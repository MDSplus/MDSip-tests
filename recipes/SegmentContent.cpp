

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

////////////////////////////////////////////////////////////////////////////
// PARAMETERS //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
Histogram<double> g_time_h ("ch time ",100,0,5);
Histogram<double> g_speed_h("ch speed",100,0,20);
TestTree g_read_src = TestTree("rfx","raserver.igi.cnr.it:: ");
const int g_read_src_pulse = 37900;
////////////////////////////////////////////////////////////////////////////





////////////////////////////////////////////////////////////////////////////////
//  TEST: SEGMENT SIZE  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Vector2d content_read_throughput_MP(size_t size_KB,
                                    int nch = 1,
                                    int nseg = 20 )
{

    TestConnectionMP conn(g_target_tree);

    std::vector< unique_ptr<Content> >  contents; // function generators //
    std::vector< unique_ptr<Channel> >  channels; // forked channels //

    size_t tot_size = size_KB * nseg;

    // prepare channels //
    for(int i=0; i<nch; ++i) {
        char name[100];

        sprintf(name,"read%i",i);
        ContentReader * cnt = new ContentReader(name,tot_size);
        g_read_src.SetClientType(TestTree::DC);
        cnt->SetTree(g_read_src,g_read_src_pulse);

        contents.push_back( cnt );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(contents[i],channels[i]);
        conn.ChannelTime(channels.back()) = g_time_h;
        conn.ChannelSpeed(channels.back()) = g_speed_h;
    }

    std::cout << "\n /////// connecting " << nch << " channels [" << size_KB << " KB]: //////// \n" << std::flush;

    conn.StartConnection();

    std::cout << "CHANNELS TIMES:\n";
    Vector2d time, speed;
    for(int i=0; i<nch; ++i) {
        Channel *ch = channels[i];
        Histogram<double> &time_h = conn.ChannelTime(ch);
        Histogram<double> &speed_h = conn.ChannelSpeed(ch);
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





Vector2d content_function_throughput_MP(size_t size_KB,
                                    enum ContentFunction::FunctionEnum ftype,
                                    int nch = 1,
                                    int nseg = 20 )
{
    typedef TestConnection::TimeHistogram _Histogram;

    TestConnectionMT conn(g_target_tree);

    std::vector< unique_ptr<Content> >  contents; // function generators //
    std::vector< unique_ptr<Channel> >  channels; // forked channels //

    size_t tot_size = size_KB * nseg;

    // prepare channels //
    for(int i=0; i<nch; ++i) {
        char name[100];

        sprintf(name,"func%i",i);
        ContentFunction * cnt = new ContentFunction(name,tot_size);
        cnt->SetGenFunction(ftype);

        contents.push_back( cnt );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(contents[i],channels[i]);
        conn.ChannelTime(channels.back()) = g_time_h;
        conn.ChannelSpeed(channels.back()) = g_speed_h;
    }

    std::cout << "\n /////// connecting " << nch << " channels [" << size_KB << " KB]: //////// \n" << std::flush;

    conn.StartConnection();

    std::cout << "CHANNELS TIMES:\n";
    Vector2d time, speed;
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
    if(argc > 1) g_target_tree = TestTree("test_size", argv[1]);
    else {
        char *path = TestTree::GetEnvPath("test_size");
        if(path) { g_target_tree = TestTree("test_size",path); }
    }
    std::cout << "CONNECTING TARGET: "
              << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";

    ////////////////////////////////////////////////////////////////////////////
    // PARAMETERS //////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    const int nch        = 1;
    const int seg_step   = 1024;
    const int seg_max    = 10240;
    ////////////////////////////////////////////////////////////////////////////

    std::vector<Curve2D> speeds;

    { // READ //
        Curve2D speed("read");
        for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid ) {
            unsigned int seg_size = seg_step*(sid+1);
            Vector2d pt = content_read_throughput_MP(seg_size,nch);
            speed.AddPoint( Point2D(seg_size,pt(0),pt(1)) );
        }
        speeds.push_back(speed);
    }
    { // SINE //
        Curve2D speed("sine");
        for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid ) {
            unsigned int seg_size = seg_step*(sid+1);
            Vector2d pt = content_function_throughput_MP(seg_size,ContentFunction::Sine,nch);
            speed.AddPoint( Point2D(seg_size,pt(0),pt(1)) );
        }
        speeds.push_back(speed);
    }
    { // NOISE W //
        Curve2D speed("noiseW");
        for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid ) {
            unsigned int seg_size = seg_step*(sid+1);
            Vector2d pt = content_function_throughput_MP(seg_size,ContentFunction::NoiseW,nch);
            speed.AddPoint( Point2D(seg_size,pt(0),pt(1)) );
        }
        speeds.push_back(speed);
    }
    { // NOISE G //
        Curve2D speed("noiseG");
        for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid ) {
            unsigned int seg_size = seg_step*(sid+1);
            Vector2d pt = content_function_throughput_MP(seg_size,ContentFunction::NoiseG,nch);
            speed.AddPoint( Point2D(seg_size,pt(0),pt(1)) );
        }
        speeds.push_back(speed);
    }


    Plot2D plot("Content Throughput vs Segment Size");

    std::cout << " ---- COLLECTED SPEEDS  ------ \n";
    foreach (Curve2D &speed, speeds) {
        std::cout << speed << "\n";
        plot.AddCurve(speed);
    }

    {   // SET PLOT TITLES AND LABELS //
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

    plot.PrintToCsv("test_segment_content");
    plot.PrintToGnuplotFile("test_segment_content");

    return 0;
}










