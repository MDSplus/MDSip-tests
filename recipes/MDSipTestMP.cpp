

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





////////////////////////////////////////////////////////////////////////////////
//  TEST: SEGMENT SIZE  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


/// \param size_KB size of segment to be sent
/// \param speed a reference to histogram to collect speed
/// \param nch number of forked channels (sine) to be used
/// \param tot_size total size per channel to be sent
/// \return 0
///
/// Test for segment size in Multi Process using Thin Client connection.
/// In histogram a value of equivalent data troughput is added in MB/s
/// This is not the actual line speed becouse reflects the time to sent actual
/// data into the channel.
///
int segment_size_testMP(size_t size_KB,
                        Histogram<double> &speed,
                        int nch = 1,
                        size_t tot_size = 1024)
{
    std::vector<ContentFunction *> functions; // function generators //
    std::vector<Channel *>         channels;  // forked channels //

    TestConnectionMP conn("test_size");

    for(int i=0; i<nch; ++i) {
        std::stringstream name;
        name << "sine" << i;
        functions.push_back( new ContentFunction(name.str().c_str(),tot_size) );
        // << FIX: server name is hard coded !
        //        channels.push_back( Channel::NewTC(size_KB,"localhost:8000") );
        channels.push_back( Channel::NewTC(size_KB,"rat.rfx.local:8200") );
        conn.AddChannel(functions[i],channels[i]);
    }

    speed.Clear();
    Accumulator<double> tot_speed("overall speed");

    for(int i=0; i<4; ++i) {
        std::cout << "connecting: -> " << std::flush;

        for(unsigned int i=0; i<functions.size(); ++i)
            functions[i]->ResetSize(tot_size); // reset time of generator //
        conn.ResetTimes();             // reset per channel distributions //

        // speed is total size in MB [tot_size/1024] multiplied per number of
        // channels (as each channel send tot_size data) and divided  by  the
        // total connection time.
        //        speed << ((double)tot_size) / 1024 / conn.StartConnection() * nch;

        double tot_time = conn.StartConnection();
        double cnx_time = conn.GetWorstChannelTime();

//        std::cout << "connection times: tot=" << tot_time << " cnx=" << cnx_time << "\n";

//        std::cout <<  "tot speed: " << ((double)tot_size) / 1024 / tot_time * nch;
//        std::cout <<  "cnx speed: " << ((double)tot_size) / 1024 / cnx_time * nch;

        tot_speed << ((double)tot_size) / 1024 / tot_time * nch;
        speed << ((double)tot_size) / 1024 / cnx_time * nch;
    }

    std::cout << "--- connection segment size: " << size_KB << " [KB] \n";

    std::cout  << tot_speed << "\n";
    std::cout  << speed << "\n";
    std::cout << "speed [MB/s] | Mean: " << speed.MeanAll() << " Rms: " << speed.RmsAll() <<  "\n\n";

    for(unsigned int i=0; i<channels.size(); ++i) {
        delete channels[i];
        delete functions[i];
    }
    return 0;
}






int main(int argc, char *argv[])
{
    static const int n_channels = 2;
    static const int seg_step   = 128;
    static const int seg_max    = 1024;

    std::vector<Curve2D> speeds;
    std::vector<Curve2D> speed_errors;

    for(int nch = 1; nch <= n_channels; nch++ )
    {
        std::stringstream curve_name;
        curve_name << "ch" << nch;
        speeds.push_back(Curve2D(curve_name.str().c_str()));
        curve_name << "_err";
        speed_errors.push_back(Curve2D(curve_name.str().c_str()));
        for(unsigned int sid = 0; sid < seg_max/seg_step; ++sid )
        {
            unsigned int seg_size = seg_step*(sid+1);
            Histogram<double> sph("test_segment_size",40,0,30);
            segment_size_testMP(seg_size,sph,nch);

            Curve2D &speed = speeds.back();
            Curve2D &speed_error = speed_errors.back();

            Point2D<double> pt;
            pt << seg_size,sph.MeanAll();
            speed.AddPoint(pt);
            pt << seg_size,sph.RmsAll();
            speed_error.AddPoint(pt);
        }
    }

    std::ofstream file;
    file.open("test_segment_size.csv");
    static const char sep = ';';

    std::cout << " ---- COLLECTED SPEEDS  ------ \n";
    file << "segment size";
    for(unsigned int nch=0; nch<n_channels; ++nch)
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
        for(unsigned int nch=0; nch<n_channels; ++nch ) {
            Curve2D &speed = speeds[nch];
            Curve2D &speed_error = speed_errors[nch];
            file << sep << speed[sid](1) << sep << speed_error[sid](1);
        }
        file << std::endl;
    }

    file.close();

    return 0;
}




























