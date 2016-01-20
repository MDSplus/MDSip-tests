
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
                    //                    std::cout << "." << std::flush;
                    time  << t;
                    speed << static_cast<double>(channel->Size())/1024/t; // speed in MB //
                    // FIX: the actual size of el may not be of this size //
                }
                //                std::cout << "\n";

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




