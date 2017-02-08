#ifndef TESTCHANNEL_H
#define TESTCHANNEL_H

#include "DataUtils.h"
#include "BandUtils.h"

#include "TestContent.h"


////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////





namespace mdsip_test {


class Channel {

public:
    typedef Histogram<double> TimeHistogram;

    typedef enum {
        DC,
        TC
    } ChannelTypeEnum;
    
    Channel(int size_KB,  const ChannelTypeEnum &kind = TC);
    ~Channel();
    
    static Channel *NewTC(int size_KB);
    static Channel *NewDC(int size_KB);
    
    void Open(TestTree &tree);

    void Close();

    size_t Size();
    
    void PutSegment(Content::Element &el);
    
    const size_t & GetErrorsCount() const;
    
    void Reset();

    void SetNoDisk(bool value);

    TimeHistogram & Times() { return m_chtimes; }
    TimeHistogram & Speeds() { return m_chspeed; }
    Curve2D & Time_Curve() { return m_chtimes_curve; }
    Curve2D & Speed_Curve() { return m_chspeed_curve; }

    Timer  m_timer;
protected:
    size_t   m_cnxerr_count;
    size_t   m_cnxerr_threshold;
    size_t   m_cnxerr_usleep;
    size_t   m_size;

    TimeHistogram m_chtimes;
    TimeHistogram m_chspeed;
    Curve2D m_chtimes_curve;
    Curve2D m_chspeed_curve;

    NLStats m_netlink_stats;          // netlink statitxtics

public:
    Histogram<double> m_rate_rx;       // netlink rx total bandwith [MB/s]
    Histogram<double> m_rate_tx;       // netlink tx total bandwith [MB/s]
    Histogram<double> m_rate_rx_drop;  //	__u32	rx_dropped;		/* no space in linux buffers	*/
    Histogram<double> m_rate_tx_drop;  //	__u32	tx_dropped;		/* no space available in linux	*/
    Histogram<double> m_rate_rx_error; //	__u32	rx_errors;		/* bad packets received		*/
    Histogram<double> m_rate_tx_error; //	__u32	tx_errors;		/* packet transmit problems	*/
    Histogram<double> m_rate_collisions;


private:
    friend class ChannelImpl;
    class ChannelImpl *d;
    
};


} // mdsip_tests

#endif // TESTCHANNEL_H


