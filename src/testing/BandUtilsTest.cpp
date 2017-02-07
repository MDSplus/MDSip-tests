#include <unistd.h>
#include "BandUtils.h"

using namespace mdsip_test;

int main(int argc, char *argv[])
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
