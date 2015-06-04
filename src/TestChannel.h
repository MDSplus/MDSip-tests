#ifndef TESTCHANNEL_H
#define TESTCHANNEL_H

#include "TestContent.h"


////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace mdsip_test {


class Channel {

public:
    virtual ~Channel() {}
    
    virtual void SetContent(Content *cnt) { m_content = cnt; }

    static Channel * NewDC(int size_KB);
    static Channel * NewTC(int size_KB);

    virtual void Open(TestTree &tree) = 0;

    virtual void Close() = 0;

    virtual size_t Size() const = 0;
    
    virtual void PutSegment(Content::Element &el) {}
    
    virtual void SetNoDisk(bool value) {}

protected:
    Content *m_content;
    Channel() {}
};


} // mdsip_tests

#endif // TESTCHANNEL_H


