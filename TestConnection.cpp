#include "TestConnection.h"
#include <mdsobjects.h>

using namespace MDSplus;


////////////////////////////////////////////////////////////////////////////////
// SIGLE CHANNEL DC CONNECTION /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void TestConnection::StartConnection()
{
    static int pulse = 1;
    size_t connection_size = m_connection_size;

    // create pulse //
    m_tree = TreeUtils::OpenTree(m_target_name.c_str(),-1);
    m_tree->createPulse(pulse);
    delete m_tree;

    // open pulse //
    m_tree = TreeUtils::OpenTree(m_target_name.c_str(),pulse);

    struct timeval startTime, endTime;
    gettimeofday(&startTime, NULL);

    int seg_id = 0;
    while(connection_size > 0) {
        int size = std::min(connection_size, m_segment_size);
        connection_size -= size;

        Content * cnt = m_contents.at( seg_id++ % m_contents.size() );
        Content::Element el = cnt->GetNextElement(size);
        mds::TreeNode *node = m_tree->getNode(el.path.c_str());
        node->makeSegment(el.dim->getBegin(), el.dim->getEnding(), el.dim, el.data);
    }

    gettimeofday(&endTime, NULL);
    double timeSec = endTime.tv_sec - startTime.tv_sec +
            (endTime.tv_usec - startTime.tv_usec)*1E-6;

    std::cout << "elapsed time: " << timeSec << "\n";

    if(m_tree) delete m_tree;
    pulse++;
}



////////////////////////////////////////////////////////////////////////////////
// THREAD BASE  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class Thread
{
public:
   Thread() {}
   virtual ~Thread() {}

   bool StartThread() {
      return (pthread_create(&_thread, NULL, InternalThreadEntryFunc, this) == 0);
   }

   void WaitForThreadToExit() {
      (void) pthread_join(_thread, NULL);
   }

protected:
   virtual void InternalThreadEntry() = 0;

private:
   static void * InternalThreadEntryFunc(void * This) {
       ((Thread *)This)->InternalThreadEntry();
       return NULL;
   }

   pthread_t _thread;
};



////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class ChannelDC : public Channel {
public:
    ChannelDC(int size) :
        m_tree(NULL),
        m_size(size)
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

    void PutSegment(Content *cnt) /*const*/ {
        Content::Element el;
        el = cnt->GetNextElement(m_size);
        //        std::cout << "D" << std::flush;
        TreeNode *node = m_tree->getNode(el.path.c_str());
        node->makeSegment(el.dim->getBegin(), el.dim->getEnding(), el.dim, el.data);
    }

    size_t Size() const { return m_size; }

private:
    Tree  *m_tree;
    size_t m_size;
};



class ChannelTC : public Channel {
public:
    ChannelTC(int size, const char *addr) :
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

    void PutSegment(Content *cnt) /*const*/ {
        Content::Element el;
        el = cnt->GetNextElement(m_size);
        //        std::cout << "T" << std::flush;

        Data * args[6];
        args[0] = new String(el.path.c_str());
        args[1] = el.dim->getBegin();
        args[2] = el.dim->getEnding();
        args[3] = el.dim->data();
        args[4] = el.data;
        args[5] = new Int32(el.data->getSize());

        // TDI: public fun MakeSegment(as_is _node, in _start, in _end, as_is _dim, in _array, optional _idx, in _rows_filled)
        m_cnx.get("MakeSegment($1,$2,$3,$4,$5,,$6)",args,6);

    }

    size_t Size() const { return m_size; }

private:
    Connection m_cnx;
    std::string m_tree_name;
    std::string m_addr;
    size_t m_size;
};


Channel *Channel::NewDC(int size_KB)
{
    return new ChannelDC(size_KB);
}

Channel *Channel::NewTC(int size_KB, const char *addr)
{
    return new ChannelTC(size_KB,addr);
}





////////////////////////////////////////////////////////////////////////////////
// THREAD CHANNEL //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class ChannelThread : public Thread {

public:
    ChannelThread(ConnectionMT *con, Channel *chn) :
        m_connection(con),
        m_channel(chn)
    {}

    void InternalThreadEntry() {
        m_channel->Open(m_connection->GetTreeName().c_str());

        while ( Content * cnt = m_connection->RequestChannel(m_channel->Size()) )
        {
            m_channel->PutSegment(cnt);
            m_connection->ReleaseChannel(cnt);
        }

        m_channel->Close();
    }

private:
    ConnectionMT * m_connection;
    Channel * m_channel;
};




////////////////////////////////////////////////////////////////////////////////
// CONNECTION MULTI THREADED ///////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void ConnectionMT::AddChannel(Channel *ch)
{
    this->m_threads.push_back(new ChannelThread(this,ch));
    this->m_content_lock.push_back(0);
}


void ConnectionMT::ClearChannels()
{
    for(size_t i=0; i<m_threads.size(); ++i) {
        delete m_threads[i];
    }
    m_threads.clear();
    m_content_lock.clear();
}


void ConnectionMT::StartConnection()
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

    m_size_consumed = m_connection_size;

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


Content* ConnectionMT::RequestChannel(unsigned int size)
{
    Content * cnt = NULL;
    int seg_size = 0;
    {
        AutoLock al(mutex); (void)al;
        seg_size = std::min(m_size_consumed, size);
        m_size_consumed -= seg_size;
        if(seg_size <= 0) return NULL;

        int seg_id;
        do seg_id = rand() % m_contents.size();
        while(m_content_lock[seg_id] == 1);
        cnt = m_contents.at( seg_id );
        m_content_lock[seg_id] = 1;
    } // atomic
    return cnt;
}

void ConnectionMT::ReleaseChannel(Content *cnt)
{
    for (unsigned int i=0; i<m_contents.size(); ++i) {
        if(m_contents[i] == cnt)
            m_content_lock[i] = 0;
    }
}






