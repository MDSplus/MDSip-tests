#include <unistd.h>
#include "BandUtils.h"

using namespace mdsip_test;

int _main(int argc, char *argv[])
{
    std::cout << "BandUtils\n";
    if (argc < 2) return 1;
    NLStats nll(argv[1]);


    for(;;) {
        nll.Start();
        usleep(10000);
        nll.Stop();
        struct rtnl_link_stats d = nll.GetDiff();
    }
    return 0;
}



int main(int argc, char *argv[]) {

    if(argc < 2) {
        std::cerr << "usage: " << argv[0] << " mdsaddr\n";
        exit(1);
    }

    mds::Connection cnx(argv[1],0);

    SocketOptMonitor cmon;
    cmon.SetFromMdsConnection(&cnx);

    float arr[1];
    unique_ptr<mds::Float32Array> a = new mds::Float32Array(arr,1);
    mds::Data * args[1];
    args[0] = a;

    while(1) {
        cnx.get("size($1)",args,1);
        usleep(100000);
        std::cout << cmon.Update() << " ";
        std::cout << "Soket buf = " << cmon.d.rcvbuf << " " << cmon.d.sndbuf << "\n";
    }

}
