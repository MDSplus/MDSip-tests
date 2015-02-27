

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
Point2D<double> segment_size_throughput_MP(size_t size_KB,
                                           int nch = 1,
                                           int nseg = 20)
{

    TestConnectionMP conn(g_target_tree);

    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //

    size_t tot_size = size_KB * nseg;

    // prepare channels //
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(functions[i],channels[i]);
    }


    std::cout << "\n /////// connecting " << nch << " channels [" << size_KB << " KB]: //////// \n" << std::flush;

    conn.StartConnection();

    std::cout << "CHANNELS TIMES:\n";
    Point2D<double> time, speed;
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
    if(argc > 1) {
        g_target_tree = TestTree("test_size", argv[1]);
    }
    else {
        char *path = TestTree::GetEnvPath("test_size");
        if(path) {
            g_target_tree = TestTree("test_size",path);
        }
    }

    std::cout << "CONNECTING TARGET: " << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";

    static const int n_channels = 1;
    static const int seg_step   = 1024;
    static const int seg_max    = 1024;

    std::vector<Curve2D> speeds;
    std::vector<Curve2D> speed_errors;

    for(int nch = 1; nch <= n_channels; nch*=2 )
    {
        std::stringstream curve_name;
        curve_name << "ch" << nch;
        speeds.push_back(Curve2D(curve_name.str().c_str()));
        curve_name << "_err";
        speed_errors.push_back(Curve2D(curve_name.str().c_str()));

        for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid )
        {
            unsigned int seg_size = seg_step*(sid+1);
            Point2D<double> pt;
            pt = segment_size_throughput_MP(seg_size,nch);

            Curve2D &speed = speeds.back();
            Curve2D &speed_error = speed_errors.back();

            speed.AddPoint( Point2D<double>(seg_size,pt(0)) );
            speed_error.AddPoint( Point2D<double>(seg_size,pt(1)) );
        }
    }

    std::ofstream file;
    file.open("test_segment_size.csv");
    static const char sep = ';';

    std::cout << " ---- COLLECTED SPEEDS  ------ \n";
    file << "segment size";
    for(unsigned int nch=0; nch<speeds.size(); ++nch)
    {
        Curve2D &speed = speeds[nch];
        Curve2D &speed_error = speed_errors[nch];
        std::cout << speed << "\n";
        file << sep << speed.GetName() << sep << speed_error.GetName();
    }
    file << std::endl;

    for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid )
    {
        unsigned int seg_size = seg_step*(sid+1);
        file << seg_size;
        for(unsigned int nch=0; nch<speeds.size(); ++nch ) {
            Curve2D &speed = speeds[nch];
            Curve2D &speed_error = speed_errors[nch];
            file << sep << speed[sid](1) << sep << speed_error[sid](1);
        }
        file << std::endl;
    }

    file.close();

    return 0;
}




























