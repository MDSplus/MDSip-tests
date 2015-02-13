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


// WARNING: keep endianes in mind, this works only within the same machine //
struct RawBuffer {

    typedef unsigned char byte_t;

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

    typedef unsigned char byte_t;


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



    void Store() {
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
        resume();
    }


protected:

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

    byte_t *m_buf;
    size_t m_buf_size;
};




////////////////////////////////////////////////////////////////////////////////
//  SerializeToShm  ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>


class SerializeToShm : public SerializeToBin
{

public:
    SerializeToShm() : m_shm(0) {}

    ~SerializeToShm() { if (m_shm) Free(); }


    void Alloc(size_t size) {
        int shm_id = shmget(IPC_PRIVATE, size, SHM_R|SHM_W);
        if(shm_id<0) return;

        void *shm = shmat(shm_id,NULL,0);
        m_shm = shm;
    }

    void Free() {
        if (m_shm) shmdt(m_shm);
        m_shm = NULL;
    }

private:

//    void * shm_create(key_t ipc_key, int shm_size, int perm, int fill = 0)
//    {
//        int shm_id;
//        void * shm_ptr;
//        shm_id = shmget(ipc_key, shm_size, IPC_CREAT|perm);
//        if (shm_id < 0) {
//            return NULL;
//        }
//        shm_ptr = shmat(shm_id, NULL, 0);
//        if (shm_ptr < 0) {
//            return NULL;
//        }
//        memset((void *)shm_ptr, fill, shm_size);
//        return shm_ptr;
//    }

//    void * shm_find(key_t ipc_key, int shm_size)
//    {
//        void * shm_ptr;
//        int shm_id;
//        shm_id = shmget(ipc_key, shm_size, 0);
//        if (shm_id < 0) {
//            return NULL;
//        }
//        shm_ptr = shmat(shm_id, NULL, 0);
//        if (shm_ptr < 0) {
//            return NULL;
//        }
//        return shm_ptr;
//    }

//    int shm_remove(key_t ipc_key, void * shm_ptr)
//    {
//        int shm_id;
//        if (shmdt(shm_ptr) < 0) {
//            return -1;
//        }
//        shm_id = shmget(ipc_key, 0, 0);
//        if (shm_id < 0) {
//            if (errno == EIDRM) return 0;
//            return -1;
//        }
//        if (shmctl(shm_id, IPC_RMID, NULL) < 0) {
//            if (errno == EIDRM) return 0;
//            return -1;
//        }
//        return 0;
//    }

private:

    void *m_shm;
};







////////////////////////////////////////////////////////////////////////////////
//  STRING SERIALIZATION  //////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


template < class Archive >
void serialize(Archive &ar, std::string &str) {
    RawBuffer data;
    if(ar.is_writing()) {    
        for(size_t i=0;i<str.length()+1;++i) {
            data.m_data.push_back( str.c_str()[i] );
        }
        serialize( ar, data );
    }
    else {
        serialize( ar, data );
        std::stringstream ss;
        while ( data.size()-1 ) {
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


template < typename T >
inline std::ostream &
operator << (std::ostream &o, const std::vector<T> &v) {
    typedef typename std::vector<T>::const_iterator iterator;
    for(iterator it = v.begin(); it < v.end(); ++it) {
        o << *it << " ";
    }
    return o;
}




#endif // CLASSUTILS_H

