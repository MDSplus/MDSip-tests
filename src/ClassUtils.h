#ifndef CLASSUTILS_H
#define CLASSUTILS_H

#include <stdlib.h>
#include <iostream>
#include <sstream>
#include <cstring>

#include <vector>
#include <deque>
#include <string>

#include <mdsobjects.h>

namespace mds = MDSplus;

////////////////////////////////////////////////////////////////////////////////
//  Comma Init  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


// Comma Initializer template ...
// ContentT should provide operator[] and resize() methods.
// Waiting for Static interface check

template < typename ContainerT, typename ContentT >
struct CommaInitializer
{
    inline explicit CommaInitializer(ContainerT *container, ContentT s)
        : container(container)
    {
        this->index = 0;
        container->resize(1);
        this->container->operator()(0) = s;
    }
    inline CommaInitializer & operator, (ContentT s) {
        this->index++;
        container->resize(index + 1);
        this->container->operator()(this->index) = s;
        return *this;
    }

    ContainerT *container;
    unsigned int index;
};


// Comma Initializer template for fixed array...
// ContentT should provide operator[] and size() methods.
// Waiting for Static interface check

template < typename ContainerT, typename ContentT >
struct CommaInitializerFixed
{
    inline explicit CommaInitializerFixed(ContainerT *container, ContentT s)
        : container(container)
    {
        this->index = 0;
        this->container->operator[](0) = s;
    }
    inline CommaInitializerFixed & operator, (ContentT s) {
        this->index++;
        this->container->operator[](this->index) = s;
        return *this;
    }

    ContainerT *container;
    unsigned int index;
};





////////////////////////////////////////////////////////////////////////////////
//  AutoDelete  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

template < class T >
class AutoDelete
{
public:
    AutoDelete(const T *ptr) : m_ptr(ptr) {}

    ~AutoDelete() {
        delete m_ptr;
    }

private:
    const T *m_ptr;
};




////////////////////////////////////////////////////////////////////////////////
//  Unique Ptr  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template < typename T >
class Deleter {
public:
    static void _delete(mds::Data * ptr) {
        mds::deleteData(ptr);
    }

    static void _delete(void * ptr) {
        delete (T*)(ptr);
    }
};

template < typename T, typename D = Deleter<T> >
class unique_ptr {
    unique_ptr(const T &ref) : ptr(new T(ref)) {}
    T *ptr;
public:

    unique_ptr() : ptr(NULL) {}

    unique_ptr(unique_ptr &other) : ptr(other.ptr)
    { other.ptr = NULL; }

    unique_ptr(const unique_ptr &other) : ptr(other.ptr)
    { const_cast<unique_ptr&>(other).ptr = NULL; }

    unique_ptr(T *ref) : ptr(ref) { }

    ~unique_ptr() { _delete(); }

    unique_ptr & operator = (T * ref) {
        _delete();
        ptr = ref;
    }

    unique_ptr & operator = (unique_ptr other) {
        ptr = other.ptr;
        other.ptr = NULL;
    }

    void _delete() { if(ptr) D::_delete(ptr); ptr=NULL; }

    operator bool() { return ptr; }

    operator T *() { return ptr; }
    operator const T *() const { return ptr; }

    T * operator ->() { return ptr; }
    const T * operator ->() const { return ptr; }

    T * base() { return ptr; }
    const T * base() const { return ptr; }
};






////////////////////////////////////////////////////////////////////////////////
//  Singleton  /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


///
/// Single instance within the same linked module
///
template < typename T >
class Singleton {
public:

    Singleton() {}

    inline T * const operator -> () { return &get_instance(); }
    inline const T * const operator -> () const { return &get_instance(); }

    static T & get_instance() {
        static T instance;
        return instance;
    }

    static const T & get_const_instance() {
        return const_cast<const T&>(get_instance());
    }

private:
    Singleton(Singleton const&);      // Don't Implement
    void operator=(Singleton const&); // Don't implement
};








////////////////////////////////////////////////////////////////////////////////
//  FOREACH EXPANSION  /////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// GCC ONLY //

namespace detail {
template <typename T>
class ForeachOnContainer {
public:
    inline ForeachOnContainer( T & t) :
        m_cnt(t),
        brk(0),
        itr(m_cnt.begin()),
        end(m_cnt.end())
    { }

    inline ForeachOnContainer(const T& t) :
        m_cnt(const_cast<T&>(t)),
        brk(0),
        itr(m_cnt.begin()),
        end(m_cnt.end()) { } // bad solution //
    T m_cnt; int brk;
    typename T::iterator itr, end;
};
} // detail

#define _FOREACH_EXPANSION(variable, container)                                 \
for (detail::ForeachOnContainer<__typeof__(container)> _foreach_cnt_(container);  \
     !_foreach_cnt_.brk && _foreach_cnt_.itr != _foreach_cnt_.end;                    \
     __extension__  ({ ++_foreach_cnt_.brk; ++_foreach_cnt_.itr; }))                \
    for (variable = *_foreach_cnt_.itr;; __extension__ ({--_foreach_cnt_.brk; break;}))

#define foreach _FOREACH_EXPANSION






#endif // CLASSUTILS_H

