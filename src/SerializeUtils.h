#ifndef SERIALIZEUTILS_H
#define SERIALIZEUTILS_H


#include <stdlib.h>
#include <iostream>
#include <sstream>
#include <cstring>
#include <string>

// SERIALIZATION CONTAINERS //
#include <vector>
#include <deque>

// SHM SERIALIZTION //
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>



////////////////////////////////////////////////////////////////////////////////
//  Raw Buffer  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

typedef unsigned char byte_t;

// WARNING: keep endianes in mind, this works only within the same machine //
struct RawBuffer {


    template < typename T >
    friend RawBuffer & operator << (RawBuffer &r, const T &data) {
        const byte_t *pos = (byte_t *)&data;
        const byte_t *end = (byte_t *)&data + sizeof(data);
        while(pos < end) {
            r.m_data.push_back(*pos++);
        }
        return r;
    }

    template < typename T >
    friend RawBuffer & operator >> (RawBuffer &r, T &data) {
        byte_t *pos = (byte_t *)&data;
        byte_t *end = (byte_t *)&data + sizeof(data);
        while(pos < end) {
            *pos++ = r.m_data.front();
            r.m_data.pop_front();
        }
        return r;
    }

    size_t size() const { return m_data.size(); }

    std::deque<byte_t> m_data;
};





////////////////////////////////////////////////////////////////////////////////
//  SerializeToBin  ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class SerializeToBin
{

    ///
    /// \brief The pod struct
    ///
    /// Pod is a wrapper around an instance that holds opaque pointer and length
    /// It is intentionally left copyable as is can be built by serialize operator
    ///
    struct pod {

        pod() : len(0), ptr(0), del(0) {}

        ~pod() {
            if(del) { delete[] ptr; }
        }

        pod(const pod &other) : len(other.len), ptr(other.ptr), del(other.del) { const_cast<pod&>(other).del = false; }
        pod(pod &other) : len(other.len), ptr(other.ptr), del(other.del) { other.del = false; }

        pod(const RawBuffer &raw) {
            this->alloc(raw.m_data.size());
            std::copy(raw.m_data.begin(),raw.m_data.end(),ptr);
            del = true;
        }
        pod(RawBuffer &raw) {
            this->alloc(raw.m_data.size());
            std::copy(raw.m_data.begin(),raw.m_data.end(),ptr);
            del = true;
        }

        // does it works ? //
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

    ///
    /// Write Archive for serialization ...
    ///

    struct _Write {
        SerializeToBin &archive;
        static const bool is_writing() { return true; }
        _Write(SerializeToBin &s) : archive(s) {}
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

    friend void serialize ( _Write &ser, RawBuffer &data )
    {
        ser.archive.push(pod(data));
    }



    ///
    /// Read Archive for serialization ...
    ///

    struct _Read {
        SerializeToBin &archive;
        static const bool is_writing() { return false; }
        _Read(SerializeToBin &s) : archive(s) {}
    };

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

    friend void serialize ( _Read &ser, RawBuffer &raw )
    {
        pod p = ser.archive.pop();
        const byte_t *pos = p.ptr;
        const byte_t *end = p.ptr + p.len;
        while(pos < end) {
            raw.m_data.push_back(*pos++);
        }
    }



    SerializeToBin() :
        m_write(*this),
        m_read(*this),
        m_buf(0), m_buf_size(0)
    {}

    ~SerializeToBin() {
        if(m_buf) delete[] m_buf;
    }

    _Write & Write() { return m_write; }

    const _Read  & Read()  { return m_read; }


    byte_t * GetBinary() const { return m_buf; }

    void Clear() { m_pods.clear(); /*this->ClearBuffer(); */}

    /// push into contiguous memory segment
    void Store() {
        // allocate buffer //
        size_t tot_len = 0;
        for(std::deque<pod>::iterator it=m_pods.begin(); it<m_pods.end();++it)
            tot_len += it->len + sizeof(size_t);

        AllocateBuffer(tot_len);

        // fill memory segment //
        byte_t *pos = m_buf;
        for(std::deque<pod>::iterator it=m_pods.begin(); it<m_pods.end();++it) {
            memcpy(pos,&it->len,sizeof(size_t));
            pos += sizeof(size_t);
            memcpy(pos,(byte_t*)it->ptr, it->len);
            pos += it->len;
        }
        m_pods.clear();
        m_buf_size = tot_len;
        Resume();
    }

    void Resume() {
        // read memory back into pods //
        this->Clear();
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

protected:

    virtual void ClearBuffer() {
        if(m_buf) delete[] m_buf;
        m_buf = NULL;
    }

    virtual void AllocateBuffer(size_t size) {
        ClearBuffer();
        m_buf = new byte_t[size];
    }


    void push(const pod &p) {
        m_pods.push_back(p);
    }

    pod pop() {
        pod p = m_pods.front();
        m_pods.pop_front();
        return p;
    }

private:
    std::deque< pod > m_pods;

    _Write m_write;
    _Read  m_read;

protected:
    byte_t *m_buf;
    size_t m_buf_size;
};




////////////////////////////////////////////////////////////////////////////////
//  SerializeToShm  ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class SerializeToShm : public SerializeToBin
{

public:
    SerializeToShm() {}

    ~SerializeToShm() { ClearBuffer(); }

    void Reserve(size_t size);

    // WARNING: ... //
    void AllocateBuffer(size_t size) {
        if(m_buf) return;
        Reserve(size * 1.5); // hardcoded 1.5 size factor //
    }

    void ClearBuffer();

};







////////////////////////////////////////////////////////////////////////////////
//  STRING SERIALIZATION  //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template < class Archive >
void serialize(Archive &ar, std::string &str) {
    RawBuffer data;
    if(ar.is_writing()) {
        for(size_t i=0;i<str.length();++i) {
            data.m_data.push_back( str.c_str()[i] );
        }
        serialize( ar, data );
    }
    else {
        serialize( ar, data );
        std::stringstream ss;
        while ( data.size() ) {
            char c;
            data >> c;
            ss << c;
        }
        str = ss.str();
    }
}


////////////////////////////////////////////////////////////////////////////////
//  CONTAINERS SERIALIZATION  //////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template < class Archive, typename T >
void serialize(Archive &ar, std::vector<T> &cnt) {
    typedef typename std::vector<T>::iterator iterator;
    typedef typename std::vector<T>::const_iterator const_iterator;
    typedef typename std::vector<T>::size_type size_type;
    RawBuffer data;
    if(ar.is_writing()) {
        data << cnt.size();
        for(const_iterator it = cnt.begin(); it < cnt.end(); ++it) {
            data << *it;
        }
        serialize(ar,data);
    }
    else {
        serialize(ar,data);
        size_type cnt_size;
        data >> cnt_size;
        cnt.resize(cnt_size);
        for(iterator it = cnt.begin(); it < cnt.end(); ++it) {
            data >> *it;
        }
    }

}


namespace std {

template < typename T >
inline ostream &
operator << (ostream &o, const vector<T> &v) {
    typedef typename vector<T>::const_iterator iterator;
    for(iterator it = v.begin(); it < v.end(); ++it) {
        o << *it << " ";
    }
    return o;
}

template < typename T >
inline istream &
operator >> (istream &is, vector<T> &v) {
    T value;
    v.clear();
    while( !(is >> value).fail() )
        v.push_back(value);
    return is;
}



} // std





#endif // SERIALIZEUTILS_H

