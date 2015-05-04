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


namespace mdsip_test {
  


////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Channel {

public:
    virtual ~Channel() {}

    static Channel * NewDC(int size_KB);
    static Channel * NewTC(int size_KB);

    virtual void Open(TestTree &tree) = 0;

    virtual void Close() = 0;

    virtual size_t Size() const = 0;

    virtual void PutSegment(Content::Element &el) /*const*/ = 0;
protected:
    Channel() {}
};



////////////////////////////////////////////////////////////////////////////////
//  TestConnection Base   //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class TestConnection {
public:

    typedef Histogram<double> TimeHistogram;

    TestConnection( const TestTree &tree) :
        m_tree(tree)
    { m_tree.Create(); }

    TestConnection( const char *name, const char *path = 0 ) :
        m_tree(name,path)
    { m_tree.Create(); }

    ~TestConnection() { this->ClearChannels(); }

    virtual double StartConnection();

    virtual void AddChannel(Content *cnt, Channel *chn) {
        m_channels.push_back(chn);
        m_contents.push_back(cnt);
        m_chtimes[chn] =  TimeHistogram(cnt->GetName().c_str(),100,0,5);
        m_chspeed[chn] =  TimeHistogram(cnt->GetName().c_str(),100,0,2);

        m_tree.AddNode(cnt->GetName().c_str(),(char *)"SIGNAL");
    }

    virtual void ClearChannels() {
        m_channels.clear();
        m_chtimes.clear();
        m_chspeed.clear();
    }

    std::string GetTreeName() const { return m_tree.Name(); }

    TestTree & Tree() { return m_tree; }
    const TestTree & Tree() const { return m_tree; }

    TimeHistogram & ChannelTime(Channel *ch) { return m_chtimes[ch]; }

    TimeHistogram & ChannelSpeed(Channel *ch) { return m_chspeed[ch]; }

    void ResetTimes();

    double GetTotalTime();

    double GetWorstChannelTime();

    double GetMeanChannelTime();

    void PrintChannelTimes(std::ostream &o);


protected:
    TestTree m_tree;

    std::vector<Channel *> m_channels;
    std::vector<Content *> m_contents;
    std::map< Channel *, TimeHistogram > m_chtimes;
    std::map< Channel *, TimeHistogram > m_chspeed;
};








////////////////////////////////////////////////////////////////////////////////
//  Connection Multi Threaded  /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class Thread; // fwd //

class TestConnectionMT : public TestConnection, Lockable {

    typedef TestConnection BaseClass;

    friend class ChannelThread;

public:

    TestConnectionMT( const TestTree &tree) : BaseClass(tree) {}

    explicit TestConnectionMT(const char *name, const char *path = 0) :
        TestConnection(name,path)
    {}

    ~TestConnectionMT()
    {        
        this->ClearChannels();
    }


    void AddChannel(Content *cnt, Channel *ch);

    void ClearChannels();

    double StartConnection();

private:
    std::vector<Thread *> m_threads;
};





////////////////////////////////////////////////////////////////////////////////
//  TestConnectionMP  //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class TestConnectionMP : public TestConnection
{
    typedef TestConnection BaseClass;

public:

    TestConnectionMP(const TestTree &tree) : BaseClass(tree) {}

    TestConnectionMP(const char *name, const char *path = 0) : TestConnection(name,path) {}

    void AddChannel(Content *cnt, Channel *ch);

    void ClearChannels();

    double StartConnection();

private:
    std::vector<pid_t> m_pids;
};




} // mdsip_test

#endif // TESTCONNECTION_H

