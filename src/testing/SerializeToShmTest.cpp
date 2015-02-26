#include <iostream>
#include <fstream>
#include <time.h>

#include <unistd.h>
#include <sys/ipc.h>
#include <sys/wait.h>

//#include <sys/mman.h>
//#include <sys/shm.h>

#include "SerializeUtils.h"
#include "FileUtils.h"
#include "DataUtils.h"

#include "testing-prototype.h"


////////////////////////////////////////////////////////////////////////////////
//  TEST SERIALIZATION  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



typedef Histogram<double> TimeHistogram;

static SerializeToShm g_shm;

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


bool AreSame(TimeHistogram h1, TimeHistogram h2) {
    int same = 0;
    for(size_t i=0; i<h1.BinSize(); ++i) {
        same += h1(i) == h2(i);
    }
    return same == h2.BinSize();
}


bool TestInsideSameProc() {
    TimeHistogram h = createHistogram();
    TimeHistogram h2;

    g_shm.Write() & h;
    g_shm.Store();

    h.Clear();

    g_shm.Resume();
    g_shm.Read() & h2;

    g_shm.Clear();
    g_shm.Write() & h2;
    g_shm.Store();

    g_shm.Resume();
    g_shm.Read() & h;


    std::cout << h << "\n"
              << h2 << "\n";
    return AreSame(h,h2);
}


bool TestWithFork() {
    TimeHistogram h1 = createHistogram();
    g_shm.Write() & h1;
    g_shm.Store();
    g_shm.Clear();

    h1.Clear();

    pid_t pid;
    if(pid = fork() == 0) {
        TimeHistogram h2 = createHistogram();
        g_shm.Write() & h2;
        g_shm.Store();
        exit(0);
    }
    waitpid(pid,NULL,0);

    std::cout << h1 << "\n";

    g_shm.Resume();
    g_shm.Read() & h1;

    std::cout << h1 << "\n";

    return AreSame(h1, createHistogram());
}


int main(int argc, char *argv[])
{
    BEGIN_TESTING(Serialize To Shm);

    TEST1( TestInsideSameProc() );
    TEST1( TestWithFork() );

    END_TESTING;
}






