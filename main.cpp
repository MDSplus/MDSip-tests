

#include <iostream>

#include <mdsobjects.h>

#include "FileUtils.h"
#include "TreeUtils.h"

#include "TestContent.h"
#include "TestConnection.h"

using namespace MDSplus;




int main(int argc, char *argv[])
{

    ContentFunction cs1("test_c1",100);
    //    cs1.SetGenFunction(ContentFunction::NoiseW);

    ContentFunction cs2("test_c2",100);
    //    cs2.SetGenFunction(ContentFunction::NoiseG);

    ContentFunction cs3("test_c3",100);
    ContentFunction cs4("test_c4",100);



    TestConnectionMT dc("test_tree");
    dc.AddChannel( cs1, Channel::NewDC(100) );
    dc.AddChannel( cs2, Channel::NewDC(100) );
    dc.AddChannel( cs3, Channel::NewTC(100,"localhost:8000") );
    dc.AddChannel( cs4, Channel::NewTC(100,"localhost:8000") );

    dc.StartConnection();

    return 0;
}









