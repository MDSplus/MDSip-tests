

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


// TEST HISTOGRAM //
int _main(int argc, char *argv[])
{

    srand (time(NULL));


    Histogram<double> h("test",20,-10,10);
    for (int i = 0; i< 10000000; ++i) {
        //        h << (double)rand() / RAND_MAX * 100;
        h << box_muller(i);
    }
    std::cout << "Histogram\n" << h << "\n";
    std::cout << "mean: " << h.Mean() << "   rms: " << h.Rms() << "\n";

    Plot2D plot("plot");
    plot.AddCurve(h);

    return 0;
}


////////////////////////////////////////////////////////////////////////////////
//  TEST: SEGMENT SIZE  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


int segment_size_test() {

    Histogram<double> time("test_segment_size",20,0,2);

    TestConnectionMT conn("test_size");
    ContentFunction cs1("sine1",1);
    conn.AddChannel(cs1, Channel::NewDC(100));

    for(int i=0; i<100; ++i) {
        cs1.ResetSize(1);
        time << conn.StartConnection();
    }

    std::cout << time << "\n";
    std::cout << "Mean: " << time.Mean() << "  Rms: " << time.Rms() << "\n";


    return 0;
}






int main(int argc, char *argv[])
{

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


    segment_size_test();

    return 0;
}





