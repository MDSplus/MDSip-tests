

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
                                           std::vector<Curve2D> &speed_curve,
                                           int nch = 1,
                                           int nseg = 50)
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

        speed_curve.at(i) = speed_h;

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



int main(int argc, char *argv[])
{
    if(argc > 1) {
        g_target_tree = TestTree("test_speed", argv[1]);
    }
    else {
        char *path = TestTree::GetEnvPath("test_speed");
        if(path) {
            g_target_tree = TestTree("test_speed",path);
        }
    }

    std::cout << "CONNECTING TARGET: " << TestTree::TreePath::toString(g_target_tree.Path()) << "\n";

    static const int n_channels  = 1;
    static const int n_samples   = 50;
    static const int seg_size    = 128;

    std::vector<Curve2D> speeds;

    for(int nch = 1; nch <= n_channels; nch++ )
    {
        std::stringstream curve_name;
        curve_name << "ch" << nch;
        speeds.push_back(Curve2D(curve_name.str().c_str()));
    }

    segment_size_throughput_MP(seg_size,speeds,n_channels,n_samples);



    std::ofstream file;
    file.open("segment_size_speed_distr.csv");
    static const char sep = ';';

    std::cout << " ---- COLLECTED SPEEDS  ------ \n";
    file << "speed";
    for(unsigned int nch=0; nch<n_channels; ++nch)
    {
        Curve2D &speed = speeds[nch];
        std::cout << speed << "\n";
        file << sep << speed.GetName();
    }
    file << std::endl;

    for(unsigned int sid = 0; sid<speeds.at(0).Size() ; ++sid )
    {
        Curve2D &speed = speeds[0];
        file << speed[sid](0);
        for(unsigned int nch=0; nch<n_channels; ++nch ) {
            Curve2D &speed = speeds[nch];
            file << sep << speed[sid](1);
        }
        file << std::endl;
    }

    file.close();

    return 0;
}





























