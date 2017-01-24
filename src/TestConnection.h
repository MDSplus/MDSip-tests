#ifndef TESTCONNECTION_H
#define TESTCONNECTION_H

#include <assert.h>
#include <sys/time.h>
#include <vector>
#include <map>

#include <mdsobjects.h>

#include "TreeUtils.h"
#include "DataUtils.h"
#include "Threads.h"

#include "TestContent.h"
#include "TestChannel.h"

namespace mdsip_test {
  


////////////////////////////////////////////////////////////////////////////////
//  TestConnection Base   //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class TestConnection {
public:

    typedef Histogram<double> TimeHistogram;

    TestConnection( const TestTree &tree);

    TestConnection( const char *name, const char *path = 0 );

    ~TestConnection() { this->ClearChannels(); }

    virtual double StartConnection();

    virtual void AddChannel(Content *cnt, Channel *chn) {
        //chn->SetContent(cnt); // NEW CONTENT IN CHANNEL //
        
        m_channels.push_back(chn);
        m_contents.push_back(cnt);        
        m_chtimes[chn] =  TimeHistogram(cnt->GetName().c_str(),100,0,5);
        m_chspeed[chn] =  TimeHistogram(cnt->GetName().c_str(),100,0,2);
        m_chtimes_curve[chn] =  Curve2D(cnt->GetName().c_str());
        m_chspeed_curve[chn] =  Curve2D(cnt->GetName().c_str());

        m_tree.OpenEdit();
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

    Curve2D & ChannelTime_Curve(Channel *ch) { return m_chtimes_curve[ch]; }
    Curve2D & ChannelSpeed_Curve(Channel *ch) { return m_chspeed_curve[ch]; }

    void ResetTimes();

    double GetTotalTime();

    double GetWorstChannelTime();

    double GetMeanChannelTime();

    void PrintChannelTimes(std::ostream &o);
    void PrintChannelTimes_Curve(std::ostream &o);

    void SetSaveEachConnection(bool state);

protected:
    bool     m_increment_pulse;
    TestTree m_tree;

    std::vector<Channel *> m_channels;
    std::vector<Content *> m_contents;
    std::map< Channel *, TimeHistogram > m_chtimes;
    std::map< Channel *, TimeHistogram > m_chspeed;
    std::map< Channel *, Curve2D > m_chtimes_curve;
    std::map< Channel *, Curve2D > m_chspeed_curve;
};








////////////////////////////////////////////////////////////////////////////////
//  Connection Multi Threaded  /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


//class Thread; // fwd //
//class WaitSubscriptions;

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

    const Timer & GetTimer() { return m_conn_timer; }

    void SetSubscriptions(size_t n_th, int msec) {
        m_wait_threads = WaitSubscriptions(n_th,msec);
    }

    WaitSubscriptions & GetSubscriptions() { return m_wait_threads; }


private:
    WaitSubscriptions     m_wait_threads;
    std::vector<Thread *> m_threads;
    Timer m_conn_timer;
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

