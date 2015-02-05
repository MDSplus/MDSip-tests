

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


int segment_size_test(size_t size_KB, Histogram<double> &speed) {

    static const int tot_size = 1024; // KB

    TestConnectionMT conn("test_size");
    ContentFunction cs1("sine1",tot_size);
    conn.AddChannel(cs1, Channel::NewTC(size_KB,"localhost:8000"));

    std::cout << "[";
    for(int i=0; i<10; ++i) {
        std::cout << "." << std::flush;
        cs1.ResetSize(tot_size);
        conn.ResetTimes();
        conn.StartConnection();
        speed << ((double)tot_size)/1024 / conn.GetTotalTime();
    }

    std::cout << "]\n";

    std::cout << "--- segment " << size_KB << " [KB] ";

    std::cout  << speed << "\n";

    std::cout << "speed [MB/s] | Mean: " << speed.MeanAll() << " Rms: " << speed.RmsAll() <<  "\n\n";

    return 0;
}






int main(int argc, char *argv[])
{


    Curve2D speed("speed_vs_segment_size");
    Curve2D speed_error("speed_vs_segment_size_error");

    for(int i = 32; i < 1024; i += 32 )
    {
        Histogram<double> sph("test_segment_size",40,0,5);
        segment_size_test(i,sph);
        Point2D<double> pt;
        pt << i,sph.Mean();
        speed.AddPoint(pt);
        pt << i,sph.Rms();
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

