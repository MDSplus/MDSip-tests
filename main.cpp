

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


int segment_size_test(size_t size_MB, Histogram<double> &time) {

    TestConnectionMT conn("test_size");
    ContentFunction cs1("sine1",size_MB);
    conn.AddChannel(cs1, Channel::NewDC(100));

    for(int i=0; i<100; ++i) {
        cs1.ResetSize(size_MB);
        time << conn.StartConnection();
    }

    std::cout << time << "\n";
    std::cout << "time [s]     | Mean: " << time.Mean() << "  Rms: " << time.Rms() << "\n";
    std::cout << "speed [MB/s] | Mean: " << size_MB/time.Mean() << "  Rms: " << size_MB/time.Rms() << "\n";

    return 0;
}






int main(int argc, char *argv[])
{



    Histogram<double> time("test_segment_size",20,0,5);
    segment_size_test(1,time);



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

