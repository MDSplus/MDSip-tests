#ifndef CLASSUTILS_H
#define CLASSUTILS_H

#include <stdlib.h>
#include <cstring>
#include <vector>
#include <string>



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
//  SerializeToBin  ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class SerializeToBin
{
public:

    struct pod {

        pod() : len(0), ptr(NULL) {}

        pod & operator = ( const pod &other) {
            if(ptr && len == other.len) memcpy(ptr, other.ptr, len);
            else {
                len = other.len;
                ptr = malloc(len);
                memcpy(ptr, other.ptr, len);
            }
            return *this;
        }

        template < typename _T >
        pod(const _T &data) :
            len(sizeof(_T)),
            ptr((void*)&data)
        {}

        pod clone() const {
            pod other;
            other.len = len;
            other.ptr = malloc(len);
            memcpy(other.ptr, ptr, len); // remove?
            return other;
        }

        void free() { std::free(ptr); }

        size_t  len;
        void   *ptr;
    };


    struct _Write {
        SerializeToBin &archive;
        static const bool is_writing() { return true; }
        _Write(SerializeToBin &s) : archive(s) {}
    };

    struct _Read {
        SerializeToBin &archive;
        static const bool is_writing() { return false; }
        _Read(SerializeToBin &s) : archive(s) {}
    };

    template < typename T >
    friend _Write & operator & ( _Write &ser, T &data )
    {
        serialize(ser,data);
        return ser;
    }

    template < typename T >
    friend const _Read & operator & ( const _Read &ser, T &data )
    {
        serialize(const_cast<_Read&>(ser),data);
        return ser;
    }

    friend void serialize ( _Write &ser, pod data )
    {
        ser.archive.m_pods.push_back( data.clone() );
    }

    friend void serialize ( _Read &ser, pod data )
    {
        std::vector<pod> &v = ser.archive.m_pods;

        data = v.front();

        std::swap(v.front(),v.back());
        v.back().free();
        v.pop_back();
    }


    template < class Archive >
    friend void serialize(Archive &ar, std::string &str) {
        if(ar.is_writing()) {
            pod p;
            p.len = str.length() + 2;
            p.ptr = (void *)str.c_str();
            ar.archive.m_pods.push_back( p.clone() );
            std::cout << "write str\n";
        }
        else {
            std::vector<pod> &v = ar.archive.m_pods;
            pod p = v.front();
            std::swap(v.front(),v.back());
            v.back().free();
            v.pop_back();
            str = std::string( (const char *)p.ptr );
            std::cout << "read str\n";
        }
    }

    SerializeToBin() :
        m_write(*this),
        m_read(*this) {}

    _Write & Write() { return m_write; }

    const _Read  & Read()  { return m_read; }

private:
    std::vector< pod > m_pods;
    _Write m_write;
    _Read  m_read;
};








#endif // CLASSUTILS_H

