#include <iostream>
#include "nl_link.h"


int main(int argc, char *argv[])
{
    struct nlsock_link_stats *sk = nl_link_setup("eno1");
    if(!sk) {
        std::cerr << "setup error\n";
        return 1;
    }
    struct rtnl_link_stats stats;
    int status = nl_link_getstats(sk, &stats);
    if(!status)
        std::cerr << "get stats error\n";
    else
        std::cout << "stat: " << stats.rx_bytes << " " << stats.tx_bytes << "\n";
    return 0;
}
