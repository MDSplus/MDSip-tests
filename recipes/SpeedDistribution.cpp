


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


TestTree g_target_tree;

//////////////////////////////////////////////////////////////////////////////////
////  TEST: SEGMENT SIZE  ////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


Vector2d segment_speed_distr_MP(size_t size_KB,
                                    Curve2D &speed_curve,
                                    Curve2D &time_curve,
                                    int nch = 1,
                                    int nseg = 50)
{
    typedef TestConnection::TimeHistogram Histogram;

    TestConnectionMP conn(g_target_tree);

    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //

    size_t tot_size = size_KB * nseg;

    Histogram speed_h_sum("speed_sum",100,0,3);
    Histogram time_h_sum("time_sum",100,0,2);

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
    speed_curve = speed_h_sum;
    time_curve = time_h_sum;

    for(int i=0; i<nch; ++i) {
        delete channels[i];
        delete functions[i];
    }
    return speed;
}



int main(int argc, char *argv[])
{
    if(argc > 1) g_target_tree = TestTree("test_speed", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("test_speed");
        if(path) g_target_tree = TestTree("test_speed",path);
    }

    std::cout << "CONNECTING TARGET: " << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";

    std::vector<int> n_channels;

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    n_channels                  << 1,2,4;
    static const int n_samples   = 100;
    static const int seg_size    = 64;
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    std::vector<Curve2D> speeds;
    std::vector<Curve2D> times;

    foreach (int nch, n_channels)
    {
        Curve2D speed;
        Curve2D time;
        segment_speed_distr_MP(seg_size,speed,time,nch,n_samples);
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
        foreach (const Curve2D &curve, speeds) {
            std::cout << curve << "\n";
            plot.AddCurve(curve);
        }

        {
            // SET PLOT TITLES AND LABELS //
            std::string prtcl = "tcp";
            if(!g_target_tree.Path().protocol.empty()) prtcl = g_target_tree.Path().protocol;
            std::stringstream ss;
            ss << plot.GetName() << " in " << g_target_tree.Path().protocol << " segsize = " << seg_size << " [KB]";
            plot.SetName( ss.str()  );
            std::string subtitle;
            subtitle = "(local time: " + FileUtils::CurrentDateTime() + ")";
            const char * hostname = FileUtils::GetEnv("HOSTNAME");
            if(hostname) subtitle += " " + std::string(hostname) + "  -->  " + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Transmission speed [MB/s]";
            plot.YAxis().name = "probability to transmit segment";
        }

        plot.PrintToCsv("speed_distribution");
        plot.PrintToGnuplotFile("speed_distribution");
    }

    {
        Plot2D plot("Time Distribution");

        std::cout << " ---- COLLECTED TIMES  ------ \n";
        foreach (const Curve2D &curve, times) {
            std::cout << curve << "\n";
            plot.AddCurve(curve);
        }

        {
            // SET PLOT TITLES AND LABELS //
            std::string prtcl = "tcp";
            if(!g_target_tree.Path().protocol.empty()) prtcl = g_target_tree.Path().protocol;
            std::stringstream ss;
            ss << plot.GetName() << " in " << g_target_tree.Path().protocol << " segsize = " << seg_size << " [KB]";
            plot.SetName( ss.str()  );
            std::string subtitle;
            subtitle = "(local time: " + FileUtils::CurrentDateTime() + ")";
            const char * hostname = FileUtils::GetEnv("HOSTNAME");
            if(hostname) subtitle += " " + std::string(hostname) + "  -->  " + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Transmission time [s]";
            plot.YAxis().name = "probability to transmit segment";
        }

        plot.PrintToCsv("time_distribution");
        plot.PrintToGnuplotFile("time_distribution");
    }

    return 0;
}





























