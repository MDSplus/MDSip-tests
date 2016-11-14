

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


struct Parameters : Options {

    std::vector<int> n_channels;
    Vector3i seg_range;
    Vector2d h_speed_limits;
    Vector2d h_time_limits;
    size_t samples;
    size_t probes;

    Parameters() :
        seg_range(2048,2048,20480),
        samples(20),probes(1),
        h_speed_limits(0,10),
        h_time_limits(0,5)
    {
        n_channels << 1,2,4;
        this->AddOptions()
                ("channels",&n_channels,"parallel channels to build")
                ("segments",&seg_range,"segment size [KB] (start,delta,stop)")
                ("samples",&samples,"number of samples to average")
                ("probes",&probes,"number of subsequent overall test probes to ease network fluctuations")
                ("speed_limits",&h_speed_limits,"speed histogram limits [MB/s] (begin,end)")
                ("time_limits",&h_time_limits,"time histogram limits [MB/s] (begin,end)")
                ;
    }

} g_options;

TestTree g_target_tree;



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



///
/// \param size_KB size of segment to be sent
/// \param nch number of forked channels (sine) to be used
/// \param nseg total number of segment per channel
/// \return mean and rms of average speed for all channels togheter
///
/// Test for segment size in Multi Thread using Thin Client connection.
/// In histogram a value of equivalent data troughput is added in MB/s
/// This is not the actual line speed becouse reflects the time to sent actual
/// data into the channel.
///
Histogram<double> segment_size_throughput_MT(size_t size_KB,
                                             int nch = 1,
                                             double *max_chan_time = NULL,
                                             int nseg = g_options.samples
                                             )
{
    
    
    TestConnectionMT conn(g_target_tree);

    std::vector< unique_ptr<ContentFunction> > functions; // function generators //
    std::vector< unique_ptr<Channel> >         channels;  // forked channels //

    size_t tot_size = size_KB * nseg;

    ////////////////////////////////////////////////////////////////////////////
    // PARAMETERS //////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    const Vector2d &l1 = g_options.h_speed_limits;
    const Vector2d &l2 = g_options.h_time_limits;
    TestConnection::TimeHistogram speed_h("ch speed",100,l1(0),l1(1));
    TestConnection::TimeHistogram time_h ("ch time ",100,l2(0),l2(1));
    ////////////////////////////////////////////////////////////////////////////

    // prepare channels //
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(functions[i],channels[i]);
        conn.ChannelTime(channels.back()) = time_h;
        conn.ChannelSpeed(channels.back()) = speed_h;
    }

    std::cout << "\n /////// connecting " << nch 
              << " channels [" << size_KB << " KB]: ////////"
              << "\n" << std::flush;            
    
    double total_connection_time = conn.StartConnection();
    

    // here we assume that speed_h is empty //
    //    std::cout << "speed_h --> mean: " << speed_h.MeanAll() << " rms: " << speed_h.RmsAll() << "\n";    

    // NOTE: max_chan_time must be set to valid value before this
    for(int i=0; i<nch; ++i) {
        Channel *ch = channels[i];
        time_h  += conn.ChannelTime(ch);
        speed_h += conn.ChannelSpeed(ch);
        // retrieve the maximum elapsed time from channels //
        if(max_chan_time && conn.ChannelTime(ch).Sum() > *max_chan_time)
            *max_chan_time = conn.ChannelTime(ch).Sum();
    }
    std::cout << speed_h << "\n";
    
    char * use_total_time = getenv("USE_TOTAL_TIME");
    if(use_total_time && !strcmp(use_total_time,"yes") ) {
        std::cout << "USING TOTAL TIME CONNECTION " << total_connection_time << "\n";
        *max_chan_time = total_connection_time;
    }

    return speed_h;    
}





////////////////////////////////////////////////////////////////////////////////
//  MAIN  //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


int main(int argc, char *argv[])
{
    std::string program_name(argv[0]);
    g_options.SetUsage(program_name + " target_path plot_filename [options]");
    g_options.Parse(argc,argv);

    if(argc > 1) g_target_tree = TestTree("segment_size", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("segment_size");
        if(path) { g_target_tree = TestTree("segment_size",path); }
    }
    std::string filename_out = "test_segment_size";
    if(argc > 2) filename_out = argv[2];



    std::cout << "CONNECTING TARGET: "
              << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";


    
    
    // collect probes //
    typedef std::vector<Histogram<double> > Probe_T;
    std::vector<Probe_T> max_time_probes(g_options.n_channels.size());
    std::vector<Probe_T> speed_probes(g_options.n_channels.size());
    Vector3i &range = g_options.seg_range;
    
    // Progress output (for dialog status bar)    
    ProgressOutput progress;    
    {
        size_t tot_steps = g_options.probes  * (int)(range(2)-range(0))/range(1);
        foreach (int nch, g_options.n_channels) {
            tot_steps *= nch;
        }
        progress.SetExpectedCount(tot_steps);
    }
    
    for(int prb = 0; prb < g_options.probes; ++prb ) {
        int seg_id = 0;
        for(int seg = range(0); seg < range(2); 
            seg += std::min(range(1), range(2)-seg), ++seg_id )
        {
            for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
            {                            
                int nch = g_options.n_channels[nch_id];
                Histogram<double> sh;
                double max_time;
                // launch segment_size_througput
                for(int i=0;; ++i) {
                    try { max_time = 0;
                          sh = segment_size_throughput_MT(seg, nch, &max_time);
                          break; }
                    catch (std::exception &e) { count_down(5,e.what()); }
                }
                // add probe //

                if(seg_id < speed_probes[nch_id].size())
                    max_time_probes[nch_id].at(seg_id) += max_time;
                else
                    max_time_probes[nch_id].push_back(max_time);

                if(seg_id < speed_probes[nch_id].size())
                    speed_probes[nch_id].at(seg_id) += sh;
                else
                    speed_probes[nch_id].push_back(sh);
                progress.Completed(nch);
            }
        }
    }

    // speed plots //
    std::vector<Curve2D> speeds;
    //    foreach(int nch, g_options.n_channels)
    for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
    {
        int nch = g_options.n_channels[nch_id];
        std::stringstream curve_name;
        curve_name << nch << " ch";
        Curve2D curve(curve_name.str().c_str());
        int seg_id = 0;
        for(int seg = range(0); seg < range(2); seg += std::min(range(1), range(2)-seg), ++seg_id ) {
            const Histogram<double> &sh = speed_probes[nch_id].at(seg_id);
            const Histogram<double> &mth = max_time_probes[nch_id].at(seg_id);
            double mspd = nch * g_options.samples * seg / 1024 / mth.MeanAll();
            // curve.AddPoint( Point2D(seg, nch * sh.MeanAll(), nch * sh.RmsAll()) );
            curve.AddPoint( Point2D(seg, mspd, nch * sh.RmsAll()) );
        }
        speeds.push_back(curve);
    }

    
    Plot2D plot("Throughput vs Segment Size");
    std::cout << " ---- COLLECTED SPEEDS  ------ \n";
    foreach (Curve2D &speed, speeds) {
        std::cout << speed << "\n";
        plot.AddCurve(speed);
    }


    // make short X axis name before to write into csv //
    plot.XAxis().name = "size";
    plot.PrintToCsv(filename_out);

    {
        // SET PLOT TITLES AND LABELS //
        std::string prtcl = "tcp";
        if(!g_target_tree.Path().protocol.empty()) prtcl = g_target_tree.Path().protocol;
        plot.SetName( plot.GetName() + " in " + g_target_tree.Path().protocol );
        std::string subtitle;
        subtitle = "(local time: " + FileUtils::CurrentDateTime() + ")";
        const char * hostname = FileUtils::GetEnv("HOSTNAME");
        if(hostname) subtitle += " " + std::string(hostname) + "  -->  " + g_target_tree.Path().server;
        plot.SetSubtitle(subtitle);
        plot.XAxis().name = "Segment size [KB] of signal data";
        plot.YAxis().name = "Total speed [MB/s]";
    }

    // Print Plot file //
    plot.PrintToGnuplotFile(filename_out);

    {
        std::ofstream o;
        o.open( (filename_out + ".sh").c_str() );
        assert(o.is_open());
        o << "# Exports parameters and results in shell like script \n\n";

        o << "target=" << argv[1] << "\n"
          << "filename_out=" << filename_out << "\n"
          << "channels=\"" << g_options.n_channels << "\"\n"
          << "segments=" << g_options.seg_range << "\n"
          << "samples=" << g_options.samples << "\n";

        // doing analisys //

        Curve2D::Point max(0,0,0);
        foreach (const Curve2D &curve, plot.Curves()) {
            if(!curve.Points().empty()) {
                Curve2D::Point p = curve[0];
                for (int i=1; i<curve.Size(); ++i)
                    if ( p(1) < curve[i](1) ) p = curve[i];
                if( max(1) < p(1)) max = p;
            }
        }
        o << "max_pt=" << max << "\n";
        o << "max_x=" << max(0) << "\n";
        o << "max_y=" << max(1) << "\n";
        o << "max_e=" << max(2) << "\n";

        o.close();
    }



    return 0;
}




























