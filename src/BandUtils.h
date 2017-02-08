#ifndef BANDUTILS_H
#define BANDUTILS_H

#include <linux/if_link.h>
#include "ext_tools/nl_link.h"

#include "DataUtils.h"

////////////////////////////////////////////////////////////////////////////////
//  NETLINK STATS  /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// struct rtnl_link_stats //
//	__u32	rx_packets;		/* total packets received	*/
//	__u32	tx_packets;		/* total packets transmitted	*/
//	__u32	rx_bytes;		/* total bytes received 	*/
//	__u32	tx_bytes;		/* total bytes transmitted	*/
//	__u32	rx_errors;		/* bad packets received		*/
//	__u32	tx_errors;		/* packet transmit problems	*/
//	__u32	rx_dropped;		/* no space in linux buffers	*/
//	__u32	tx_dropped;		/* no space available in linux	*/
//	__u32	multicast;		/* multicast packets received	*/
//	__u32	collisions;

//	/* detailed rx_errors: */
//	__u32	rx_length_errors;
//	__u32	rx_over_errors;		/* receiver ring buff overflow	*/
//	__u32	rx_crc_errors;		/* recved pkt with crc error	*/
//	__u32	rx_frame_errors;	/* recv'd frame alignment error */
//	__u32	rx_fifo_errors;		/* recv'r fifo overrun		*/
//	__u32	rx_missed_errors;	/* receiver missed packet	*/

//	/* detailed tx_errors */
//	__u32	tx_aborted_errors;
//	__u32	tx_carrier_errors;
//	__u32	tx_fifo_errors;
//	__u32	tx_heartbeat_errors;
//	__u32	tx_window_errors;

//	/* for cslip etc */
//	__u32	rx_compressed;
//	__u32	tx_compressed;

//	__u32	rx_nohandler;		/* dropped, no handler found	*/



namespace mdsip_test {
class NLStats {
    struct nlsock_link_stats *m_ptr;
    struct rtnl_link_stats    A,B;
    Timer                     m_timer;
public:

    NLStats() {}

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

    Timer & GetTimer() { return m_timer; }
};


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
