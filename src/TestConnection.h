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

    //    typedef Histogram<double> TimeHistogram;

public:
    virtual ~Channel() {}

    static Channel * NewDC(int size_KB);
    static Channel * NewTC(int size_KB, const char *addr = "localhost");

    virtual void Open(const char *tree) = 0;
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

    TestConnection( const char *connection_string )
    {
        m_tname = TestTree::GetTreeName( std::string(connection_string) );
        m_tree  = TestTree::CreateTree(m_tname.name.c_str());
        m_tree->write();
    }

    ~TestConnection() { this->ClearChannels(); }

    virtual double StartConnection();

    virtual void AddChannel(Content *cnt, Channel *chn) {
        m_channels.push_back(chn);
        m_contents.push_back(cnt);
        m_chtimes[chn] =  TimeHistogram(cnt->GetName().c_str(),50,0,5);
        m_chspeed[chn] =  TimeHistogram(cnt->GetName().c_str(),50,0,5);

        this->m_tree->addNode(cnt->GetName().c_str(),(char *)"SIGNAL"); // FIX
        m_tree->write();        
    }

    virtual void ClearChannels() {
        m_channels.clear();
        m_chtimes.clear();
        m_chspeed.clear();
    }

    mds::Tree * GetTree() const { return m_tree; }

    std::string GetTreeName() { return m_tname.name; }

    TimeHistogram & ChannelTime(Channel *ch) { return m_chtimes[ch]; }

    TimeHistogram & ChannelSpeed(Channel *ch) { return m_chspeed[ch]; }

    void ResetTimes();

    double GetTotalTime();

    double GetWorstChannelTime();

    double GetMeanChannelTime();

    void PrintChannelTimes(std::ostream &o);


protected:

    mds::Tree * m_tree;
    TestTree::TreeName m_tname;

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

    explicit TestConnectionMT(const char *name) :
        TestConnection(name)
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
    typedef TestConnection BaseCLass;

public:
    TestConnectionMP(const char *name) : TestConnection(name) {}

    void AddChannel(Content *cnt, Channel *ch);

    void ClearChannels();

    double StartConnection();

private:
    std::vector<pid_t> m_pids;
};






#endif // TESTCONNECTION_H

