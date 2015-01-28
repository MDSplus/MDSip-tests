#ifndef TESTCONTENT_H
#define TESTCONTENT_H

#include <mdsobjects.h>

namespace mds = MDSplus;


////////////////////////////////////////////////////////////////////////////////
//  Content  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class Content {
public:

    Content(const char *name) : m_name(name) {}

    struct Element {
        std::string         path;
        mds::Float32Array  *data;
        mds::Range         *dim;
    };


    virtual std::string GetName() const { return m_name; }

    virtual Element GetNextElement(size_t size_KB) = 0;

    template <typename T>
    static size_t GetKByteSizeIn(size_t KB) { return KB*1024/sizeof(T); }



protected:
    virtual ~Content() {}
    std::string m_name;
};


inline std::ostream &
operator << (std::ostream &o, Content::Element &el) {
    o << "path:  " << el.path << "\n"
      << "data:  " << el.data << "\n"
      << "dim:   " << el.dim  << "\n";
    return o;
}




////////////////////////////////////////////////////////////////////////////////
//  ContentFunciton ////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


class ContentFunction : public Content {

    typedef double(*GenFunction)(double);

public:    
    ContentFunction(const char *name);

    ~ContentFunction();

    enum FunctionEnum {
        Sine,
        NoiseG,
        NoiseW
    };
    void SetGenFunction(const enum FunctionEnum funt);

    virtual Element GetNextElement(size_t size_KB);

    void SetSampleTime(float time) { m_sample_time = time; }    

private:   
    mds::Mutex m_mutex;
    mds::Tree *m_subtree;
    float m_sample_time;
    float m_current_time;
    GenFunction m_func;
};






#endif // TESTCONTENT_H

