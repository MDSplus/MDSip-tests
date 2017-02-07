#ifndef BANDUTILS_H
#define BANDUTILS_H

#include <linux/if_link.h>
#include "ext_tools/nl_link.h"

#include "DataUtils.h"

namespace mdsip_test {
class NLStats {
    struct nlsock_link_stats *m_ptr;
    struct rtnl_link_stats    A,B;
    Timer                     m_timer;
public:

    NLStats(const char *devname) :
        m_ptr(nl_link_setup(devname))
    {
        if(m_ptr)
            nl_link_getstats(m_ptr,&A);
        m_timer.Start();
    }
    ~NLStats() { if(m_ptr) nl_link_release(m_ptr); }

    void Start() {
        if(m_ptr) {
            nl_link_read(m_ptr);
            nl_link_getstats(m_ptr,&A);
        }
        m_timer.Start();
    }

    void Stop() {
        if(m_ptr) {
            nl_link_read(m_ptr);
            nl_link_getstats(m_ptr,&B);
        }
        m_timer.StopWatch();
    }

    struct rtnl_link_stats GetDiff() {
        struct rtnl_link_stats d;
        if(m_ptr)
            for (int i=0; i<sizeof(d)/sizeof(__u32); ++i)
                ((__u32*)&d)[i] = ((__u32*)&B)[i] - ((__u32*)&A)[i];
        else
            memset(&d,0,sizeof(d));
        return d;
    }

};
} // mdsip_tests

#endif // BANDUTILS_H
