


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


#include <ctime>
#include <sys/types.h>
#include <signal.h>
#include <unistd.h> // sleep




using namespace MDSplus;
using namespace mdsip_test;

#define MAX_CONNECTION_ATTEMPTS 100
#define WAIT_CONNECTION_SECONDS 5


////////////////////////////////////////////////////////////////////////////////
//  GLOBALS  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////




struct Parameters : Options {
    
    std::vector<int> n_channels;
    size_t seg_size, samples;
    Vector2d h_speed_limits;
    Vector2d h_time_limits;
    Vector2d timer_interval_duration;
    
    Parameters() :
        seg_size(128),
        samples(250),
        h_speed_limits(0,10),
        h_time_limits(0,5),
        timer_interval_duration(10,60)
    {
        n_channels << 1,2,4; // default channels number;
        this->AddOptions()
                ("channels",&n_channels,"parallel channels to build")
                ("segments",&seg_size,"segment size [KB]")
                ("samples",&samples,"number of samples to average")
                ("speed_limits",&h_speed_limits,"speed histogram limits [MB/s] (begin,end)")
                ("time_range",&timer_interval_duration,
                   "timer interval/duration (interval[seconds], duration[minutes])")
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
//  TIMER    ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define CLOCKID CLOCK_REALTIME
#define SIG SIGRTMIN

static time_t  timer_start;
static timer_t timerid;
static sigset_t mask;
static struct sigaction sa;
static double elapsed_seconds = 0;

// fwd //
static int fill_trend();

static void handler(int sig, siginfo_t *si, void *uc)
{
    
    /* lock timer signal temporarily */
    sigemptyset(&mask);
    sigaddset(&mask, SIG);
    if (sigprocmask(SIG_SETMASK, &mask, NULL) == -1)
    { std::cerr << "Error handling timer\n"; exit(1); }
    
    // DO TEST //
    fill_trend();
    g_progress.Completed();
    
    time_t now; time(&now);
    elapsed_seconds = difftime(now,timer_start);
    if(elapsed_seconds > g_options.timer_interval_duration(1) * 60)
        signal(sig, SIG_IGN); // stop handling  
    
    /* unlock timer signal */
    if (sigprocmask(SIG_UNBLOCK, &mask, NULL) == -1)
    { std::cerr << "Error handling timer\n"; exit(1); }
}





int register_timer(long long seconds) {
//    memset(&sigalarm_new_action, 0, sizeof(sigalarm_new_action));
//    sigalarm_new_action.sa_handler = sig_handler;
//    sigaction(SIGALRM, &sigalarm_new_action, &sigalarm_old_action);

    struct sigevent sev;
    struct itimerspec its;    

    /* Establish handler for timer signal */
    sa.sa_flags = SA_SIGINFO;
    sa.sa_sigaction = handler;
    sigemptyset(&sa.sa_mask);
    if (sigaction(SIG, &sa, NULL) == -1)
        return false;

    /* lock timer signal temporarily */
    sigemptyset(&mask);
    sigaddset(&mask, SIG);
    if (sigprocmask(SIG_SETMASK, &mask, NULL) == -1)
        return false;

    /* Create the timer */
    sev.sigev_notify = SIGEV_SIGNAL;
    sev.sigev_signo = SIG;
    sev.sigev_value.sival_ptr = &timerid;
    if (timer_create(CLOCKID, &sev, &timerid) == -1)
        return false;

    printf("timer ID is 0x%lx\n", (long) timerid);

    /* Start the timer */
    its.it_value.tv_sec = seconds;
    its.it_value.tv_nsec = 0;
    its.it_interval.tv_sec = its.it_value.tv_sec;
    its.it_interval.tv_nsec = its.it_value.tv_nsec;

    time(&timer_start);
    if (timer_settime(timerid, 0, &its, NULL) == -1)
        return false;
    
    /* Unlock the timer signal, so that timer notification can be delivered */
    if (sigprocmask(SIG_UNBLOCK, &mask, NULL) == -1)
        return false;

    // OK //
    std::cout << "timer started\n";
    return true;
}

int unregister_timer() {
    return true;
}




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
    conn.SetSubscriptions(nch,0);
    
    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //
    
    size_t tot_size = size_KB * nseg;
    
    const Vector2d &l1 = g_options.h_speed_limits;
    // const Vector2d &l2 = g_options.h_time_limits;
    Histogram speed_h_sum("speed_sum",100,l1(0),l1(1));
    
    // prepare channels //
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(functions.back(),channels.back());
        Channel *ch = channels.back();
        Histogram &speed_h = ch->Speeds();
        speed_h = speed_h_sum;
    }
    
    std::cout << "\n /////// connecting " << nch
              << " channels [" << size_KB << " KB]: //////// \n" << std::flush;
    
    
    conn.StartConnection();

    Vector2d speed;
    
    for(int i=0; i<nch; ++i) {
        Channel *ch = channels[i];        
        Histogram &speed_h = ch->Speeds();
        std::cout << "speed dist: " << speed_h << "\n";                
        speed_h_sum = Histogram::merge(speed_h_sum,speed_h);        
        speed(0) += speed_h.MeanAll();
        speed(1) += speed_h.VarianceAll();
    }
    speed(0);
    speed(1) = sqrt( speed(1) );
    std::cout << "SPEED: " << speed << "\n";
    
    // returns a plot of merged histograms .. speed per channel //
    speed_h_out = speed_h_sum;
    
    for(int i=0; i<nch; ++i) {
        delete channels[i];
        delete functions[i];
    }
    return speed;
}



// FILL TREND FUNCTION //


static std::vector<TestConnection::TimeHistogram > trend_speeds;
static std::vector<Curve2D>   trend_value;
static std::vector<time_t>   trend_time;

static int fill_trend() 
{   
    typedef TestConnection::TimeHistogram Histogram;
    
    // CH LOOP ( loops for each channel )
    std::vector<Histogram> ch_speeds;
    std::vector<Point2D>   ch_value;
    
    foreach (int nch, g_options.n_channels)
    {
        Histogram speed_h;
        Vector2d  speed;
        time_t start_time,end_time;
        
        time(&start_time);
        while(true) {
            try {
                speed = segment_speed_distr_MT(g_options.seg_size,speed_h,nch,g_options.samples);
                break; 
            }
            catch (std::exception &e) 
            {
                std::cerr << "Exception: " << e.what();
                static int count = 0;
                if(++count == MAX_CONNECTION_ATTEMPTS) { 
                    std::cerr << "Too many faild attempts to connect.. aborting test\n"; 
                    exit(1);
                } 
                else count_down(WAIT_CONNECTION_SECONDS);
            }
        }
        time(&end_time);
        
        std::stringstream curve_name;
        curve_name << "ch" << nch;       
        speed_h.SetName(curve_name.str().c_str());        
        ch_speeds.push_back(speed_h);
                                
        // stores only start time for now //
        time_t now; time(&now);
        Point2D trend_point;
        trend_point << difftime(now,timer_start)/60,speed(0),speed(1);
        ch_value.push_back(trend_point);
        trend_time.push_back(start_time);
    }
    
    // collect speed histograms per channel simply merging values
    if(trend_speeds.empty()) trend_speeds = ch_speeds;
    else for(int i=0; i<g_options.n_channels.size(); ++i) {
        trend_speeds[i] = Histogram::merge(trend_speeds[i],ch_speeds[i]);
    }
    
    for(int i=0; i<g_options.n_channels.size(); ++i) {
        trend_value[i].AddPoint(ch_value[i]);        
        std::stringstream curve_name;
        curve_name << "ch" << g_options.n_channels[i];
        trend_value[i].SetName(curve_name.str().c_str());                        
    }
}



std::string g_start_date;


int main(int argc, char *argv[])
{
    std::string program_name(argv[0]);
    g_options.SetUsage(program_name + " target_path plot_fileprefix [options]");
    g_options.Parse(argc,argv);
    
    if(argc > 1) g_target_tree = TestTree("speed_trend", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("speed_trend");
        if(path) g_target_tree = TestTree("speed_trend",path);
    }
    std::string filename_out = "test_distribution";
    if(argc > 2) filename_out = argv[2];
    
    g_start_date = FileUtils::CurrentDateTime();
    
        
    std::cout << "CONNECTING TARGET: " << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";
    
    typedef TestConnection::TimeHistogram Histogram;    
    trend_value = std::vector<Curve2D>(g_options.n_channels.size());
    trend_time = std::vector<time_t>(g_options.n_channels.size());
    
    { // calculate steps
        g_progress = ProgressOutput(g_options.timer_interval_duration(1) * 60 /
                                    g_options.timer_interval_duration(0));
        g_progress.SetExpectedTime(g_options.timer_interval_duration(1)*60);
    }
    
    // loop until end of time //
    register_timer(g_options.timer_interval_duration(0));
    raise(SIG); // start also from now //
    while(elapsed_seconds < g_options.timer_interval_duration(1) * 60) sleep(1);
    
    
    // write out //
    {
        Plot2D plot("Speed per single segment");
        
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
            const char * hostname = FileUtils::GetEnv("HOSTNAME");
            if(hostname) subtitle += " " + std::string(hostname) + "  -->  " 
                    + g_target_tree.Path().server;
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Transmission speed [MB/s]";
            plot.YAxis().name = "Transmission rate";
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
            subtitle = "(started at: " + g_start_date + " -- ended at: " + FileUtils::CurrentDateTime() + ")";
            plot.SetSubtitle(subtitle);
            plot.XAxis().name = "Time [min]";
            plot.YAxis().name = "Transmission speed";
        }
        
        plot.PrintToCsv(filename_out + "trend");
        plot.PrintToGnuplotFile(filename_out + "trend");
    }


    
    return 0;
}





























