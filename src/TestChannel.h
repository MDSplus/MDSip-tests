#ifndef TESTCHANNEL_H
#define TESTCHANNEL_H

#include "DataUtils.h"
#include "TestContent.h"


////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////





namespace mdsip_test {


class Channel {

public:
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
        
protected:
    size_t   m_cnxerr_count;
    size_t   m_cnxerr_threshold;
    size_t   m_cnxerr_usleep;
    size_t   m_size;

private:
    friend class ChannelImpl;
    class ChannelImpl *d;

    friend class TestConnection;
//    Histogram<double> m_chtimes;
//    Histogram<double> m_chspeed;
//    Curve2D m_chtimes_curve;
//    Curve2D m_chspeed_curve;
    
};


} // mdsip_tests

#endif // TESTCHANNEL_H


