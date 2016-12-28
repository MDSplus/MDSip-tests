
#include <unistd.h>
#include <ctime>
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
  
static void count_down(int sec, const char *msg=0) {
    if(msg)
        std::cerr << msg;
    else
        std::cerr << "Exception caught: ";
    std::cerr << std::endl;
    for(int i=sec; i-->0;) {
        std::cerr << " retrying in " << i+1 << " sec \r";
        sleep(1);
    }
}

////////////////////////////////////////////////////////////////////////////////
// SIGLE CHANNEL DC CONNECTION /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


TestConnection::TestConnection(const TestTree &tree) :
    m_tree(tree),
    m_increment_pulse(false)
{
    while(1) {
        try{ m_tree.Create(); break; }
        catch (MDSplus::MdsException &e) {
            std::cerr << "Error creating Tree: " << e.what() << "\n";
            count_down(5);
        }
    }
}

TestConnection::TestConnection(const char *name, const char *path) :
    m_tree(name,path),
    m_increment_pulse(false)
{
    while(1) {
        try{ m_tree.Create(); break; }
        catch (MDSplus::MdsException &e) {
            std::cerr << "Error creating Tree: " << e.what() << "\n";
            count_down(5);
        }
    }
}


double TestConnection::StartConnection()
{
    static int pulse = 1;
    
    m_tree.CreatePulse(pulse);
    m_tree.SetCurrentPulse(pulse);
    foreach(Channel *ch, m_channels) ch->Reset();
    
    // DO NOTHING //

    if(m_increment_pulse) ++pulse;
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

void TestConnection::PrintChannelTimes_Curve(std::ostream &o)
{

}

void TestConnection::SetSaveEachConnection(bool state) {
    m_increment_pulse = state;
}







////////////////////////////////////////////////////////////////////////////////
// CONNECTION THREAD  //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class ConnectionThread : public Thread {

public:
    ConnectionThread(TestConnectionMT *con, Channel *chn, Content *cnt) :
        m_connection(con),
        m_channel(chn),
        m_content(cnt),
        m_integrity(true)
    {}

    void InternalThreadEntry() {
        Timer t, w = m_connection->GetTimer();
        TestConnection::TimeHistogram &time = m_connection->ChannelTime(m_channel);
        TestConnection::TimeHistogram &speed = m_connection->ChannelSpeed(m_channel);
        Curve2D & time_curve  = m_connection->ChannelTime_Curve(m_channel);
        Curve2D & speed_curve = m_connection->ChannelSpeed_Curve(m_channel);
        time.Clear();
        speed.Clear();
        double t1 = 0,t2 = 0;
        int seg_sent = 0;
        timespec ts1,ts2;
        try {
            m_integrity = true;
            m_channel->Open(m_connection->Tree());
            // timer should start here when waiting for a thread broadcast //
            m_integrity = m_connection->GetSubscriptions().Subscribe();
            w.Start(); t.Start();

            if( m_content ) {
                m_content->SetMode(Content::UnconsumingSource);
                //   while (  m_content->GetSize() > 0 )
                while( m_connection->m_active_threads > 0 )
                {
                    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &ts1); // POSIX
                    Content::Element el;
                    m_content->GetNextElement(m_channel->Size(), el);
                    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &ts2); // POSIX
                    m_channel->PutSegment(el);
                    double posix_diff = (1E3*ts2.tv_sec + 1E-6*ts2.tv_nsec)
                            - (1E3*ts1.tv_sec + 1E-6*ts1.tv_nsec);
                    t2 = t.StopWatch_ms() - posix_diff;
                    t1 = w.StopWatch();
                    time_curve.AddPoint( Point2D(t1, 1, 0) );
                    // reject all packets that have different size from expected ..
                    if( el.data->getSize()*sizeof(float)/1024 == m_channel->Size() ) {
                        time << (t2*1E-3);
                        speed << static_cast<double>(m_channel->Size())/1024/(t2*1E-3); // sped in MB //
                        speed_curve.AddPoint( Point2D(t1,static_cast<double>(m_channel->Size())/1024/(t2*1E-3),0));
                    }

                    if(seg_sent >= 0) seg_sent += m_channel->Size();
                    if(seg_sent >= m_content->GetSize()) {
                        m_connection->NotifyCompletedThread();
                        seg_sent = -1;
                    }

                    t.Start();
                } // end while //
                std::cout << "fin\n";
                // m_channel->Close();
            }
        }
        catch (std::exception &e) {
            m_integrity = false;
            error = e;
        }
    }
    

    void InternalThreadExit() {
        try {
            std::cout << "Closing channel Connection\n";
            m_channel->Close();
        }
        catch (std::exception &e) {
            m_integrity = false;
            error = e;
        }
    }


    bool HasErrors() const { return m_integrity == false; }
    const std::exception &Error() const { return error; }
private:
    TestConnectionMT * m_connection;
    Channel *m_channel;
    Content *m_content;
    bool     m_integrity;
    std::exception error;
};









////////////////////////////////////////////////////////////////////////////////
// MULTITHREADED CONNECTION  ///////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


void TestConnectionMT::AddChannel(Content *cnt, Channel *ch)
{
    BaseClass::AddChannel(cnt,ch);
    ConnectionThread *th = new ConnectionThread(this,ch,cnt);
    this->m_active_threads++;
    this->m_threads.push_back(th);
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

    //    Timer conn_timer;
    m_conn_timer.Start();

    for(size_t i=0; i<m_threads.size(); ++i) {
        Thread * thread = m_threads.at(i);
        thread->StartThread();
    }

    for(size_t i=0; i<m_threads.size(); ++i) {
        Thread * thread = m_threads.at(i);
        thread->WaitForThreadToExit();
    }

    // Get total connection time
    // WARNING, this is accountinng the Open/Close ops too.
    double time = m_conn_timer.StopWatch();

    foreach (const Thread *t, m_threads) {
        const ConnectionThread *ct = static_cast<const ConnectionThread *>(t);
        if(ct->HasErrors()) throw (ct->Error());
    }
    
    return time;
}


///
/// \brief TestConnectionMT::NotifyCompletedThread In a non consuming source
/// configuration, when a Thread completes this is used to notify all the
/// others ...
///
void TestConnectionMT::NotifyCompletedThread()
{
    MDS_LOCK_SCOPE(*this);
    if(m_active_threads>0) --m_active_threads;
    std::cout << "->" << m_active_threads << "\n";
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
                    // std::cout << "." << std::flush;
                    time  << t;
                    // speed << static_cast<double>(channel->Size())/1024/t; // speed in MB //
                    speed << static_cast<double>(el.data->getSize()/1024)/1024/t; // speed in MB //                 
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




