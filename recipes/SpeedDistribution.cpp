


#include <iostream>
#include <fstream>
#include <time.h>

#include <mdsobjects.h>


#include "FileUtils.h"
#include "TreeUtils.h"

#include "TestContent.h"
#include "TestConnection.h"

#include "DataUtils.h"


using namespace MDSplus;


////////////////////////////////////////////////////////////////////////////////
//  GLOBALS  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


struct Parameters : Options {

    std::vector<int> n_channels;
    size_t seg_size, samples;
    Vector2d h_speed_limits;
    Vector2d h_time_limits;

    Parameters() :
        seg_size(128),
        samples(250),
        h_speed_limits(0,10),
        h_time_limits(0,5)
    {
        n_channels << 1,2,4; // default channels number;
        this->AddOptions()
                ("channels",&n_channels,"parallel channels to build")
                ("segments",&seg_size,"segment size [KB]")
                ("samples",&samples,"number of samples to average")
                ("speed_limits",&h_speed_limits,"speed histogram limits [MB/s] (begin,end)")
                ("time_limits",&h_time_limits,"time histogram limits [MB/s] (begin,end)")
                ;
    }

} g_options;

TestTree g_target_tree;





////////////////////////////////////////////////////////////////////////////////
//  TEST: SEGMENT SIZE  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Vector2d segment_speed_distr_MP(size_t size_KB,
                                    TestConnection::TimeHistogram &speed_h_out,
                                    TestConnection::TimeHistogram &time_h_out,
                                    int nch = 1,
                                    int nseg = 50)
{
    typedef TestConnection::TimeHistogram Histogram;

    TestConnectionMP conn(g_target_tree);

    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //

    size_t tot_size = size_KB * nseg;

    const Vector2d &l1 = g_options.h_speed_limits;
    const Vector2d &l2 = g_options.h_speed_limits;
    Histogram speed_h_sum("speed_sum",100,l1(0),l1(1));
    Histogram time_h_sum("time_sum",100,l2(0),l2(1));

    // prepare channels //
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(functions.back(),channels.back());

        Histogram &time_h = conn.ChannelTime(channels.back());
        Histogram &speed_h = conn.ChannelSpeed(channels.back());
        time_h = time_h_sum;
        speed_h = speed_h_sum;
    }

    std::cout << "\n /////// connecting " << nch << " channels [" << size_KB << " KB]: //////// \n" << std::flush;

    conn.StartConnection();

    std::cout << "CHANNELS TIMES:\n";
    Vector2d time, speed;

    for(int i=0; i<nch; ++i) {
        Channel *ch = channels[i];
        Histogram &time_h = conn.ChannelTime(ch);
        Histogram &speed_h = conn.ChannelSpeed(ch);
        std::cout << "times dist: " << time_h << "\n";
        std::cout << "speed dist: " << speed_h << "\n";

        time_h_sum = Histogram::merge(time_h_sum,time_h);
        speed_h_sum = Histogram::merge(speed_h_sum,speed_h);

        time(0) += time_h.MeanAll();
        time(1) += time_h.VarianceAll();
        speed(0) += speed_h.MeanAll();
        speed(1) += speed_h.VarianceAll();
    }
    time(0) /= nch;
    time(1) = sqrt( time(1)/nch );
    speed(0);
    speed(1) = sqrt( speed(1) );
    std::cout << "SPEED: " << speed << "\n";

    // returns a plot of merged histograms //
    speed_h_out = speed_h_sum;
    time_h_out = time_h_sum;

    for(int i=0; i<nch; ++i) {
        delete channels[i];
        delete functions[i];
    }
    return speed;
}



int main(int argc, char *argv[])
{
    std::string program_name(argv[0]);
    g_options.SetUsage(program_name + " target_path plot_fileprefix [options]");
    g_options.Parse(argc,argv);

    if(argc > 1) g_target_tree = TestTree("test_speed", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("test_speed");
        if(path) g_target_tree = TestTree("test_speed",path);
    }
    std::string filename_out = "test_distribution";
    if(argc > 2) filename_out = argv[2];

    std::cout << "CONNECTING TARGET: " << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";

    typedef TestConnection::TimeHistogram Histogram;


    std::vector<Histogram> speeds;
    std::vector<Histogram> times;

    foreach (int nch, g_options.n_channels)
    {
        Histogram speed;
        Histogram time;
        segment_speed_distr_MP(g_options.seg_size,speed,time,nch,g_options.samples);
        std::stringstream curve_name;
        curve_name << "ch" << nch;
        speed.SetName(curve_name.str().c_str());
        time.SetName(curve_name.str().c_str());
        speeds.push_back(speed);
        times.push_back(time);
    }

    {
        Plot2D plot("Speed Distribution");

        std::cout << " ---- COLLECTED SPEEDS  ------ \n";
        foreach (const Histogram &h, speeds) {
            std::cout << h << "\n";
            Curve2D curve = h;
            foreach (Point2D &pt, curve.Points())
                pt(1) /= h.Size(); // NORMALIZE DISTRIBUTION //
            plot.AddCurve(curve);
        }

        {
            // SET PLOT TITLES AND LABELS //
            std::string prtcl = "tcp";
            if(!g_target_tree.Path().protocol.empty()) prtcl = g_target_tree.Path().protocol;
            std::stringstream ss;
            ss << plot.GetName() << " in " << g_target_tree.Path().protocol << " segsize = " << g_options.seg_size << " [KB]";
            plot.SetName( ss.str()  );
            std::string subtitle;
            subtitle = "(local time: " + FileUtils::CurrentDateTime() + ")";
            const char * hostname = FileUtils::GetEnv("HOSTNAME");
            if(hostname) subtitle += " " + std::string(hostname) + "  -->  " + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Transmission speed [MB/s]";
            plot.YAxis().name = "Transmission probability";
        }

        plot.PrintToCsv(filename_out + "_speed");
        plot.PrintToGnuplotFile(filename_out + "_speed");
    }

    {
        Plot2D plot("Time Distribution");

        std::cout << " ---- COLLECTED TIMES  ------ \n";
        foreach (const Histogram &h, times) {
            std::cout << h << "\n";
            Curve2D curve = h;
            foreach (Point2D &pt, curve.Points())
                pt(1) /= h.Size(); // NORMALIZE DISTRIBUTION //
            plot.AddCurve(curve);
        }

        {
            // SET PLOT TITLES AND LABELS //
            std::string prtcl = "tcp";
            if(!g_target_tree.Path().protocol.empty()) prtcl = g_target_tree.Path().protocol;
            std::stringstream ss;
            ss << plot.GetName() << " in " << g_target_tree.Path().protocol << " segsize = " << g_options.seg_size << " [KB]";
            plot.SetName( ss.str()  );
            std::string subtitle;
            subtitle = "(local time: " + FileUtils::CurrentDateTime() + ")";
            const char * hostname = FileUtils::GetEnv("HOSTNAME");
            if(hostname) subtitle += " " + std::string(hostname) + "  -->  " + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Transmission time [s]";
            plot.YAxis().name = "Transmission probability";
        }

        plot.PrintToCsv(filename_out + "_time");
        plot.PrintToGnuplotFile(filename_out + "_time");
    }

    return 0;
}





























