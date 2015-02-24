#ifndef PRODUCERCONSUMER_H
#define PRODUCERCONSUMER_H

#include <unistd.h>
#include <queue>
#include <deque>

#include <mdsobjects.h>

#include <Threads.h>

namespace mds = MDSplus;

////////////////////////////////////////////////////////////////////////////////
//  Queue   ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

///
/// FIFO sequence
///
template < typename T >
class Queue : private std::queue<T>
{
    typedef std::queue<T> BaseClass;
public:

    inline size_t Size() const { return this->size(); }

    inline void Push(const T &data) { this->push(data); }

    inline T Pop() { T data = this->front(); this->pop(); return data; }

};




////////////////////////////////////////////////////////////////////////////////
//  Pool    ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


///
/// Thread safe FIFO buffer
///
template < typename T >
class Pool : protected Queue<T>, Lockable {
    typedef Queue<T> Q;
public:
    Pool(const size_t size = 10, const unsigned int spin_time = 60 ) :
        m_size(size),
        m_spin_time(spin_time)
    {}

    ~Pool();

    size_t Size();

    void Push(const T &data);

    T Pop();

private:
    size_t m_size;
    unsigned int m_spin_time;
};



template < typename T >
inline Pool<T>::~Pool()
{
    MDS_LOCK_SCOPE(*this);
    while ( Q::Size() ) {
        Q::Pop();
    }
}


template < typename T >
inline size_t Pool<T>::Size()
{
    MDS_LOCK_SCOPE(*this);
    return Q::Size();
}


template < typename T >
inline void Pool<T>::Push(const T &data)
{
    while( this->Size() >= m_size  ) {
        usleep(m_spin_time); // leaving unlocked pool //
    }
    lock();
    Q::Push(data);
    unlock();
}

template < typename T >
inline T Pool<T>::Pop()
{
    while( this->Size() <= 0  ) {
        usleep(m_spin_time); // leaving unlocked pool //
    }
    lock();
    T data = Q::Pop();
    unlock();
    return data;
}










#endif // PRODUCERCONSUMER_H
