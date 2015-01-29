#ifndef TESTCONNECTION_H
#define TESTCONNECTION_H

#include <assert.h>
#include <sys/time.h>
#include <vector>

#include <mdsobjects.h>

#include "TreeUtils.h"
#include "TestContent.h"


class TestConnection {
public:

    TestConnection( std::string name ) :
        m_target_name(name)
    {
        m_tree = TreeUtils::CreateTree(m_target_name.c_str());
        m_tree->write();
    }

    virtual void StartConnection();

    mds::Tree * GetTree() const { return m_tree; }

    std::string GetTreeName() { return m_target_name; }

protected:

    mds::Tree * m_tree;
    std::string m_target_name;
};



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
//  Connection Multi Threaded  /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class Thread; // fwd //

class TestConnectionMT : public TestConnection, Lockable {

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

