#ifndef CLASSUTILS_H
#define CLASSUTILS_H

#include <stdlib.h>
#include <cstring>
#include <vector>
#include <deque>
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
//  Unique Ptr  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template < typename T >
class unique_ptr {
    unique_ptr(const T &ref) : ptr(new T(ref)) {}
    T *ptr;
public:

    unique_ptr(unique_ptr &other) : ptr(other.ptr)
    { other.ptr = NULL; }

    unique_ptr(T *ref) : ptr(ref) {}

    ~unique_ptr() { if(ptr) delete ptr; }

    T * operator ->() { return ptr; }
    const T * operator ->() const { return ptr; }
};



////////////////////////////////////////////////////////////////////////////////
//  Raw Buffer  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


struct RawBuffer {

    template < typename T >
    friend RawBuffer & operator << (RawBuffer &r, const T &data) {
        const byte_t *pos = &data;
        const byte_t *end = &data + sizeof(data);
        while(pos < end) {
            r.m_data.push_back(*pos);
        }
        return r;
    }

    std::vector<byte_t> m_data;
};





////////////////////////////////////////////////////////////////////////////////
//  SerializeToBin  ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class SerializeToBin
{

    typedef unsigned char byte_t;

    struct pod {

        pod() : len(0), ptr(0), del(0) {}

        ~pod() {
            if(del) { delete ptr; }
        }

        pod(const pod &other) : len(other.len), ptr(other.ptr), del(other.del) { const_cast<pod&>(other).del = false; }
        pod(pod &other) : len(other.len), ptr(other.ptr), del(other.del) { other.del = false; }

        template <typename T >
        explicit pod(T *t) : len(sizeof(T)), ptr((byte_t*)t), del(0) { if(t==0) len=0; }

        template <typename T >
        pod(T &t) : len(sizeof(T)), ptr((byte_t*)&t), del(0) {}

        void copy_from(const pod &p) {
            len = p.len;
            memcpy(ptr,p.ptr,len);
        }

        void alloc(const size_t size) {
            try {
                ptr = new byte_t[size];
                len = size;
                del = true;
            }
            catch(std::bad_alloc e) {
                throw e;
            }
        }

        size_t  len;
        byte_t *ptr;
        bool del;
    };    

public:

    struct raw : pod {

        raw() {}
        raw(const pod &p) : pod(p) {}
        raw(pod &p) : pod(p) {}

        operator pod () {
            pod p;
            p.alloc(m_data.size());
            std::copy(m_data.begin(),m_data.end(),p.ptr);
            p.del = true;
            return p;
        }

        template < typename T >
        friend raw & operator << (raw &r, const T &data) {
            const byte_t *pos = &data;
            const byte_t *end = &data + sizeof(data);
            while(pos < end) {
                r.m_data.push_back(*pos);
            }
            return r;
        }

        std::vector<byte_t> m_data;
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
    friend _Write & operator & ( _Write &ser, T *&data )
    {
        if(data) serialize(ser,*data);
        return ser;
    }

    template < typename T >
    friend _Write & operator & ( _Write &ser, T &data )
    {
        serialize(ser,data);
        return ser;
    }

    friend void serialize ( _Write &ser, pod data )
    {
        ser.archive.push(data);
    }

    friend void serialize ( _Write &ser, raw &data )
    {
        ser.archive.push(data.operator pod());
    }

    template < typename T >
    friend const _Read & operator & ( const _Read &ser, T *&data )
    {
        if(data) serialize(const_cast<_Read&>(ser),*data);
        return ser;
    }

    template < typename T >
    friend const _Read & operator & ( const _Read &ser, T &data )
    {
        serialize(const_cast<_Read&>(ser),data);
        return ser;
    }

    friend void serialize ( _Read &ser, pod data )
    {
        pod p = ser.archive.pop();
        data.copy_from(p);
    }

    friend void serialize ( _Read &ser, raw &data )
    {
        data = ser.archive.pop();
    }


    template < class Archive >
    friend void serialize(Archive &ar, std::string &str) {
        if(ar.is_writing()) {
            raw data;
            for(size_t i=0;i<str.length()+1;++i) {
                data.m_data.push_back( str.c_str()[i] );
            }
            serialize( ar, data );
        }
        else {
            raw data;
            serialize( ar, data );
            str = std::string( (const char *)data.ptr );
        }
    }

    SerializeToBin() :
        m_write(*this),
        m_read(*this),
        m_buf(0), m_buf_size(0)
    {}

    ~SerializeToBin() {
        if(m_buf) delete m_buf;
    }

    _Write & Write() { return m_write; }

    const _Read  & Read()  { return m_read; }

    void print() const {
        std::cout << "PODS:\n";
        for(size_t i=0; i< m_pods.size(); ++i) {
            const pod &p = m_pods[i];
            std::cout << " len:" << p.len << " ptr:" << (void*)p.ptr << "  cast<float>:" << *(float*)p.ptr << "\n";
        }
    }

protected:

    void push(const pod &p) {
        m_pods.push_back(p);
    }

    pod pop() {
        pod p = m_pods.front();
        m_pods.pop_front();
        return p;
    }

public:

    void store() {
        // push into contiguous memory segment //
        size_t tot_len = 0;
        for(std::deque<pod>::iterator it=m_pods.begin(); it<m_pods.end();++it)
            tot_len += it->len + sizeof(size_t);

        if(m_buf) delete m_buf;
        m_buf = new byte_t[tot_len];
        byte_t *pos = m_buf;
        for(std::deque<pod>::iterator it=m_pods.begin(); it<m_pods.end();++it) {
            memcpy(pos,&it->len,sizeof(size_t));
            pos += sizeof(size_t);
            memcpy(pos,(byte_t*)it->ptr, it->len);
            pos += it->len;
        }
        m_pods.clear();
        m_buf_size = tot_len;
    }

    void resume() {
        // read memory back into pods //
        byte_t *pos = m_buf;
        byte_t *end = m_buf + m_buf_size;
        while (pos < end)
        {
            pod p;
            p.len = *(size_t*)pos;
            p.ptr =  (byte_t *)(pos + sizeof(size_t));
            pos += sizeof(size_t) + sizeof(byte_t) * p.len;
            push( p );
        }
    }

private:
    std::deque< pod > m_pods;

    _Write m_write;
    _Read  m_read;
    byte_t *m_buf;
    size_t m_buf_size;
};









#endif // CLASSUTILS_H

