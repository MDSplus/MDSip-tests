#ifndef TESTCONTENT_H
#define TESTCONTENT_H

#include <mdsobjects.h>

#include "ClassUtils.h"
#include "Threads.h"

namespace mds = MDSplus;


////////////////////////////////////////////////////////////////////////////////
//  Content  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class Content {
public:

    Content(const char *name) :
        m_name(name)
    {}

    struct Element {
        std::string         path;
        unique_ptr<mds::Float32Array> data;
        unique_ptr<mds::Range> dim;
    };

    virtual std::string GetName() const { return m_name; }

    virtual size_t GetSize() const = 0;

    virtual bool GetNextElement(size_t size_KB, Element &el) = 0;

    template <typename T>
    static size_t GetKByteSizeIn(size_t KB) { return KB*1024/sizeof(T); }

protected:
    virtual ~Content() {}
    std::string m_name;    
};


//inline std::ostream &
//operator << (std::ostream &o, Content::Element &el) {
//    o << "path:  " << el.path << "\n"
//      << "data:  " << el.data << "\n"
//      << "dim:   " << el.dim  << "\n";
//    return o;
//}




////////////////////////////////////////////////////////////////////////////////
//  ContentFunciton ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class ContentFunction : public Content, Lockable {

    typedef double(*GenFunction)(double);

public:    
    ContentFunction(const char *name, size_t size_KB = 0);

    ~ContentFunction();

    size_t GetSize() const;

    enum FunctionEnum {
        Sine,
        NoiseG,
        NoiseW
    };
    void SetGenFunction(const enum FunctionEnum funt);

    void SetGenFunction(GenFunction func);

    virtual bool GetNextElement(size_t size_KB, Element &el);

    void SetSampleTime(float time) { m_sample_time = time; }    

    void ResetSize(size_t size_KB);

private:

    size_t m_size;
    float  m_sample_time; // seconds
    size_t m_current_sample;
    GenFunction m_func;

    mds::Tree  *m_subtree; // not used at the moment //
};






#endif // TESTCONTENT_H

