#include <mdsobjects.h>

#include "TestConnection.h"
#include "Threads.h"

using namespace MDSplus;


////////////////////////////////////////////////////////////////////////////////
// SIGLE CHANNEL DC CONNECTION /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void TestConnection::StartConnection()
{
    static int pulse = 1;
    //size_t connection_size = m_connection_size;

    // create pulse //
    m_tree = TreeUtils::OpenTree(m_target_name.c_str(),-1);
    m_tree->createPulse(pulse);
    delete m_tree;

    // open pulse //
    m_tree = TreeUtils::OpenTree(m_target_name.c_str(),pulse);

    if(m_tree) delete m_tree;
    pulse++;
}







////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class ChannelDC : public Channel {
public:
    ChannelDC(Content *cnt, int size) :
        Channel(cnt),
        m_size(size),
        m_tree(NULL)
    {}

    ~ChannelDC() { Close(); }

    void Open(const char *tree) {
        Close();
        m_tree = new Tree(tree,1); // not use 0 cos a race in mdsplus default id
    }

    void Close() {
        if(m_tree) delete m_tree;
        m_tree = NULL;
    }

    void PutSegment(Content::Element &el) /*const*/ {
        TreeNode *node = m_tree->getNode(el.path.c_str());
        node->makeSegment(el.dim->getBegin(), el.dim->getEnding(), el.dim, el.data);
    }

    size_t Size() const { return m_size; }

private:
    size_t m_size;
    Tree  *m_tree;
};



class ChannelTC : public Channel {
public:
    ChannelTC(Content *cnt, int size, const char *addr) :
        Channel(cnt),
        m_cnx((char *)addr),
        m_addr(addr),
        m_size(size)
    {}

    ~ChannelTC() {
        Close();
    }

    void Open(const char *tree) {
        m_cnx.openTree((char*)tree, 1); // not use 0 cos a race in mdsplus default id
    }

    void Close() {
        m_cnx.closeAllTrees();
    }

    void PutSegment(Content::Element &el) /*const*/ {

        Data * args[6];
        args[0] = new String(el.path.c_str());
        args[1] = el.dim->getBegin();
        args[2] = el.dim->getEnding();
        args[3] = el.dim->data();
        args[4] = el.data;
        args[5] = new Int32(el.data->getSize());

        // TDI: public fun MakeSegment(as_is _node, in _start, in _end, as_is _dim, in _array, optional _idx, in _rows_filled)
        m_cnx.get("MakeSegment($1,$2,$3,$4,$5,,$6)",args,6);

        deleteData(args[0]);
        deleteData(args[5]);

    }

    size_t Size() const { return m_size; }

private:
    mds::Connection m_cnx;
    std::string m_tree_name;
    std::string m_addr;
    size_t m_size;
};


Channel *Channel::NewDC(Content &cnt, int size_KB)
{
    return new ChannelDC(&cnt, size_KB);
}

Channel *Channel::NewTC(Content &cnt, int size_KB, const char *addr)
{
    return new ChannelTC(&cnt, size_KB,addr);
}





////////////////////////////////////////////////////////////////////////////////
// CONNECTION THREAD  //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class ConnectionThread : public Thread {

public:
    ConnectionThread(TestConnectionMT *con, Channel *chn) :
        m_connection(con),
        m_channel(chn)
    {}

    void InternalThreadEntry() {
        m_channel->Open(m_connection->GetTreeName().c_str());

        if( Content * cnt = m_channel->GetContent() )
        while (  cnt->GetSize() > 0 )
        {
            Content::Element el;
            cnt->GetNextElement(m_channel->Size(), el);
            m_channel->PutSegment(el);
        }

        m_channel->Close();
    }

private:

    TestConnectionMT * m_connection;
    Channel * m_channel;
};




////////////////////////////////////////////////////////////////////////////////
// MULTITHREADED CONNECTION  ///////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void TestConnectionMT::AddChannel(Channel *ch)
{
    this->m_threads.push_back(new ConnectionThread(this,ch));
    this->m_tree->addNode(ch->GetContent()->GetName().c_str(),(char *)"SIGNAL"); // FIX
    m_tree->write();
}


void TestConnectionMT::ClearChannels()
{
    for(size_t i=0; i<m_threads.size(); ++i) {
        delete m_threads[i];
    }
    m_threads.clear();
}


void TestConnectionMT::StartConnection()
{
    static int pulse = 1;

    // create pulse //
    m_tree = TreeUtils::OpenTree(m_target_name.c_str(),-1);
    m_tree->createPulse(pulse);
    delete m_tree;

    // open pulse //
    m_tree = TreeUtils::OpenTree(m_target_name.c_str(),pulse);
    m_tree->setCurrent(m_target_name.c_str(),pulse);
    delete m_tree;


    struct timeval startTime, endTime;
    gettimeofday(&startTime, NULL);

    for(size_t i=0; i<m_threads.size(); ++i) {
        Thread * thread = m_threads.at(i);
        thread->StartThread();
    }

    for(size_t i=0; i<m_threads.size(); ++i) {
        Thread * thread = m_threads.at(i);
        thread->WaitForThreadToExit();
    }

    gettimeofday(&endTime, NULL);
    double timeSec = endTime.tv_sec - startTime.tv_sec +
            (endTime.tv_usec - startTime.tv_usec)*1E-6;

    std::cout << "elapsed time: " << timeSec << "\n";
}





