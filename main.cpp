

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


int segment_size_test(size_t size_KB, Histogram<double> &time) {

    TestConnectionMT conn("test_size");
    ContentFunction cs1("sine1",1024);
    conn.AddChannel(cs1, Channel::NewDC(size_KB));

    for(int i=0; i<100; ++i) {
        cs1.ResetSize(1024);
        time << conn.StartConnection();
    }

    //    std::cout << time << "\n";
    std::cout << "time [s]     | Mean: " << time.Mean() << "  Rms: " << time.Rms() << "\n";
    std::cout << "speed [MB/s] | Mean: " << size_KB/time.Mean() << "\n";

    return 0;
}






int main(int argc, char *argv[])
{


    Curve2D speed("speed_vs_segment_size");
    Curve2D speed_error("speed_vs_segment_size_error");

    for(int i = 32; i < 1024; i += 32 )
    {
        Histogram<double> time("test_segment_size",20,0,0.5);
        segment_size_test(i,time);
        Point2D<double> pt;
        pt << i,time.Mean();
        speed.AddPoint(pt);
        pt << i,time.Rms();
        speed_error.AddPoint(pt);
    }


    std::ofstream file;
    file.open("test_segment_size.csv");
    file << speed << "\n";
    file.close();

    file.open("test_segment_size_error.csv");
    file << speed_error << "\n";
    file.close();

    return 0;
}




////////////////////////////////////////////////////////////////////////////////
//  Examples  //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void _examples() {

    ContentFunction cs1("test_c1",2);
    ContentFunction cs2("test_c2",2);
    ContentFunction cs3("test_c3",2);
    ContentFunction cs4("test_c4",2);

    TestConnectionMT dc("test_tree");

    dc.AddChannel( cs1, Channel::NewDC(160) );
    dc.AddChannel( cs2, Channel::NewDC(80) );
    dc.AddChannel( cs3, Channel::NewDC(40) );
    dc.AddChannel( cs4, Channel::NewDC(20) );

    //    dc.AddChannel( cs4, Channel::NewDC(20) );
    //    dc.AddChannel( cs3, Channel::NewTC(100,"localhost:8000") );
    //    dc.AddChannel( cs4, Channel::NewTC(100,"localhost:8000") );
    //    dc.AddChannel( cs4, Channel::NewTC(100,"ra22.igi.cnr.it:8001") );



    dc.StartConnection();

    //    std::ofstream file;
    //    file.open("test_tree.csv");
    //    dc.PrintChannelTimes(file);
    //    file.close();

}

