
#include <unistd.h>
#include <sys/ipc.h>

#include <mdsobjects.h>

#include "DataUtils.h"
#include "Threads.h"

#include "TestConnection.h"

using namespace MDSplus;


////////////////////////////////////////////////////////////////////////////////
// SIGLE CHANNEL DC CONNECTION /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


double TestConnection::StartConnection()
{
    static int pulse = 1;

    // create pulse //
    m_tree = TestTree::OpenTree(m_tname.name.c_str(),-1);
    m_tree->createPulse(pulse);
    delete m_tree;

    // open pulse //
    m_tree = TestTree::OpenTree(m_tname.name.c_str(),pulse);

    if(m_tree) delete m_tree;
    pulse++;

    return 0;
}

void TestConnection::ResetTimes()
{
    for(unsigned int i=0; i< m_channels.size(); ++i)
    {
        Channel *ch = m_channels[i];
        m_chtimes[ch].Clear();
    }
}

double TestConnection::GetTotalTime()/* const*/
{
    double time = 0;
    for(unsigned int i=0; i< m_channels.size(); ++i)
    {
        Channel *ch = m_channels[i];
        time += m_chtimes[ch].MeanAll();
    }
    return time;
}

void TestConnection::PrintChannelTimes(std::ostream &o)
{
    static const char c = ';';

    if(!this->m_channels.size()) return;
    Channel *first_ch = m_channels[0];
    TimeHistogram &h0 = m_chtimes[first_ch];
    size_t nbins = h0.BinSize();

    o << "time [s]";
    for (unsigned int i=0; i< m_channels.size(); ++i)
    {
        Channel *ch = m_channels[i];
        TimeHistogram &h = m_chtimes[ch];
        o << c << h.GetName();
    }
    o << "\n";

    for (unsigned int i=0; i< nbins; ++i)
    {
        o << h0.operator [](i).first;
        for (unsigned int j=0; j< m_channels.size(); ++j)
        {
            Channel *ch = m_channels[j];
            TimeHistogram &h = m_chtimes[ch];
            o << c << h[i].second;
        }
        o << "\n";
    }
    o << "\n";
}







////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class ChannelDC : public Channel {
public:
    ChannelDC(int size) :
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
    ChannelTC(int size, const char *addr) :
        m_cnx((char *)addr),
        m_addr(addr),
        m_size(size)
    {}

    ~ChannelTC() {
        // Close();
    }

    void Open(const char *tree) {
        m_cnx.openTree((char*)tree, 0); // not use 0 cos a race in mdsplus default id
    }

    void Close() {
        m_cnx.closeAllTrees();        
    }

    void PutSegment(Content::Element &el) /*const*/ {

        Data * args[6];
        args[0] = new String(el.path.c_str());
        args[1] = el.dim->getBegin();
        args[2] = el.dim->getEnding();
        //        args[3] = el.dim->data();
        args[3] = el.dim->getDeltaVal();
        args[4] = el.data;
        args[5] = new Int32(el.data->getSize());

        // TDI: public fun MakeSegment(as_is _node, in _start, in _end, as_is _dim, in _array, optional _idx, in _rows_filled)
        m_cnx.get("MakeSegment($1,$2,$3,make_range($2,$3,$4),$5,,$6)",args,6);
        // TDI: public fun MakeSegmentRange(as_is _node, in _start, in _end, in _delta, in _array, optional _idx, in _rows_filled)
        //        m_cnx.get("MakeSegmentRange($1,$2,$3,$4,$5,,$6)",args,6);

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


Channel *Channel::NewDC(int size_KB)
{
    return new ChannelDC(size_KB);
}

Channel *Channel::NewTC(int size_KB, const char *addr)
{
    return new ChannelTC(size_KB,addr);
}





////////////////////////////////////////////////////////////////////////////////
// CONNECTION THREAD  //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class ConnectionThread : public Thread {

public:
    ConnectionThread(TestConnectionMT *con, Channel *chn, Content *cnt) :
        m_connection(con),
        m_channel(chn),
        m_content(cnt)
    {}

    void InternalThreadEntry() {
        Timer timer;
        TestConnection::TimeHistogram &hist = m_connection->GetChannelTimes(m_channel);

        m_channel->Open(m_connection->GetTreeName().c_str());

        if( m_content )
        while (  m_content->GetSize() > 0 )
        {
            Content::Element el;
            m_content->GetNextElement(m_channel->Size(), el);
            timer.Start();
            m_channel->PutSegment(el);
            hist << timer.StopWatch();
        }

        m_channel->Close();
    }

private:
    TestConnectionMT * m_connection;
    Channel *m_channel;
    Content *m_content;
};









////////////////////////////////////////////////////////////////////////////////
// MULTITHREADED CONNECTION  ///////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void TestConnectionMT::AddChannel(Content &cnt, Channel *ch)
{
    BaseClass::AddChannel(cnt,ch);
    this->m_threads.push_back(new ConnectionThread(this,ch,&cnt));    
    this->m_tree->addNode(cnt.GetName().c_str(),(char *)"SIGNAL"); // FIX
    m_tree->write();
}


void TestConnectionMT::ClearChannels()
{    
    for(size_t i=0; i<m_threads.size(); ++i) {
        delete m_threads[i];
    }
    m_threads.clear();
    BaseClass::ClearChannels();
}


double TestConnectionMT::StartConnection()
{
    static int pulse = 1;

    // create pulse //
    m_tree = TestTree::OpenTree(m_tname.name.c_str(),-1);
    m_tree->createPulse(pulse);
    delete m_tree;

    // open pulse //
    m_tree = TestTree::OpenTree(m_tname.name.c_str(),pulse);
    m_tree->setCurrent(m_tname.name.c_str(),pulse);
    delete m_tree;


    Timer time;
    time.Start();

    for(size_t i=0; i<m_threads.size(); ++i) {
        Thread * thread = m_threads.at(i);
        thread->StartThread();
    }

    for(size_t i=0; i<m_threads.size(); ++i) {
        Thread * thread = m_threads.at(i);
        thread->WaitForThreadToExit();
    }

    double timeSec = time.StopWatch();
    //std::cout << "Total connection time: " << timeSec << "\n";

    pulse++;
    return timeSec;
}




////////////////////////////////////////////////////////////////////////////////
//  MUTIPROCESS CONNECTION  ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



double TestConnectionMP::StartConnection()
{
    for(unsigned int i = 0; i < m_pids.size(); ++i)
    {
        if( (m_pids[i] = fork()) == 0)
        {
            Timer timer;

//            m_channel->Open(m_connection->GetTreeName().c_str());

//            if( m_content )
//            while (  m_content->GetSize() > 0 )
//            {
//                Content::Element el;
//                m_content->GetNextElement(m_channel->Size(), el);
//                timer.Start();
//                m_channel->PutSegment(el);
//                hist << timer.StopWatch();
//            }

//            m_channel->Close();

            exit(0);
        }
    }
}
