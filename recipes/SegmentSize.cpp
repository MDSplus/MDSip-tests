

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
                                   int nseg = 5)
{
    typedef TestConnection::TimeHistogram _Histogram;

    TestConnectionMP conn(g_target_tree);

    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //

    size_t tot_size = size_KB * nseg;

    ////////////////////////////////////////////////////////////////////////////
    // PARAMETERS //////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    _Histogram time_h ("ch time ",100,0,5);
    _Histogram speed_h("ch speed",100,0,20);
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


    std::cout << "\n /////// connecting " << nch << " channels [" << size_KB << " KB]: //////// \n" << std::flush;

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

    for(int i=0; i<nch; ++i) {
        delete channels[i];
        delete functions[i];
    }
    return speed;
}




////////////////////////////////////////////////////////////////////////////////
//  MAIN  //////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


int main(int argc, char *argv[])
{
    if(argc > 1) g_target_tree = TestTree("test_size", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("test_size");
        if(path) { g_target_tree = TestTree("test_size",path); }
    }
    std::cout << "CONNECTING TARGET: "
              << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";


    std::vector<int> n_channels;

    ////////////////////////////////////////////////////////////////////////////
    // PARAMETERS //////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    n_channels                 << 1;
    static const int seg_step   = 128;
    static const int seg_max    = 128;
    ////////////////////////////////////////////////////////////////////////////

    std::vector<Curve2D> speeds;

    foreach(int nch, n_channels)
    {
        std::stringstream curve_name;
        curve_name << nch << " ch";
        Curve2D curve(curve_name.str().c_str());
        speeds.push_back(curve);

        for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid )
        {
            unsigned int seg_size = seg_step*(sid+1);
            Point2D pt;
            pt = segment_size_throughput_MP(seg_size,nch);

            Curve2D &speed = speeds.back();
            speed.AddPoint( Point2D(seg_size,pt(0),pt(1)) );
        }
    }


    Plot2D plot("Throughput vs Segment Size");

    std::cout << " ---- COLLECTED SPEEDS  ------ \n";
    foreach (Curve2D &speed, speeds) {
        std::cout << speed << "\n";
        plot.AddCurve(speed);
    }

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

    plot.PrintToCsv("test_segment_size");
    plot.PrintToGnuplotFile("test_segment_size");

    return 0;
}




























