#ifndef TESTCONNECTION_H
#define TESTCONNECTION_H

#include <assert.h>
#include <sys/time.h>
#include <vector>
#include <map>

#include <mdsobjects.h>

#include "TreeUtils.h"
#include "TestContent.h"
#include "DataUtils.h"


////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Channel {

public:

    static Channel * NewDC(int size_KB);
    static Channel * NewTC(int size_KB, const char *addr = "localhost");

    virtual void Open(const char *tree) = 0;
    virtual void Close() = 0;

    virtual size_t Size() const = 0;

    virtual void PutSegment(Content::Element &el) /*const*/ = 0;
protected:
    virtual ~Channel() {}

};



////////////////////////////////////////////////////////////////////////////////
//  TestConnection Base   //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class TestConnection {
public:

    typedef Histogram<double> TimeHistogram;

    TestConnection( std::string connection_string )
    {
        m_tname = TestTree::GetTreeName(connection_string);
        m_tree = TestTree::CreateTree(m_tname.name.c_str());
        m_tree->write();
    }

    virtual double StartConnection();

    virtual void AddChannel(Content &cnt, Channel *ch) {
        m_channels.push_back(ch);
        m_chtimes[ch] =  TimeHistogram(cnt.GetName().c_str(),50,0,0.0012);
    }

    mds::Tree * GetTree() const { return m_tree; }

    std::string GetTreeName() { return m_tname.name; }

    TimeHistogram & GetChannelTimes(Channel *ch) { return m_chtimes[ch]; }

    void PrintChannelTimes(std::ostream &o);


protected:

    mds::Tree * m_tree;
    TestTree::TreeName m_tname;

    std::vector<Channel *> m_channels;
    std::map< Channel *, TimeHistogram > m_chtimes;
};








////////////////////////////////////////////////////////////////////////////////
//  Connection Multi Threaded  /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class Thread; // fwd //

class TestConnectionMT : public TestConnection, Lockable {

    typedef TestConnection BaseClass;

    friend class ChannelThread;

public:

    TestConnectionMT(std::string name) :
        TestConnection(name)
    {}

    ~TestConnectionMT()
    {
        ClearChannels();
    }


    void AddChannel(Content &cnt, Channel *ch);

    void ClearChannels();

    double StartConnection();

private:
    std::vector<Thread *> m_threads;
};





#endif // TESTCONNECTION_H

