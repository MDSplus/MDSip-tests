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

    TestConnection( std::string name ) :
        m_target_name(name)
    {
        m_tree = TreeUtils::CreateTree(m_target_name.c_str());
        m_tree->write();
    }

    virtual void StartConnection();

    virtual void AddChannel(Content &cnt, Channel *ch) {
        m_channels.push_back(ch);
        m_chtimes[ch] =  TimeHistogram(cnt.GetName().c_str(),50,0,0.002);
    }

    mds::Tree * GetTree() const { return m_tree; }

    std::string GetTreeName() { return m_target_name; }

    TimeHistogram & GetChannelTimes(Channel *ch) { return m_chtimes[ch]; }

    void PrintChannelTimes(std::ostream &o);


protected:

    mds::Tree * m_tree;
    std::string m_target_name;

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

    void StartConnection();

private:
    std::vector<Thread *> m_threads;
};





#endif // TESTCONNECTION_H

