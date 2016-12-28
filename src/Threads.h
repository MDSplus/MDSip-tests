#ifndef TREADS_H
#define TREADS_H

#include <stdlib.h>
#include <signal.h>
#include <pthread.h>
#include <mdsobjects.h>

#include "ClassUtils.h"


namespace mds = MDSplus;

namespace mdsip_test {
  


////////////////////////////////////////////////////////////////////////////////
// THREAD BASE  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class Thread
{
    typedef void (* SigActionHandlerT)(int sig, siginfo_t *si, void *args);
public:
    Thread() {}
    virtual ~Thread() {}

    virtual bool StartThread() {
        return (pthread_create(&_thread, NULL, InternalThreadEntryFunc, this) == 0);
    }

    virtual void StopThread() {
        pthread_cancel(_thread);
    }

    virtual void WaitForThreadToExit() {
        (void) pthread_join(_thread, NULL);
    }

    int SetSigAction(int sig, SigActionHandlerT handler) {
        sa.sa_flags = SA_SIGINFO;
        sigemptyset(&sa.sa_mask);
        sa.sa_sigaction = handler;
        if (sigaction(sig, &sa, NULL) == -1) {
            std::cerr << "Error setting sig handler in thread\n";
            return 0;
        }
        return 1;
    }

    void SendSignal(int sig) const { pthread_kill(_thread, sig); }
    static void SendSignal(Thread &th, int sig) { pthread_kill(th, sig); }

    operator pthread_t() {
        return _thread;
    }

protected:
    virtual void InternalThreadEntry() = 0;
    virtual void InternalThreadExit() {}

private:       

    static void * InternalThreadEntryFunc(void * This) {
        pthread_cleanup_push(InternalThreadExitFunc, This);
        ((Thread *)This)->InternalThreadEntry();
        pthread_cleanup_pop(1);
        return NULL;
    }

    static void InternalThreadExitFunc(void * This) {
        ((Thread *)This)->InternalThreadExit();
    }

    struct sigaction sa;
    pthread_t _thread;
};




////////////////////////////////////////////////////////////////////////////////
//  Lockable  //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define MDS_LOCK_SCOPE(mutex) MDSplus::AutoLock al(mutex); (void)al



class Lockable
{
public:
    Lockable() : m_mutex(new mds::Mutex) {}

    ~Lockable() {/* delete m_mutex; */}

    Lockable(const Lockable &) : m_mutex(new mds::Mutex) {}
    Lockable & operator = (const Lockable &) {}
    const Lockable & operator = (const Lockable &) const {}

    void lock() const { m_mutex->lock(); }

    void unlock() const { m_mutex->unlock(); }

    mds::Mutex & mutex() const { return *m_mutex; }

    operator mds::Mutex &() const { return *m_mutex; }

private:
    // TODO: move to shared pointer
    unique_ptr<mds::Mutex> m_mutex;
};


class WaitSubscriptions : public Lockable {
public:

    WaitSubscriptions(const size_t subscriptor_to_wait = 0, size_t timeout_msec = 0) :
        m_subscriptors(subscriptor_to_wait),
        m_count(0),
        m_timeout_msec(timeout_msec)
    { }

    WaitSubscriptions(const WaitSubscriptions &o) : Lockable(o) {}

    ~WaitSubscriptions() { }

    bool Subscribe() {
        if(!m_subscriptors) return false;
        {
            MDS_LOCK_SCOPE(*this);
            m_count += 1;
            if(m_count >= m_subscriptors) {
                ClearCount();
                m_condition.notify();
                return true;
            }
        }
        if(m_timeout_msec > 0)
            return m_condition.waitTimeout(m_timeout_msec);
        else
            m_condition.wait();
        return true;
    }

    void ClearCount() { m_count = 0; }

private:
    size_t  m_subscriptors;
    size_t  m_count;
    size_t  m_timeout_msec;
    mds::ConditionVar m_condition;
};


} // mdsip_test

#endif // TREADS_H

