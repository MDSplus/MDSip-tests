

#include <iostream>
#include <fstream>

#include <mdsobjects.h>

#include "FileUtils.h"
#include "TreeUtils.h"

#include "TestContent.h"
#include "TestConnection.h"

#include "DataUtils.h"

using namespace MDSplus;



void test_data_utils() {


    Point2D<double> p;
    p << 1,2;

    std::cout << p << "\n";


    Histogram<double> h("test",20,-10,10);
    for (int i = 0; i< 10000000; ++i) {
        //h << (double)rand() / RAND_MAX * 100;
        h << box_muller(i);
    }
    std::cout << "Histogram\n" << h << "\n";

}


int main(int argc, char *argv[])
{

    ContentFunction cs1("test_c1",500);
    //    cs1.SetGenFunction(ContentFunction::NoiseW);

    ContentFunction cs2("test_c2",500);
    //    cs2.SetGenFunction(ContentFunction::NoiseG);

    ContentFunction cs3("test_c3",500);
    ContentFunction cs4("test_c4",500);


    TestConnectionMT dc("test_tree");
    dc.AddChannel( cs1, Channel::NewDC(100) );
    dc.AddChannel( cs2, Channel::NewDC(100) );
    dc.AddChannel( cs3, Channel::NewTC(100,"localhost:8000") );
    dc.AddChannel( cs4, Channel::NewTC(100,"localhost:8000") );

    dc.StartConnection();


    std::ofstream file;
    file.open("test_tree.csv");

    dc.PrintChannelTimes(file);

    file.close();

    return 0;
}



int _main(int argc, char *argv[])
{
    test_data_utils();
    return 0;
}






