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
    Channel() : m_content(NULL) {}
    Channel(Content *cnt) : m_content(cnt) {}

    static Channel * NewDC(Content &cnt, int size_KB);
    static Channel * NewTC(Content &cnt, int size_KB, const char *addr = "localhost");

    virtual void Open(const char *tree) = 0;
    virtual void Close() = 0;

    virtual void SetContent(Content *cnt) { m_content = cnt; }
    virtual Content * GetContent() const { return m_content; }
    virtual size_t Size() const = 0;

    virtual void PutSegment(Content::Element &el) /*const*/ = 0;
protected:
    virtual ~Channel() {}

    Content *m_content;
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


    void AddChannel(Channel *ch);

    void ClearChannels();

    void StartConnection();

private:
    std::vector<Thread *> m_threads;
};





#endif // TESTCONNECTION_H

