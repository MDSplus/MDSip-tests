#ifndef BANDUTILS_H
#define BANDUTILS_H

#include <linux/if_link.h>
#include "ext_tools/nl_link.h"

#include "Threads.h"
#include "DataUtils.h"

namespace mdsip_test {

////////////////////////////////////////////////////////////////////////////////
//  NETLINK STATS  /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

///
/// \brief The NLStats class
///
class NLStats {
    std::string m_name;
    struct rtnl_link_stats    A,B;
    Timer                     m_timer;
public:

    NLStats() {}

    NLStats(const char *devname) :
        m_name(devname) {
        //    nl_link_getstats(m_ptr,&A);
        if(!get_link_stats(m_name.c_str(),&A)) throw std::exception();
        m_timer.Start();
    }
    ~NLStats() {
        //    if(m_ptr) nl_link_release(m_ptr);
    }

    void Start() {
        //    nl_link_read(m_ptr);
        //    nl_link_getstats(m_ptr,&A);
        if(!get_link_stats(m_name.c_str(),&A)) throw std::exception();
        m_timer.Start();
    }

    void Stop() {
        //    nl_link_read(m_ptr);
        //    nl_link_getstats(m_ptr,&B);
        if(!get_link_stats(m_name.c_str(),&B)) throw std::exception();
        m_timer.StopWatch();
    }

    struct rtnl_link_stats GetDiff() {
        struct rtnl_link_stats d;
        for (int i=0; i<sizeof(d)/sizeof(__u32); ++i)
            ((__u32*)&d)[i] = ((__u32*)&B)[i] - ((__u32*)&A)[i];
        return d;
    }

    Timer & GetTimer() { return m_timer; }
private:

    static int get_link_stats(const char *iface, rtnl_link_stats *stats);

    NLStats(const NLStats &other) {}
    NLStats & operator =(const NLStats &o) {}
};



///
/// NOT USED //
///
class NLStatsAccumulator : NLStats {
    typedef NLStats BaseClass;
    const unsigned int m_size;
    Histogram<double> *m_h;
public:
    NLStatsAccumulator(const char *devname,
                       const char *h_name = "link stats", size_t nbin=100, double min=0, double max=10) :
        BaseClass(devname),
        m_size(sizeof(struct rtnl_link_stats)/sizeof(__u32)),
        m_h(new Histogram<double>[m_size])
    {
        // reset histograms to correct parameters //
        Histogram<double> tmp(h_name,nbin,min,max);
        for(int i=0;i<m_size; ++i) m_h[i] = tmp;
    }
    ~NLStatsAccumulator() {
        delete[] m_h;
    }

    void Stop() {
        BaseClass::Stop();
        // add diff elements to histograms //
        struct rtnl_link_stats d = GetDiff();
        for (int i=0; i<m_size; ++i)
            m_h[i] << ((__u32*)&d)[i];
    }
};
} // mdsip_tests

#endif // BANDUTILS_H
