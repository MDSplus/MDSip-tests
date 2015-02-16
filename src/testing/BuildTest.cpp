#include <iostream>
#include <fstream>
#include <time.h>

#include <mdsobjects.h>

#include "FileUtils.h"
#include "TreeUtils.h"
#include "TestContent.h"
#include "TestConnection.h"
#include "DataUtils.h"

#include "testing-prototype.h"

using namespace MDSplus;



typedef Histogram<double> TimeHistogram;


TimeHistogram createHistogram() {

    //    TimeHistogram h("test",40,0,10);
    //    for (unsigned int i=0; i<100000; i++) {
    //        h << box_muller(0) / 2 + 5;
    //    }

    TimeHistogram h("test",5,0,5);
    h << 1;
    h << 2 << 2;
    h << 3 << 3 << 3;
    h << 4 << 4 << 4 << 4;

    return h;
}


int main(int argc, char *argv[])
{

    TimeHistogram h = createHistogram();
    h.Clear();
    return 0;
}

