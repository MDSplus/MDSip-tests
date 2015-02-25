


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
                                           Curve2D &speed_curve,
                                           Curve2D &time_curve,
                                           int nch = 1,
                                           int nseg = 50)
{
    typedef TestConnection::TimeHistogram _Histogram;

    TestConnectionMP conn(g_target_tree);

    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //

    size_t tot_size = size_KB * nseg;

    _Histogram speed_h_sum("speed_sum",100,0,0.2);
    _Histogram time_h_sum("time_sum",100,0,2);

    // prepare channels //
    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        channels.push_back( Channel::NewTC(size_KB) );
        conn.AddChannel(functions.back(),channels.back());

        _Histogram &time_h = conn.ChannelTime(channels.back());
        _Histogram &speed_h = conn.ChannelSpeed(channels.back());
        time_h = time_h_sum;
        speed_h = speed_h_sum;
    }

    std::cout << "\n /////// connecting " << nch << " channels [" << size_KB << " KB]: //////// \n" << std::flush;

    conn.StartConnection();

    std::cout << "CHANNELS TIMES:\n";
    Point2D<double> time, speed;

    for(int i=0; i<nch; ++i) {
        Channel *ch = channels[i];
        _Histogram &time_h = conn.ChannelTime(ch);
        _Histogram &speed_h = conn.ChannelSpeed(ch);
        std::cout << "times dist: " << time_h << "\n";
        std::cout << "speed dist: " << speed_h << "\n";

        time_h_sum = _Histogram::merge(time_h_sum,time_h);
        speed_h_sum = _Histogram::merge(speed_h_sum,speed_h);

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
    speed_curve = speed_h_sum;
    time_curve = time_h_sum;

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

    static const int n_channels  = 4;
    static const int n_samples   = 200;
    static const int seg_size    = 40;

    std::vector<Curve2D> speeds;
    std::vector<Curve2D> times;

    for(int nch = 1; nch <= n_channels; nch++ )
    {
        Curve2D speed;
        Curve2D time;
        segment_size_throughput_MP(seg_size,speed,time,nch,n_samples);
        std::stringstream curve_name;
        curve_name << "ch" << nch;
        speed.SetName(curve_name.str().c_str());
        time.SetName(curve_name.str().c_str());
        speeds.push_back(speed);
        times.push_back(time);
    }

    {
        std::ofstream file;
        file.open("segment_size_speed_distr.csv");
        const char sep = ';';

        std::cout << " ---- COLLECTED SPEEDS  ------ \n";
        file << "speed";
        for(unsigned int nch=0; nch<speeds.size(); ++nch)
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
            for(unsigned int nch=0; nch<speeds.size(); ++nch ) {
                Curve2D &speed = speeds[nch];
                file << sep << speed[sid](1);
            }
            file << std::endl;
        }
        file.close();
    }

    {
        std::ofstream file;
        file.open("segment_size_time_distr.csv");
        const char sep = ';';

        std::cout << " ---- COLLECTED TIMES  ------ \n";
        file << "time";
        for(unsigned int nch=0; nch<times.size(); ++nch)
        {
            Curve2D &time = times[nch];
            std::cout << time << "\n";
            file << sep << time.GetName();
        }
        file << std::endl;

        for(unsigned int sid = 0; sid<times.at(0).Size() ; ++sid )
        {
            Curve2D &time = times[0];
            file << time[sid](0);
            for(unsigned int nch=0; nch<times.size(); ++nch ) {
                Curve2D &time = times[nch];
                file << sep << time[sid](1);
            }
            file << std::endl;
        }
        file.close();
    }

    return 0;
}





























