

#include <iostream>
#include <string>
#include <stdio.h> // itoa

#include <fstream>
#include <time.h>
#include <unistd.h> // sleep
#include <mdsobjects.h>


#include "FileUtils.h"
#include "TreeUtils.h"

#include "TestContent.h"
#include "TestConnection.h"

#include "DataUtils.h"

#include <math.h>

using namespace MDSplus;
using namespace mdsip_test;


struct Parameters : Options {

    std::vector<int> n_channels;
    Vector3i seg_range;
    Vector2d h_speed_limits;
    Vector2d h_time_limits;
    Vector2d h_numeric_limits;
    size_t samples;
    size_t probes;
    std::string   env_no_disk;

    struct {
        std::string iface;
    } link;

    struct {
        bool times;
        bool speeds;
        bool stats;
    } dump;

    Parameters() :
        seg_range(2048,2048,20480),
        samples(20),probes(1),
        h_speed_limits(0,4),
        h_time_limits(0,1),
        h_numeric_limits(0,100),
        env_no_disk("no")
    {
        n_channels << 1,2,4;
        if(const char *env = getenv("USE_NO_DISK")) env_no_disk = env;
        this->AddOptions()
                ("channels",&n_channels,"parallel channels to build")
                ("segments",&seg_range,"segment size [KB] (start,delta,stop)")
                ("samples",&samples,"number of samples to average")
                ("probes",&probes,"number of subsequent overall test probes to ease network fluctuations")
                ("speed_limits",&h_speed_limits,"speed histogram limits [MB/s] (begin,end)")
                ("time_limits",&h_time_limits,"time histogram limits [MB/s] (begin,end)")
                ("no_disk",&env_no_disk,"no_disk_option (yes/no)")
                ("dump_times",&dump.times,true,"dump times histogram (bool)")
                ("dump_speeds",&dump.speeds,true,"dump speeds histogram (bool)")
                ("dump_stats",&dump.stats,true,"dump stats histogram (bool)")
                ("link_iface",&link.iface,"link device interface name (see comand \"ip a\")")
                ;
    }

} g_options;

TestTree g_target_tree;


template < typename T >
static std::string to_string(const T& val) {
    return static_cast<std::ostringstream*>( &(std::ostringstream() << val) )->str();
}

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


///
/// PROBE: TestConnection should provide this one time
///
class TestProbe {
public:

    typedef Histogram<double>    H;
    typedef Curve2D C;

    template < class T >
    class Probe_T : public std::vector<T> {
    public:
        typedef std::vector<T> BaseClass;
        Probe_T() : BaseClass() {}
        Probe_T(size_t size, const T &defh)
            : BaseClass(0)
        { for(int i=0; i<size; ++i) this->push_back(defh); }
    };

    typedef Probe_T<H> Probe_H;
    typedef Probe_T<C> Probe_C;


    size_t m_size;
    Vector2d lim_s, lim_t;
    Vector2d lim_n;

    Probe_H h_speed;
    Probe_H h_time;

    std::vector<Probe_C> c_time;
    std::vector<Probe_C> c_speed;
    std::vector<Probe_C> c_rcvbuf;
    std::vector<Probe_C> c_sndbuf;

    Probe_H h_rx;
    Probe_H h_tx;
    Probe_H h_rx_d;
    Probe_H h_tx_d;
    Probe_H h_rx_e;
    Probe_H h_tx_e;
    Probe_H h_c;

    TestProbe() : m_size(0) {}

    TestProbe(int size) :
        // limits //
        m_size(size),
        lim_s(g_options.h_speed_limits),
        lim_t(g_options.h_time_limits),
        lim_n(g_options.h_numeric_limits),

        // standard //
        h_speed (size, H("ch speed",100,lim_s(0),lim_s(1))),
        h_time  (size, H("ch times",100,lim_t(0),lim_t(1))),

        // curves //
        c_time  (size),
        c_speed (size),
        c_rcvbuf (size),
        c_sndbuf (size),

        // statistics //
        h_rx    (size, H("lnk rx",100,lim_s(0),lim_s(1))),
        h_tx    (size, H("lnk tx",100,lim_s(0),lim_s(1))),
        h_rx_d  (size, H("rx drp",100,lim_n(0),lim_n(1))),
        h_tx_d  (size, H("tx drp",100,lim_n(0),lim_n(1))),
        h_rx_e  (size, H("rx err",100,lim_n(0),lim_n(1))),
        h_tx_e  (size, H("tx err",100,lim_n(0),lim_n(1))),
        h_c     (size, H("collis",100,lim_n(0),lim_n(1)))
    {
        ;
    }

    void ChannelSetup(Channel *ch) {
        if(m_size) {
            ch->Times() = h_time[0];
            ch->Speeds() = h_speed[0];
            ch->m_rate_rx = h_rx[0];
            ch->m_rate_tx = h_tx[0];
            ch->m_rate_rx_drop = h_rx_d[0];
            ch->m_rate_tx_drop = h_tx_d[0];
            ch->m_rate_rx_error = h_rx_e[0];
            ch->m_rate_tx_error = h_tx_e[0];
            ch->m_rate_collisions = h_c[0];

            ch->Times().Clear();
            ch->Speeds().Clear();
            ch->m_rate_rx.Clear();
            ch->m_rate_tx.Clear();
            ch->m_rate_rx_drop.Clear();
            ch->m_rate_tx_drop.Clear();
            ch->m_rate_rx_error.Clear();
            ch->m_rate_tx_error.Clear();
            ch->m_rate_collisions.Clear();
        }
    }

    void ReadFromChannel(Channel *ch, int id) {
        h_speed[id] += ch->Speeds();
        h_time[id] += ch->Times();

        h_rx[id]   += ch->m_rate_rx;
        h_tx[id]   += ch->m_rate_tx;
        h_rx_d[id] += ch->m_rate_rx_drop;
        h_tx_d[id] += ch->m_rate_tx_drop;
        h_rx_e[id] += ch->m_rate_rx_error;
        h_tx_e[id] += ch->m_rate_tx_error;
        h_c[id]    += ch->m_rate_collisions;
    }

    void ReadCurves(Channel *ch, int id) {
        c_time[id].push_back(ch->Time_Curve());
        c_speed[id].push_back(ch->Speed_Curve());
        c_rcvbuf[id].push_back(ch->RcvBuf_Curve());
        c_sndbuf[id].push_back(ch->SndBuf_Curve());
    }


};


////////////////////////////////////////////////////////////////////////////////
//  TEST: SEGMENT SIZE  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
///
/// Test for segment size in Multi Thread using Thin Client connection.
/// In histogram a value of equivalent data troughput is added in MB/s
/// This is not the actual line speed becouse reflects the time to sent actual
/// data into the channel.
///
double segment_size_throughput_MT(size_t size_KB,
                                             int nch = 1,
                                             TestProbe *probe = NULL,
                                             int seg_id = 0,
                                             int nseg = g_options.samples
                                             )
{
    
    std::vector< unique_ptr<ContentFunction> > functions; // function generators //
    std::vector< unique_ptr<Channel> >         channels;  // forked channels //

    size_t tot_size = size_KB * nseg;
    TestConnectionMT conn(g_target_tree);
    conn.SetSubscriptions(nch,0);

    // PREPARE CHANNELS //
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        ContentFunction *cnt = new ContentFunction(name.str().c_str(),tot_size);
        // cnt->SetGenFunction(ContentFunction::NoiseW);
        Channel *ch = Channel::NewTC(size_KB);
        if(g_options.env_no_disk == "yes") ch->SetNoDisk(true);
        ch->SetInterfaceName(g_options.link.iface);
        probe->ChannelSetup(ch);
        conn.AddChannel(cnt,ch);
        functions.push_back( cnt );
        channels.push_back( ch );
    }

    std::cout << "\n /////// connecting " << nch 
              << " channels [" << size_KB << " KB]: ////////"
              << "\n" << std::flush;            
    
    // START CONNECTION /////////////////////////////////////
    double total_connection_time = conn.StartConnection(); //
    /////////////////////////////////////////////////////////

    // COLLECT STATISTICS //
    foreach (Channel *ch, channels) {
        ch->Time_Curve().XAxis().limits[0] = 0.;
        ch->Time_Curve().XAxis().limits[1] = total_connection_time;
        ch->RcvBuf_Curve().XAxis().limits[0] = 0.;
        ch->RcvBuf_Curve().XAxis().limits[1] = total_connection_time;
        ch->RcvBuf_Curve().XAxis().limits[0] = 0.;
        ch->RcvBuf_Curve().XAxis().limits[1] = total_connection_time;
        probe->ReadFromChannel(ch,seg_id);
        probe->ReadCurves(ch,seg_id);
    }

    { // PRINT TIME ENVELOPES //
        std::cout << "---- TIME ENVELOPES -----" << "\n";
        for(int i=0; i<nch; ++i) {
            Channel *ch = channels[i];
            std::cout << "TimeEnv";
            ch->Time_Curve().PrintSelf_abs(std::cout,100);
            std::cout << "\n";
            //            std::cout << "RcvBuf ";
            //            ch->RcvBuf_Curve().PrintSelf_abs(std::cout,100);
            //            std::cout << "\n";
            //            std::cout << "SndBuf ";
            //            ch->SndBuf_Curve().PrintSelf_abs(std::cout,100);
            //            std::cout << "\n";
        }
    }

    { // PRINT TIME HISTOGRAMS //
        std::cout << "---- TIME HISTOGRAMS -----" << "\n";
        for(int i=0; i<nch; ++i) {
            Channel *ch = channels[i];
            std::cout << "TimeHist" << ch->Times() <<"\n";
        }
    }

    { // PRINT SPEED HISTOGRAMS //
        std::cout << "---- SPEED HISTOGRAMS -----" << "\n";
        for(int i=0; i<nch; ++i) {
            Channel *ch = channels[i];
            std::cout << "SpeedH" << ch->Speeds() <<"\n";
        }
    }

    { // PRINT STATISTICS //
        std::cout << "---- COMPOSITE HISTOGRAMS -----" << "\n";
        std::cout << "---- CHANNEL STATS -----" << "\n";
        std::cout << "  " << probe->h_rx[seg_id]   << "\n";
        std::cout << "  " << probe->h_tx[seg_id]   << "\n";
        std::cout << "  " << probe->h_rx_d[seg_id] << "\n";
        std::cout << "  " << probe->h_tx_d[seg_id] << "\n";
        std::cout << "  " << probe->h_rx_e[seg_id] << "\n";
        std::cout << "  " << probe->h_tx_e[seg_id] << "\n";
        std::cout << "  " << probe->h_c[seg_id]    << "\n";
    }

    { // PRINT SOCKET BUFFERS //
        std::cout << "---- SOCKET BUFFERS  -----" << "\n";
        for(int i=0; i<nch; ++i) {
            Channel *ch = channels[i];
            std::cout << "ch" << i << " ";
            ch->SndBuf_Curve().PrintSelf_abs(std::cout,100);
            std::cout << "\n";
        }
    }
    
    return total_connection_time;
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

    // ranges //
    Vector3i &range = g_options.seg_range;
    int seg_vector_size = (range(2)-range(0))/range(1)+1;


    // collect probes //
    std::vector<unique_ptr<TestProbe> > probes;
    for(int i=0; i<g_options.n_channels.size();++i)
        probes.push_back(new TestProbe(seg_vector_size));
    
    // Progress output (for dialog status bar)    
    ProgressOutput progress;
    {
        size_t tot_steps = ((int)(range(2)-range(0))/range(1)+1);
        foreach (int nch, g_options.n_channels)
            tot_steps *= nch;        
        tot_steps *= g_options.probes;
        progress.SetExpectedCount(tot_steps);
    }
    
    for(int prb = 0; prb < g_options.probes; ++prb ) {
        int seg_id = 0;
        for(int seg = range(0); seg < range(2); seg += range(1), ++seg_id )
        {
            for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
            {                            
                int nch = g_options.n_channels[nch_id];
                for(int i=0;; ++i) {
                    try {
                        // launch segment_size_througput ///////////////////////
                        segment_size_throughput_MT(seg, nch, probes[nch_id], seg_id);
                        break; /////////////////////////////////////////////////
                    }
                    catch (std::exception &e) { count_down(5,e.what()); }
                }
                // PROGRESS STEP //////////
                progress.Completed(nch); //
                ///////////////////////////
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    ///  PLOT  /////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    {
        // CREATE CURVES FROM HISTOGRAMS //
        std::vector<Curve2D> speeds;
        for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
        {
            int nch = g_options.n_channels[nch_id];
            std::stringstream curve_name;
            curve_name << nch << " ch";
            Curve2D curve(curve_name.str().c_str());
            int seg_id = 0;
            for(int seg = range(0); seg < range(2); seg += range(1), ++seg_id ) {
                const TestProbe &probe = *probes[nch_id];
                const Histogram<double> &sh = probe.h_speed[seg_id];
                curve.AddPoint( Point2D(seg, nch * sh.MeanAll(), nch * sh.RmsAll()) );
            }
            speeds.push_back(curve);
        }

        // COLLECT CURVES ON A PLOT //
        Plot2D plot("Throughput vs Segment Size");
        std::cout << " ---- COLLECTED SPEEDS  ------ \n";
        foreach (Curve2D &speed, speeds) {
            std::cout << speed << "\n";
            plot.AddCurve(speed);
        }

        // PRINT TO CSV FILE //
        plot.XAxis().name = "size";
        plot.PrintToCsv(filename_out);

        // SET PLOT TITLES AND LABELS //
        {
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
            plot.YAxis().limits[0] = 0;
            plot.YAxis().limits[1] = NAN;
        }

        // PRINT PLOT TO GNUPLOT FILE //
        plot.PrintToGnuplotFile(filename_out);

        // EXPORT A SHELL SCRIPT CONFIGURATION //
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
    }


    ////////////////////////////////////////////////////////////////////////////////
    //  PLOT STATS  ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    if( !g_options.link.iface.empty() )
    {
        // CREATE CURVES FROM HISTOGRAMS //
        std::vector<Curve2D> speeds;
        std::vector<Curve2D> link_rx;
        std::vector<Curve2D> link_tx;
        //        std::vector<Curve2D> link_rx_d;
        //        std::vector<Curve2D> link_tx_d;
        //        std::vector<Curve2D> link_rx_e;
        //        std::vector<Curve2D> link_tx_e;

        for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
        {
            int nch = g_options.n_channels[nch_id];
            std::stringstream curve_name;
            curve_name << nch << " mdsip";
            Curve2D curve(curve_name.str().c_str());
            int seg_id = 0;
            for(int seg = range(0); seg < range(2); seg += range(1), ++seg_id ) {
                const TestProbe &probe = *probes[nch_id];
                const Histogram<double> &sh = probe.h_speed[seg_id];
                curve.AddPoint( Point2D(seg, nch * sh.MeanAll(), nch * sh.RmsAll()) );
            }
            speeds.push_back(curve);
        }

        // link rx //
        for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
        {
            Curve2D curve("Link rx");
            int seg_id = 0;
            for(int seg = range(0); seg < range(2); seg += range(1), ++seg_id ) {
                const TestProbe &probe = *probes[nch_id];
                const Histogram<double> &h = probe.h_rx[seg_id];
                curve.AddPoint( Point2D(seg, h.MeanAll(), h.RmsAll()) );
            }
            link_rx.push_back(curve);
        }

        // link tx //
        for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
        {
            Curve2D curve("Link tx");
            int seg_id = 0;
            for(int seg = range(0); seg < range(2); seg += range(1), ++seg_id ) {
                const TestProbe &probe = *probes[nch_id];
                const Histogram<double> &h = probe.h_tx[seg_id];
                curve.AddPoint( Point2D(seg, h.MeanAll(), h.RmsAll()) );
            }
            link_tx.push_back(curve);
        }

        // CREATE PLOTS ONE PER CHANNELS CONFIGURATION //
        for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
        {
            int nch = g_options.n_channels[nch_id];
            std::string filename = filename_out+"_stats_"+to_string(nch);

            // COLLECT CURVES ON A PLOT //
            Plot2D plot("Link interface throughput vs Segment Size");
            plot.AddCurve(speeds[nch_id]);
            plot.AddCurve(link_rx[nch_id]);
            plot.AddCurve(link_tx[nch_id]);

            //
            //
            // TODO: add drops and errors
            //
            //

            // PRINT TO CSV FILE //
            plot.XAxis().name = "size";
            plot.PrintToCsv(filename);

            // SET PLOT TITLES AND LABELS //
            {
                std::string prtcl = "tcp";
                if(!g_target_tree.Path().protocol.empty()) prtcl = g_target_tree.Path().protocol;
                plot.SetName( plot.GetName() + " in " + g_target_tree.Path().protocol );
                std::string subtitle;
                subtitle = "(local time: " + FileUtils::CurrentDateTime() + ")";
                const char * hostname = FileUtils::GetEnv("HOSTNAME");
                if(hostname) subtitle += " " + std::string(hostname) + "  -->  " + g_target_tree.Path().server;
                plot.SetSubtitle(subtitle);
                plot.XAxis().name = "Segment size [KB] of signal data";
                plot.YAxis().name = "Total Link Troughput [MB/s]";
            }

            // PRINT PLOT TO GNUPLOT FILE //
            plot.PrintToGnuplotFile(filename);

        }
    }


    ////////////////////////////////////////////////////////////////////////////////
    //  PLOT EV CURVES  ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    {
        // GET CURVES //
        for(int prb = 0; prb < g_options.probes; ++prb )
        for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
        {
            int seg_id = 0;
            for(int seg = range(0); seg < range(2); seg += range(1), ++seg_id ) {
                const TestProbe &probe = *probes[nch_id];

                // CREATE PLOT //
                int nch = g_options.n_channels[nch_id];
                std::string filename = filename_out
                        +"_evspeed_"+to_string(nch)
                        +"_seg"+to_string(seg)
                        +"_p"+to_string(prb);

                std::string title = "Evolution of per ch throughput [ch="+to_string(nch)+"]";
                Plot2D plot(title.c_str());

                { // ADD CURVES //
                    int i = 0;
                    for(int pc=nch*prb; pc<nch*(prb+1); ++pc ) {
                        Curve2D c = probe.c_speed[seg_id].at(pc);
                        std::string name = "ch"+to_string(i++);
                        c.SetName(name);
                        plot.AddCurve(c);
                    }
                }

                // PRINT TO CSV FILE //
                plot.XAxis().name = "time ev";
                plot.PrintToCsv(filename);

                // SET PLOT TITLES AND LABELS //
                {
                    std::string prtcl = "tcp";
                    if(!g_target_tree.Path().protocol.empty()) prtcl = g_target_tree.Path().protocol;
                    plot.SetName( plot.GetName() + " in " + g_target_tree.Path().protocol );

                    // SUBTITLE //
                    std::string subtitle;
                    subtitle += " seg="+to_string(seg);
                    subtitle += " prb="+to_string(prb);
                    subtitle += " " + FileUtils::CurrentDateTime() + ")";
                    const char * hostname = FileUtils::GetEnv("HOSTNAME");
                    if(hostname) subtitle += " " + std::string(hostname)
                            + "  -->  " + g_target_tree.Path().server;
                    plot.SetSubtitle(subtitle);

                    plot.XAxis().name = "Connection time";
                    plot.YAxis().name = "Total Link Troughput [MB/s]";
                    plot.YAxis().limits[0] = 0;
                    plot.YAxis().limits[1] = NAN;
                }

                // PRINT PLOT TO GNUPLOT FILE //
                plot.PrintToGnuplotFile(filename);
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    //  PLOT EV CURVES  ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    if(g_target_tree.Path().protocol == "tcp")
    {
        for(int prb = 0; prb < g_options.probes; ++prb )
            for(int nch_id = 0; nch_id < g_options.n_channels.size(); nch_id++)
            {
                int seg_id = 0;
                for(int seg = range(0); seg < range(2); seg += range(1), ++seg_id ) {
                    const TestProbe &probe = *probes[nch_id];
                    int nch = g_options.n_channels[nch_id];

                    // CREATE PLOT //
                    // FileUtils::CreateDir("ev_speed");
                    std::string filename = filename_out
                            +"_ev_"+to_string(nch)
                            +"_seg"+to_string(seg)
                            +"_p"+to_string(prb);
                    std::string title = "Evolution of Sockets Buffer [ch="+to_string(nch)+"]";
                    Plot2D plot(title.c_str());

                    // { // ADD RCVBUF CURVES //
                    //   int i = 0;
                    //   foreach(Curve2D c, probe.c_rcvbuf[seg_id]) {
                    //    std::string name = "rcv ch"+to_string(i++);
                    //    c.SetName(name);
                    //    plot.AddCurve(c);
                    //   }
                    // }

                    { // ADD CURVES //
                        int i = 0;
                        for(int pc=nch*prb; pc<nch*(prb+1); ++pc ) {
                            Curve2D c = probe.c_speed[seg_id].at(pc);
                            std::string name = "bwt ch"+to_string(i++);
                            c.SetName(name);
                            plot.AddCurve(c,0);
                        }
                    }

                    { // ADD SNDBUF CURVES //
                        int i = 0;
                        for(int pc=nch*prb; pc<nch*(prb+1); ++pc ) {
                            Curve2D c = probe.c_sndbuf[seg_id].at(pc);
                            std::string name = "buf ch"+to_string(i++);
                            c.SetName(name);
                            plot.AddCurve(c,1);
                        }
                    }


                    // PRINT TO CSV FILE //
                    plot.XAxis(0).name = "socket bufev";
                    plot.XAxis(1).name = "socket bufev";
                    plot.PrintToCsv(filename);

                    // SET PLOT TITLES AND LABELS //
                    {
                        std::string prtcl = "tcp";
                        if(!g_target_tree.Path().protocol.empty()) prtcl = g_target_tree.Path().protocol;
                        plot.SetName( plot.GetName() + " in " + g_target_tree.Path().protocol );

                        // SUBTITLE
                        std::string subtitle;
                        subtitle += " seg="+to_string(seg);
                        subtitle += " prb="+to_string(prb);
                        subtitle += " " + FileUtils::CurrentDateTime() + ")";
                        const char * hostname = FileUtils::GetEnv("HOSTNAME");
                        if(hostname) subtitle += " " + std::string(hostname)
                                + "  -->  " + g_target_tree.Path().server;
                        plot.SetSubtitle(subtitle);

                        plot.XAxis(0).name = "Connection time";
                        plot.XAxis(1).name = "Connection time";
                        plot.YAxis(0).name = "Total Link Troughput [MB/s]";
                        plot.YAxis(1).name = "Buffer Size [KB]";
                        plot.YAxis(0).limits[0] = 0;
                        plot.YAxis(0).limits[1] = NAN;
                        plot.YAxis(1).limits[0] = 0;
                        plot.YAxis(1).limits[1] = NAN;
                    }

                    // PRINT PLOT TO GNUPLOT FILE //
                    plot.PrintToGnuplotFile(filename);
                }
            }
    }




    return 0;
}




























