

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
using namespace mdsip_test;


struct Parameters : Options {

    std::vector<int> n_channels;
    Vector3i seg_range;
    Vector2d h_speed_limits;
    Vector2d h_time_limits;
    size_t samples;

    Parameters() :
        seg_range(2048,2048,20480),
        samples(20),
        h_speed_limits(0,10),
        h_time_limits(0,5)
    {
        n_channels << 1,2,4;
        this->AddOptions()
                ("channels",&n_channels,"parallel channels to build")
                ("segments",&seg_range,"segment size [KB] (start,delta,stop)")
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



///
/// \param size_KB size of segment to be sent
/// \param nch number of forked channels (sine) to be used
/// \param nseg total number of segment per channel
/// \return mean and rms of average speed for all channels togheter
///
/// Test for segment size in Multi Process using Thin Client connection.
/// In histogram a value of equivalent data troughput is added in MB/s
/// This is not the actual line speed becouse reflects the time to sent actual
/// data into the channel.
///
Point2D segment_size_throughput_MP(size_t size_KB,
                                   int nch = 1,
                                   int nseg = g_options.samples)
{
    typedef TestConnection::TimeHistogram _Histogram;

    TestConnectionMT conn(g_target_tree);

    std::vector< unique_ptr<ContentFunction> > functions; // function generators //
    std::vector< unique_ptr<Channel> >         channels;  // forked channels //

    size_t tot_size = size_KB * nseg;

    ////////////////////////////////////////////////////////////////////////////
    // PARAMETERS //////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    const Vector2d &l1 = g_options.h_speed_limits;
    const Vector2d &l2 = g_options.h_time_limits;
    _Histogram speed_h("ch speed",100,l1(0),l1(1));
    _Histogram time_h ("ch time ",100,l2(0),l2(1));
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
              << " channels [" << size_KB << " KB]: //////// \n" << std::flush;

    conn.StartConnection();

    std::cout << "CHANNELS TIMES:\n";
    Point2D time, speed;
    for(int i=0; i<nch; ++i) {
        Channel *ch = channels[i];
        TestConnection::TimeHistogram &time_h = conn.ChannelTime(ch);
        TestConnection::TimeHistogram &speed_h = conn.ChannelSpeed(ch);
        std::cout << "times dist: " << time_h << "\n";
        std::cout << "speed dist: " << speed_h << "\n";
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

    return speed;
}




////////////////////////////////////////////////////////////////////////////////
//  MAIN  //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


int main(int argc, char *argv[])
{
    std::string program_name(argv[0]);
    g_options.SetUsage(program_name + " target_path plot_filename [options]");
    g_options.Parse(argc,argv);

    if(argc > 1) g_target_tree = TestTree("test_size", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("test_size");
        if(path) { g_target_tree = TestTree("test_size",path); }
    }
    std::string filename_out = "test_segment_size";
    if(argc > 2) filename_out = argv[2];



    std::cout << "CONNECTING TARGET: "
              << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";

    std::vector<Curve2D> speeds;
    foreach(int nch, g_options.n_channels)
    {
        std::stringstream curve_name;
        curve_name << nch << " ch";
        Curve2D curve(curve_name.str().c_str());
        speeds.push_back(curve);

        Vector3i &range = g_options.seg_range;
        for(int seg = range(0); seg < range(2); seg += std::min(range(1), range(2)-seg) )
        {            
            Point2D pt = segment_size_throughput_MP(seg,nch);
            Curve2D &speed = speeds.back();
            speed.AddPoint( Point2D(seg,pt(0),pt(1)) );
        }
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




























