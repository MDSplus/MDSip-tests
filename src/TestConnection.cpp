
#include <unistd.h>
#include <sys/ipc.h>
#include <sys/wait.h>

#include <sys/mman.h>
#include <sys/shm.h>

#include <mdsobjects.h>

#include "SerializeUtils.h"
#include "DataUtils.h"
#include "Threads.h"
#include "TestConnection.h"

using namespace MDSplus;

namespace mdsip_test {
  


////////////////////////////////////////////////////////////////////////////////
// SIGLE CHANNEL DC CONNECTION /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


double TestConnection::StartConnection()
{
    static int pulse = 0;
    m_tree.CreatePulse(++pulse);
    m_tree.SetCurrentPulse(pulse);

    // DO NOTHING //

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
        time += m_chtimes[ch].Sum();
    }
    return time;
}

double TestConnection::GetWorstChannelTime()
{
    double time = 0;
    for(unsigned int i=0; i< m_channels.size(); ++i)
    {
        Channel *ch = m_channels[i];
        time = std::max(time, m_chtimes[ch].Sum());
    }
    return time;
}

double TestConnection::GetMeanChannelTime()
{
    return GetTotalTime() / m_chtimes.size();
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

    void Open(TestTree &tree) {
        Close();
        m_tree = tree.Open();
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
    ChannelTC(int size) :
        m_cnx(0),
        m_size(size)
    {}

    ~ChannelTC() {
        // Close();
    }

    void Open(TestTree &tree) {
        if(m_cnx) Close();       
        std::string cnx_path = TestTree::TreePath::toString(tree.Path());
        m_cnx = new mds::Connection((char *)cnx_path.c_str());
        m_cnx->openTree((char*)tree.Name().c_str(), 0);
    }

    void Close() {
        if(m_cnx) {
            m_cnx->closeAllTrees();
            delete m_cnx;
            m_cnx = NULL;
        }
    }

//    void PutSegment(Content::Element &el) /*const*/ {
//        Data * args[6];
//        args[0] = new String(el.path.c_str());
//        args[1] = el.dim->getBegin();
//        args[2] = el.dim->getEnding();
//        //        args[3] = el.dim->data();
//        args[3] = el.dim->getDeltaVal();
//        args[4] = el.data;
//        args[5] = new Int32(el.data->getSize());        
        
//        // TDI: public fun MakeSegment(as_is _node, in _start, in _end, as_is _dim, in _array, optional _idx, in _rows_filled)
//        m_cnx->get("MakeSegment($1,$2,$3,make_range($2,$3,$4),$5,,$6)",args,6);
//        // TDI: public fun MakeSegmentRange(as_is _node, in _start, in _end, in _delta, in _array, optional _idx, in _rows_filled)
//        //        m_cnx.get("MakeSegmentRange($1,$2,$3,$4,$5,,$6)",args,6);

//        deleteData(args[0]);
//        deleteData(args[5]);
//    }
    void PutSegment(Content::Element &el) /*const*/ {

      Data * args[1];
      args[0] = el.data;
      
      char * begin = el.dim->getBegin()->getString();
      char * end = el.dim->getEnding()->getString();
      char * delta = el.dim->getDeltaVal()->getString();
      
      std::stringstream ss;
      ss << "MakeSegment(" 
         << el.path << "," 
         << begin << ","
         << end << ","
         << "make_range(" << begin << "," << end << "," << delta << ")" << ",,"
         << "$1" << ","
         << el.data->getSize() << ")";
            
      // TDI: public fun MakeSegment(as_is _node, in _start, in _end, as_is _dim, in _array, optional _idx, in _rows_filled)
      m_cnx->get(ss.str().c_str(),args,1);

      delete[] begin;
      delete[] end;
      delete[] delta;
    }

    size_t Size() const { return m_size; }

private:
    mds::Connection *m_cnx;
    size_t m_size;
};


Channel *Channel::NewDC(int size_KB)
{
    return new ChannelDC(size_KB);
}

Channel *Channel::NewTC(int size_KB)
{
    return new ChannelTC(size_KB);
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
        TestConnection::TimeHistogram &time = m_connection->ChannelTime(m_channel);
        TestConnection::TimeHistogram &speed = m_connection->ChannelSpeed(m_channel);
        time.Clear();
        speed.Clear();

        m_channel->Open(m_connection->Tree());

        if( m_content )
        while (  m_content->GetSize() > 0 )
        {
            Content::Element el;
            m_content->GetNextElement(m_channel->Size(), el);
            timer.Start();
            m_channel->PutSegment(el);
            double t = timer.StopWatch();
            time << t;
            speed << static_cast<double>(m_channel->Size())/1024/t; // speed in MB //
            // FIX: the actual size of el may not be of this size //
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


void TestConnectionMT::AddChannel(Content *cnt, Channel *ch)
{
    BaseClass::AddChannel(cnt,ch);
    this->m_threads.push_back(new ConnectionThread(this,ch,cnt));
}


void TestConnectionMT::ClearChannels()
{    
    for(size_t i=0; i<m_threads.size(); ++i) {
        delete m_threads[i];
    }
    m_threads.clear();
    BaseClass::ClearChannels();
}

///
/// \brief TestConnectionMT::StartConnection
/// \return the total time of connection (comprise of open channel time)
///
/// Main Test Connection MT routine
///
double TestConnectionMT::StartConnection()
{
    BaseClass::StartConnection();

    std::cout << "START MULTITHREADED CONNECTION\n";

    Timer conn_timer;
    conn_timer.Start();

    for(size_t i=0; i<m_threads.size(); ++i) {
        Thread * thread = m_threads.at(i);
        thread->StartThread();
    }

    for(size_t i=0; i<m_threads.size(); ++i) {
        Thread * thread = m_threads.at(i);
        thread->WaitForThreadToExit();
    }

    //    pulse++;
    return conn_timer.StopWatch();
}











////////////////////////////////////////////////////////////////////////////////
//  MUTIPROCESS CONNECTION  ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void TestConnectionMP::AddChannel(Content *cnt, Channel *ch)
{
    this->m_pids.push_back(-1);
    BaseClass::AddChannel(cnt,ch);
}


void TestConnectionMP::ClearChannels()
{
    this->m_pids.clear();
    BaseClass::ClearChannels();
}



// GLOBAL SHARED TIMINGS //
SerializeToShm g_shm_timings[20];

///
/// \brief TestConnectionMP::StartConnection
/// \return the total time of connection (comprise of open channel time)
///
/// Main Test Connection MP routine
///
double TestConnectionMP::StartConnection()
{
    BaseClass::StartConnection();

    std::cout << "START MULTIPROCESS CONNECTION\n";

    // TOTAL CONNECTION TIMER //
    Timer conn_timer; conn_timer.Start();

//    if(m_pids.size() == 1)
//    {

//        // FIX: use BaseClass for single channel //

//        Channel *channel = this->m_channels[0];
//        Content *content = this->m_contents[0];

//        Timer timer;

//        TimeHistogram &time = this->ChannelTime(channel);
//        TimeHistogram &speed = this->ChannelSpeed(channel);

//        channel->Open(this->Tree());

//        while (  content->GetSize() > 0 )
//        {
//            Content::Element el;
//            content->GetNextElement(channel->Size(), el);
//            timer.Start();
//            channel->PutSegment(el);
//            double t = timer.StopWatch();
//            std::cout << "." << std::flush;
//            time << t;
//            speed << static_cast<double>(channel->Size())/1024/t; // speed in MB //
//            // FIX: the actual size of el may not be of this size //
//        }

//        std::cout << "\n";

//        channel->Close();
//    }
//    else
    {
        // SHARED MEMORY TIMINGS SERIALIZATION //
        for(unsigned int i = 0; i < m_pids.size(); ++i) {
            Channel *channel = this->m_channels[i];
            TimeHistogram &time = this->ChannelTime(channel);
            TimeHistogram &speed = this->ChannelSpeed(channel);
            SerializeToShm &shm = g_shm_timings[i];
            shm.Write() & time & speed;
            shm.Store();
        }

        for(unsigned int i = 0; i < m_pids.size(); ++i)
        {

            if( (m_pids[i] = fork()) == 0 )
            {
                if(i >= m_channels.size() || i >= m_contents.size()) exit(0);

                Channel *channel = this->m_channels[i];
                Content *content = this->m_contents[i];
                Timer timer;

                TimeHistogram &time = this->ChannelTime(channel);
                TimeHistogram &speed = this->ChannelSpeed(channel);
                SerializeToShm &shm = g_shm_timings[i];
                time.Clear();
                speed.Clear();



                channel->Open(this->Tree());

                while (  content->GetSize() > 0 )
                {
                    Content::Element el;
                    content->GetNextElement(channel->Size(), el);
                    timer.Start();
                    channel->PutSegment(el);
                    double t = timer.StopWatch();
                    std::cout << "." << std::flush;
                    time  << t;
                    speed << static_cast<double>(channel->Size())/1024/t; // speed in MB //
                    // FIX: the actual size of el may not be of this size //
                }

                std::cout << "\n";

                shm.Clear();
                shm.Write() & time & speed;
                shm.Store();

                channel->Close();
                exit(0);
            }
        }
        for(unsigned int i = 0; i < m_pids.size(); ++i)
            waitpid(m_pids[i], NULL, 0);

        for(unsigned int i = 0; i < m_pids.size(); ++i) {
            Channel *channel = this->m_channels[i];
            TimeHistogram &time = this->ChannelTime(channel);
            TimeHistogram &speed = this->ChannelSpeed(channel);
            SerializeToShm &shm = g_shm_timings[i];
            shm.Resume();
            shm.Read() & time & speed;
            shm.Clear();
        }

    } // END MULTIPLE PIDS //

    return conn_timer.StopWatch();
}



} // mdsip_test




