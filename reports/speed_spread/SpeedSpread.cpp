


#include <iostream>
#include <fstream>
#include <time.h>
#include <unistd.h> // sleep

#include <mdsobjects.h>


#include "FileUtils.h"
#include "TreeUtils.h"

#include "TestContent.h"
#include "TestConnection.h"

#include "DataUtils.h"

using namespace MDSplus;
using namespace mdsip_test;


////////////////////////////////////////////////////////////////////////////////
//  GLOBALS  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


struct Parameters : Options {
    
    std::vector<int> n_channels;
    size_t seg_size, samples;
    std::string h_speed_limits;
    std::string h_time_limits;
    
    Parameters() :
        seg_size(128),
        samples(250),
        h_speed_limits("auto"),
        h_time_limits("auto")
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
ProgressOutput g_progress;





static void count_down(int sec, const char *msg=0) {
    if(msg) 
        std::cerr << msg;
    else
        std::cerr << "Exception caught: ";
    std::cerr << std::endl;
    for(int i=sec; i-->0;) {
        std::cerr << " retrying in " << i+1 << " sec \r";
        sleep(1);
    }
}


////////////////////////////////////////////////////////////////////////////////
//  TEST: SEGMENT SIZE  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Vector2d segment_speed_distr_MT(size_t size_KB,
                                TestConnection::TimeHistogram &speed_h_out,
                                TestConnection::TimeHistogram &time_h_out,
                                int nch = 1,
                                int nseg = 50)
{
    typedef TestConnection::TimeHistogram Histogram;
    
    TestConnectionMT conn(g_target_tree);
    conn.SetSubscriptions(nch,0);

    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //
    
    size_t tot_size = size_KB * nseg;
    
    const Vector2d l1 = g_options.h_speed_limits;
    const Vector2d l2 = g_options.h_time_limits;
    Histogram speed_h_sum("speed_sum",100,l1(0),l1(1));
    Histogram time_h_sum("time_sum",100,l2(0),l2(1));
    
    // prepare channels //
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(functions.back(),channels.back());
        Channel *ch = channels.back();
        Histogram &time_h = ch->Times();
        Histogram &speed_h = ch->Speeds();
        time_h = time_h_sum;
        speed_h = speed_h_sum;
    }
    
    std::cout << "\n /////// connecting " << nch
              << " channels [" << size_KB << " KB]: //////// \n" << std::flush;
    
    conn.StartConnection(); 
    
    Vector2d time, speed;
    
    for(int i=0; i<nch; ++i) {
        Channel *ch = channels[i];
        Histogram &time_h = ch->Times();
        Histogram &speed_h = ch->Speeds();
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
    
    if(argc > 1) g_target_tree = TestTree("speed_spread", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("speed_spread");
        if(path) g_target_tree = TestTree("speed_spread",path);
    }
    std::string filename_out = "test_distribution";
    if(argc > 2) filename_out = argv[2];
    
    std::cout << "CONNECTING TARGET: " << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";
    
    typedef TestConnection::TimeHistogram Histogram;
    
    
    std::vector<Histogram> speeds;
    std::vector<Histogram> times;
    
    
    {
        int size = 0;
        foreach(int nch, g_options.n_channels)
            size += nch;
        g_progress = ProgressOutput(size*2);
    }
    
    { // trim heading and trailing spaces //
        std::string &str = g_options.h_speed_limits;
        size_t endpos = str.find_last_not_of(" \t");
        if( std::string::npos != endpos )
            str = str.substr( 0, endpos+1 );
        size_t startpos = str.find_first_not_of(" \t");
        if( std::string::npos != startpos )
            str = str.substr( startpos );
    }
    
    // training for plot limits //
    if( g_options.h_speed_limits == "auto" 
            /*|| g_options.h_time_limits == "auto"*/) {
        g_progress = ProgressOutput(g_progress.GetExpectedCount() * 2);
        std::cout << "Start trainig plot limits...\n";
        double s_min=0, s_max=0;
        double t_min=0, t_max=0;
        double s_rms=0,t_rms=0;
        const int training_samples = std::min((int)g_options.samples,10);
        foreach(int nch, g_options.n_channels) {
            Histogram speed;
            Histogram time;
            while(true) { 
//                segment_speed_distr_MT(g_options.seg_size,speed,time,nch,training_samples); break;
                try { segment_speed_distr_MT(g_options.seg_size,speed,time,nch,training_samples); break; }
                catch (std::exception &e) { count_down(5,e.what()); }
            }
            s_min = std::min(s_min, speed.Min());
            s_max = std::max(s_max, speed.Max());
            t_min = std::min(t_min, time.Min());
            t_max = std::max(t_max, time.Max());
            s_rms = std::max(s_rms, speed.RmsAll());
            t_rms = std::max(t_rms, time.RmsAll());
            g_progress.Completed(nch);
        }
        Vector2d sl(std::max(s_min-s_rms/2,0.),s_max+s_rms/2);
        Vector2d tl(std::max(t_min-t_rms/2,0.),t_max+t_rms/2);
        if(g_options.h_speed_limits == "auto") {
            std::stringstream ss; ss << sl;
            g_options.h_speed_limits = ss.str();
        }
        if(g_options.h_time_limits == "auto") {
            std::stringstream ss; ss << tl;
            g_options.h_time_limits = ss.str();
        }
    }
    
    foreach (int nch, g_options.n_channels)
    {
        Histogram speed;
        Histogram time;
        while(true) { 
            try { segment_speed_distr_MT(g_options.seg_size,speed,time,nch,g_options.samples); break; } 
            catch (std::exception &e) { count_down(5,e.what()); }
        }
        std::stringstream curve_name;
        curve_name << "ch" << nch;
        speed.SetName(curve_name.str().c_str());
        time.SetName(curve_name.str().c_str());
        speeds.push_back(speed);
        times.push_back(time);
        g_progress.Completed(nch);
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
            if(!g_target_tree.Path().protocol.empty()) 
                prtcl = g_target_tree.Path().protocol;
            std::stringstream ss;
            ss << plot.GetName() << " in " << g_target_tree.Path().protocol 
               << " segsize = " << g_options.seg_size << " [KB]";
            plot.SetName( ss.str()  );
            std::string subtitle;
            subtitle = "(local time: " + FileUtils::CurrentDateTime() + ")";
            const char * hostname = FileUtils::GetEnv("HOSTNAME");
            if(hostname) subtitle += " " + std::string(hostname) 
                    + "  -->  " + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Transmission speed [MB/s]";
            plot.YAxis().name = "Transmission rate";
        }
        
        plot.PrintToCsv(filename_out + "speed");
        plot.PrintToGnuplotFile(filename_out + "speed");
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
            if(!g_target_tree.Path().protocol.empty()) 
                prtcl = g_target_tree.Path().protocol;
            std::stringstream ss;
            ss << plot.GetName() << " in " << g_target_tree.Path().protocol 
               << " segsize = " << g_options.seg_size << " [KB]";
            plot.SetName( ss.str()  );
            std::string subtitle;
            subtitle = "(local time: " + FileUtils::CurrentDateTime() + ")";
            const char * hostname = FileUtils::GetEnv("HOSTNAME");
            if(hostname) subtitle += " " + std::string(hostname) 
                    + "  -->  " + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Transmission time [s]";
            plot.YAxis().name = "Transmission probability";
        }
        
        plot.PrintToCsv(filename_out + "time");
        plot.PrintToGnuplotFile(filename_out + "time");
    }
    
    return 0;
}





























