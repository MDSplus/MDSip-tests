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
        m_target_name(name),
        m_connection_size(100),
        m_segment_size(100)
    {
        m_tree = TreeUtils::CreateTree(m_target_name.c_str());
        m_tree->write();
    }

    void AddContent(Content *content) {
        m_tree->edit();
        m_contents.push_back(content);
        m_tree->addNode(content->GetName().c_str(),(char *)"SIGNAL");
        m_tree->write();
    }

    virtual void StartConnection();

    virtual void SetSegmentSize(unsigned int size) { m_segment_size = size; }

    const size_t & SegmentSize() const { return m_segment_size; }

    virtual void SetConnectionSize(unsigned int size) { m_connection_size = size*1024; }

    const size_t & ConnectionSize() const { return m_connection_size; }

    virtual std::string GetTreeName() { return m_target_name; }

protected:

    mds::Tree * m_tree;
    std::string m_target_name;

    std::vector<Content *> m_contents;

    size_t m_connection_size; // in KB
    size_t m_segment_size;
};



////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Channel
{
public:
    static Channel * NewDC(int size_KB);
    static Channel * NewTC(int size_KB, const char *addr = "localhost");

    virtual void Open(const char *tree) = 0;
    virtual void Close() = 0;
    virtual void PutSegment(Content *cnt) /*const*/ = 0;
    virtual size_t Size() const = 0;
};


////////////////////////////////////////////////////////////////////////////////
//  Thread  ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Thread; // fwd //


////////////////////////////////////////////////////////////////////////////////
//  Connection Multi Threaded  /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class ConnectionMT : public TestConnection {

    friend class ChannelThread;

public:

    ConnectionMT(std::string name) :
        TestConnection(name)
    {}

    ~ConnectionMT()
    {
        mutex.lock(); // bug di Mutex
        ClearChannels();
    }


    void AddChannel(Channel *ch);

    void ClearChannels();

    void StartConnection();

    mds::Tree * GetTree() const { return m_tree; }

private:

    Content * RequestChannel(unsigned int size);

    void ReleaseChannel(Content *cnt);

private:
    mds::Mutex mutex;
    std::vector<Thread *> m_threads;
    std::vector<bool> m_content_lock; // fix with something smarter //
    unsigned int m_size_consumed;
};





#endif // TESTCONNECTION_H

