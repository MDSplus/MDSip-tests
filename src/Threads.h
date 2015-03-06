#ifndef TREADS_H
#define TREADS_H

#include <pthread.h>
#include <mdsobjects.h>

namespace mds = MDSplus;

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

   void StopThread() {
       pthread_cancel(_thread);
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
//  Lockable  //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define MDS_LOCK_SCOPE(mutex) MDSplus::AutoLock al(mutex); (void)al

class Lockable
{
public:

    Lockable(const Lockable &) : m_mutex(new mds::Mutex) { }

    Lockable() : m_mutex(new mds::Mutex) {}

    ~Lockable() {
        delete m_mutex;
    }


    void lock() const { m_mutex->lock(); }

    void unlock() const { m_mutex->unlock(); }

    mds::Mutex & mutex() const { return *m_mutex; }

    operator mds::Mutex &() const { return *m_mutex; }

private:
    mds::Mutex *m_mutex;
};







#endif // TREADS_H

