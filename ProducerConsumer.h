#ifndef PRODUCERCONSUMER_H
#define PRODUCERCONSUMER_H

#include <unistd.h>
#include <queue>

#include <mdsobjects.h>

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
    Queue(const size_t size) : BaseClass(size) {}

    inline size_type Size() const { return size(); }

    inline void Push(const T &data) { push(data); }
    inline T Pop() { return pop(); }

    inline T & Front() { return front(); }
    inline const T & Front() const { return front(); }

    inline T & Back() { return back(); }
    inline const T & Back() const { return back(); }
};




////////////////////////////////////////////////////////////////////////////////
//  Pool    ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


///
/// Thread safe FIFO buffer
///
template < typename T >
class Pool : protected Queue<T> {
    typedef Queue<T> Q;
public:
    Pool(const size_t size = 10, const unsigned int spin_time ) :
        Q(size),
        m_size(size),
        m_spin_time(spin_time)
    {}

    ~Pool();

    size_type Size();

    void Push(const T &data);

    T Pop();

private:
    mds::Mutex m_mutex;
    size_t m_size;
    unsigned int m_spin_time;
};



template < typename T >
inline Pool::~Pool()
{
    mds::AutoLock al(m_mutex); (void)al;
    while ( Q::Size() ) {
        Q::Pop();
    }
}


template < typename T >
inline std::queue::size_type Pool::Size()
{
    mds::AutoLock al(m_mutex); (void)al;
    return Q::Size();
}


template < typename T >
inline void Pool::Push(const T &data)
{
    while( this->Size() >= m_size  ) {
        usleep(m_spin_time); // leaving unlocked pool //
    }
    m_mutex.lock();
    Q::Push(data);
    m_mutex.unlock();
}

template < typename T >
inline T Pool::Pop()
{
    while( this->Size() <= 0  ) {
        usleep(m_spin_time); // leaving unlocked pool //
    }
    m_mutex.lock();
    T data = Q::Pop();
    m_mutex.unlock();
    return data;
}










#endif // PRODUCERCONSUMER_H
