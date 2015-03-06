#ifndef CLASSUTILS_H
#define CLASSUTILS_H

#include <stdlib.h>
#include <iostream>
#include <sstream>
#include <cstring>
#include <assert.h>

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
// TODO: Waiting for Static interface mpl check

template < typename ContainerT, typename ContentT >
struct CommaInitializer
{
    typedef ContentT&(ContainerT::* OpType)(const size_t);

    inline explicit CommaInitializer(ContainerT *container, ContentT s, OpType op = &ContainerT::operator() )
        : container(container), operation(op)
    {
        this->index = 0;
        container->resize(1);
        (container->*operation)(0) = s;
    }
    inline CommaInitializer & operator, (ContentT s) {
        this->index++;
        container->resize(index + 1);
        (container->*operation)(this->index) = s;
        return *this;
    }

    ContainerT *container;
    OpType      operation;
    unsigned int index;
};



// Comma Initializer template for fixed array...
// ContentT should provide operator[] and size() methods.
// TODO: Waiting for Static interface mpl check

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
//  COMMA INIT FOR CONTAINERS  /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


namespace std {

template < typename _T >
inline CommaInitializer< std::vector<_T>, _T > operator << (std::vector<_T> &cnt, _T scalar ) {
    return CommaInitializer< std::vector<_T>, _T>(&cnt,scalar,&std::vector<_T>::operator []);
}

} // std












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

    Singleton(const T &copy) {
        this->get_instance() = copy;
    }

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
//    Singleton(Singleton const&);      // Don't Implement
    void operator=(Singleton const&); // Don't implement
};




////////////////////////////////////////////////////////////////////////////////
//  TYPE TRAITS  ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//  MACROS  ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define MDSIPTEST_PP_STRINGIZE_I(text) #text
#define MDSIPTEST_STATIC_CONSTANT(type, assignment) static const type assignment

#define DO_PRAGMA(x) _Pragma (#x)
#define TODO(x) DO_PRAGMA(message ("TODO - " #x))
#define COMPILE_WARNING(x) DO_PRAGMA(message ("WARNING - " #x))
#define COMPILE_ERROR(x) DO_PRAGMA(message ("ERROR - " #x))

////////////////////////////////////////////////////////////////////////////////
//  CV QUALIFIERS MATHCING  ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace detail {

#define MDSIPTEST_TT_AUX_CV_TRAITS_IMPL_PARAM(X) X *
template <typename T> struct cv_traits_imp {};

template <typename T>
struct cv_traits_imp<T*>
{
    MDSIPTEST_STATIC_CONSTANT(bool, is_const    = false);
    MDSIPTEST_STATIC_CONSTANT(bool, is_volatile = false);
    typedef T unqualified_type;
};

template <typename T>
struct cv_traits_imp<MDSIPTEST_TT_AUX_CV_TRAITS_IMPL_PARAM(const T)>
{
    MDSIPTEST_STATIC_CONSTANT(bool, is_const    = true);
    MDSIPTEST_STATIC_CONSTANT(bool, is_volatile = false);
    typedef T unqualified_type;
};

template <typename T>
struct cv_traits_imp<MDSIPTEST_TT_AUX_CV_TRAITS_IMPL_PARAM(volatile T)>
{
    MDSIPTEST_STATIC_CONSTANT(bool, is_const    = false);
    MDSIPTEST_STATIC_CONSTANT(bool, is_volatile = true);
    typedef T unqualified_type;
};

template <typename T>
struct cv_traits_imp<MDSIPTEST_TT_AUX_CV_TRAITS_IMPL_PARAM(const volatile T)>
{
    MDSIPTEST_STATIC_CONSTANT(bool, is_const    = true);
    MDSIPTEST_STATIC_CONSTANT(bool, is_volatile = true);
    typedef T unqualified_type;
};
#undef MDSIPTEST_TT_AUX_CV_TRAITS_IMPL_PARAM

} // detail


////////////////////////////////////////////////////////////////////////////////
//  IS CONST  //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


namespace detail {
template <class T>
struct is_const_rvalue_filter
{
    static const bool value =
            detail::cv_traits_imp<T*>::is_const;
};

template <class T>
struct is_const_rvalue_filter<T*>
{
    static const bool value =
            detail::cv_traits_imp<T*>::is_const;
};

template <class T>
struct is_const_rvalue_filter<T&>
{ static const bool value = false; };

template <class T>
struct is_const_rvalue_filter<const T&>
{ static const bool value = true; };

} // detail

template < typename T >
struct is_const : detail::is_const_rvalue_filter<T> {};


////////////////////////////////////////////////////////////////////////////////
//  FOREACH EXPANSION  /////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <typename T, bool IsConst = true >
class ForeachOnContainer {
public:
    inline ForeachOnContainer(const T & t) :
        m_cnt(t),
        brk(0),
        itr(m_cnt.begin()),
        end(m_cnt.end())
    { }
    const T & m_cnt; int brk;
    typename T::const_iterator itr,end;
};

template <typename T >
class ForeachOnContainer<T,false> {
public:
    inline ForeachOnContainer(T & t) :
        m_cnt(t),
        brk(0),
        itr(m_cnt.begin()),
        end(m_cnt.end())
    { }
    T & m_cnt; int brk;
    typename T::iterator itr,end;
};



} // detail


// WARNING: GCC ONLY //
#define _FOREACH_EXPANSION(variable, container)                          \
for (detail::ForeachOnContainer<__typeof__(container), is_const<__typeof__(container)>::value > _cnt(container); \
     !_cnt.brk && _cnt.itr != _cnt.end;                                  \
     __extension__  ({ ++_cnt.brk; ++_cnt.itr; })  )                \
    for (variable = *_cnt.itr;; __extension__ ({--_cnt.brk; break;}))

// foreach loop re-definition //
# ifdef foreach
#  undef foreach
   COMPILE_WARNING( overloading foreach definition );
# else
#  define foreach _FOREACH_EXPANSION
# endif





////////////////////////////////////////////////////////////////////////////////
//  Flags  /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////




template<typename Enum>
class Flags
{
    int i;
public:
    typedef Enum enum_type;
    inline Flags(const Flags &f) : i(f.i) {}
    inline Flags(Enum f) : i(f) {}
    inline Flags(unsigned int f) : i(f) {}
    inline Flags() : i(0) {}

    inline Flags &operator=(const Flags &f) { i = f.i; return *this; }
    inline Flags &operator&=(int mask) { i &= mask; return *this; }
    inline Flags &operator&=(uint mask) { i &= mask; return *this; }
    inline Flags &operator|=(Flags f) { i |= f.i; return *this; }
    inline Flags &operator|=(Enum f) { i |= f; return *this; }
    inline Flags &operator^=(Flags f) { i ^= f.i; return *this; }
    inline Flags &operator^=(Enum f) { i ^= f; return *this; }

    inline operator int() const { return i; }

    inline Flags operator|(Flags f) const { return Flags(Enum(i | f.i)); }
    inline Flags operator|(Enum f) const { return Flags(Enum(i | f)); }
    inline Flags operator^(Flags f) const { return Flags(Enum(i ^ f.i)); }
    inline Flags operator^(Enum f) const { return Flags(Enum(i ^ f)); }
    inline Flags operator&(int mask) const { return Flags(Enum(i & mask)); }
    inline Flags operator&(uint mask) const { return Flags(Enum(i & mask)); }
    inline Flags operator&(Enum f) const { return Flags(Enum(i & f)); }
    inline Flags operator~() const { return Flags(Enum(~i)); }

    inline bool operator!() const { return !i; }
    inline bool testFlag(Enum f) const { return (i & f) == f && (f != 0 || i == int(f) ); }

    // non funzia ..
    //    inline friend Flags operator | (Enum f1, Enum f2)
    //    { return Flags(f1) | f2; }

    //    inline friend Flags operator | (Enum f1, Flags f2)
    //    { return f2 | f1; }
};



#define DEFINE_OPERATORS_FOR_FLAGS(_flags) \
    inline Flags<_flags::enum_type> operator | (_flags::enum_type f1, _flags::enum_type f2) \
{ return Flags<_flags::enum_type>(f1) | f2; } \
    inline Flags<_flags::enum_type> operator | (_flags::enum_type f1, Flags<_flags::enum_type> f2) \
{ return f2 | f1; }


















#endif // CLASSUTILS_H

