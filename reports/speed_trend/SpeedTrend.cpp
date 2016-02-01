


#include <iostream>
#include <fstream>
#include <time.h>

#include <mdsobjects.h>


#include "FileUtils.h"
#include "TreeUtils.h"

#include "TestContent.h"
#include "TestConnection.h"

#include "DataUtils.h"

#include <time.h>
#include <sys/types.h>

#include <signal.h>


static struct sigaction sigalarm_old_action;
static struct sigaction sigalarm_new_action;


using namespace MDSplus;
using namespace mdsip_test;


static void sig_handler(int sig_nr)
{

    switch (sig_nr)
    {
    case SIGALRM:
        std::cout << "got Alarm\n";
        break;
    case SIGTERM:
    case SIGINT:
    default:
        break;
    }
}

#define CLOCKID CLOCK_REALTIME
#define SIG SIGRTMIN

int register_signal() {
    memset(&sigalarm_new_action, 0, sizeof(sigalarm_new_action));
    sigalarm_new_action.sa_handler = sig_handler;
    sigaction(SIGALRM, &sigalarm_new_action, &sigalarm_old_action);


    timer_t timerid;
    struct sigevent sev;
    struct itimerspec its;
    long long freq_nanosecs;
    sigset_t mask;
    struct sigaction sa;

    /* Establish handler for timer signal */
    printf("Establishing handler for signal %d\n", SIG);
    sa.sa_flags = SA_SIGINFO;
    sa.sa_sigaction = sig_handler;
    sigemptyset(&sa.sa_mask);
    if (sigaction(SIG, &sa, NULL) == -1)
        return 0;

    /* Block timer signal temporarily */

    printf("Blocking signal %d\n", SIG);
    sigemptyset(&mask);
    sigaddset(&mask, SIG);
    if (sigprocmask(SIG_SETMASK, &mask, NULL) == -1)
        return 0;

    /* Create the timer */
    sev.sigev_notify = SIGEV_SIGNAL;
    sev.sigev_signo = SIG;
    sev.sigev_value.sival_ptr = &timerid;
    if (timer_create(CLOCKID, &sev, &timerid) == -1)
        return 0;

    printf("timer ID is 0x%lx\n", (long) timerid);

    /* Start the timer */
    freq_nanosecs = atoll(argv[2]);
    its.it_value.tv_sec = freq_nanosecs / 1000000000;
    its.it_value.tv_nsec = freq_nanosecs % 1000000000;
    its.it_interval.tv_sec = its.it_value.tv_sec;
    its.it_interval.tv_nsec = its.it_value.tv_nsec;

    if (timer_settime(timerid, 0, &its, NULL) == -1)
        return 0;


    /* Unlock the timer signal, so that timer notification
          can be delivered */

//    printf("Unblocking signal %d\n", SIG);
//    if (sigprocmask(SIG_UNBLOCK, &mask, NULL) == -1)
//        errExit("sigprocmask");
    return 1;
}


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

Vector2d segment_speed_distr_MT(size_t size_KB,
                                TestConnection::TimeHistogram &speed_h_out,                                
                                int nch = 1,
                                int nseg = 50)
{
    typedef TestConnection::TimeHistogram Histogram;
    
    TestConnectionMT conn(g_target_tree);
    
    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //
    
    size_t tot_size = size_KB * nseg;
    
    const Vector2d &l1 = g_options.h_speed_limits;
    const Vector2d &l2 = g_options.h_time_limits;
    Histogram speed_h_sum("speed_sum",100,l1(0),l1(1));    
    
    // prepare channels //
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(functions.back(),channels.back());
                
        Histogram &speed_h = conn.ChannelSpeed(channels.back());        
        speed_h = speed_h_sum;
    }
    
    std::cout << "\n /////// connecting " << nch
              << " channels [" << size_KB << " KB]: //////// \n" << std::flush;
    
    conn.StartConnection();
    
    
    Vector2d speed;
    
    for(int i=0; i<nch; ++i) {
        Channel *ch = channels[i];
        
        Histogram &speed_h = conn.ChannelSpeed(ch);
        
        std::cout << "speed dist: " << speed_h << "\n";
                
        speed_h_sum = Histogram::merge(speed_h_sum,speed_h);        
        speed(0) += speed_h.MeanAll();
        speed(1) += speed_h.VarianceAll();
    }
    speed(0);
    speed(1) = sqrt( speed(1) );
    std::cout << "SPEED: " << speed << "\n";
    
    // returns a plot of merged histograms //
    speed_h_out = speed_h_sum;
    
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
    
    
    std::vector<Histogram> trend_speeds;
    std::vector<Curve2D>   trend_value(g_options.n_channels.size());
    std::vector<time_t>   trend_time(g_options.n_channels.size());

    // TIME LOOP ( add this to a timer interruption )
    for(int time_i=10;time_i-->0;) {
        
        // CH LOOP ( loops for each channel )
        std::vector<Histogram> ch_speeds;
        std::vector<Point2D>   ch_value;
        
        foreach (int nch, g_options.n_channels)
        {
            Histogram speed;
            
            time_t start_time,end_time;
            
            time(&start_time);        
            segment_speed_distr_MT(g_options.seg_size,speed,nch,g_options.samples);
            time(&end_time);
            
            std::stringstream curve_name;
            curve_name << "ch" << nch;
            
            speed.SetName(curve_name.str().c_str());        
            ch_speeds.push_back(speed);
            
            // stores only start time for now //
            Point2D speed_point;
            speed_point << time_i,speed.Mean(),speed.Rms();
            ch_value.push_back(speed_point);
            trend_time.push_back(start_time);        
        }
        
        // collect speed histograms per channel simply merging values
        if(trend_speeds.empty()) trend_speeds = ch_speeds;
        else for(int i=0; i<g_options.n_channels.size(); ++i) {
            trend_speeds[i] = Histogram::merge(trend_speeds[i],ch_speeds[i]);
        }
        
        for(int i=0; i<g_options.n_channels.size(); ++i) {
            trend_value[i].AddPoint(ch_value[i]);
        }
        
    }
    
    
    {
        Plot2D plot("Speed Distribution");
        
        std::cout << " ---- COLLECTED SPEEDS  ------ \n";
        foreach (const Histogram &h, trend_speeds) {
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
            if(hostname) subtitle += " " + std::string(hostname) + "  -->  " 
                    + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Transmission speed [MB/s]";
            plot.YAxis().name = "Transmission probability";
        }
        
        plot.PrintToCsv(filename_out + "speed");
        plot.PrintToGnuplotFile(filename_out + "speed");
    }
    

    {
        Plot2D plot("Speed Trend");
        std::cout << " ---- COLLECTED TRENDS  ------ \n";
        foreach (Curve2D &speed, trend_value) {
            std::cout << speed << "\n";
            plot.AddCurve(speed);
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
            if(hostname) subtitle += " " + std::string(hostname) + "  -->  " 
                    + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Time value (fix)";
            plot.YAxis().name = "Transmission speed";
        }
        
        plot.PrintToCsv(filename_out + "trend");
        plot.PrintToGnuplotFile(filename_out + "trend");
    }


    
    return 0;
}





























