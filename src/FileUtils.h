#ifndef FILEUTILS_H
#define FILEUTILS_H

#include <fstream>


#include "ClassUtils.h"
#include "SerializeUtils.h" // container stream interaction //
#include "Threads.h"



class FileUtils
{
public:
    static bool FindDir(const char *name, const char *path = ".");
    static void CreateDir(const char *name, const char *path = ".");
    static char *GetEnv(const char *name);
    static void SetEnv(const char *name, const char *value);
    static void UnsetEnv(const char *name);
    void SetFile(char * ciao, int parm);


    static const std::string CurrentDateTime();

};



////////////////////////////////////////////////////////////////////////////////
//  CsvDataFile  ///////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class CsvDataFile : public std::fstream
{
    typedef std::fstream BaseClass;
public:
    CsvDataFile() :
        m_comma(';')
    {}

    explicit CsvDataFile(const char *name, std::ios_base::openmode mode = std::ios_base::out, const char comma = ';') :
        BaseClass(name,mode),
        m_file_name(name),
        m_comma(comma)
    {}

    // hide fstream open //
    void open(const std::string &s, ios_base::openmode mode) {
        m_file_name = s;
        BaseClass::open(s.c_str(),mode);
    }

    // hide fstream open //
    void open(const char *s, ios_base::openmode mode) {
        m_file_name = s;
        BaseClass::open(s,mode);
    }

    const char Separator() const { return m_comma; }

private:
    std::string m_file_name;
    char m_comma;
};



////////////////////////////////////////////////////////////////////////////////
//  Options  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace detail {
class value_semantic {
public:
    value_semantic(const char *name,
                   const char ch = 0,
                   const char *desc = "") :
        m_name(name),
        m_ch(ch),
        m_description(desc)
    {}

    virtual ~value_semantic() {}

    virtual void parse( std::string str) {}

    virtual std::string toString() { return ""; }

    const std::string m_name;
    const char  m_ch;
    std::string m_description;
};

template <typename T>
class value_type : public value_semantic {
    T *m_ptr;
public:
    value_type(const char *name,
               T *ptr = NULL,
               const char ch = 0,
               const char *desc = "") :
        value_semantic(name,ch,desc), m_ptr(ptr) {}

    void parse(std::string str) {
        std::stringstream ss(str);
        ss >> *m_ptr;
    }

    std::string toString() {
        std::stringstream ss;
        ss << *m_ptr;
        return ss.str();
    }
};

template <>
class value_type<std::string> : public value_semantic {
    std::string *m_ptr;
public:
    value_type(const char *name,
               std::string *ptr = NULL,
               const char ch = 0,
               const char *desc = "") :
        value_semantic(name,ch,desc), m_ptr(ptr) {}

    void parse(std::string str) { *m_ptr = str; }
    std::string toString() { return *m_ptr; }
};
} // detail


class Options {

    typedef unique_ptr< detail::value_semantic > Value;

public:

    class OptionInit {
        Options *m_init;
    public:
        OptionInit(Options &options) : m_init(&options) {}

        OptionInit &
        operator()(const char *name) {
            m_init->addValue( new detail::value_semantic(name) );
            return *this;
        }

        OptionInit &
        operator()(const char *name, const char *desc) {
            m_init->addValue( new detail::value_semantic(name,0,desc) );
            return *this;
        }

        template <typename T>
        OptionInit &
        operator()(const char* name, T * value, const char* description = "") {
            m_init->addValue( new detail::value_type<T>(name,value,0,description) );
            return *this;
        }
    };

    Options(const char *usage = "") : m_usage(usage) {
        this->AddOptions()("help","print this help");
    }

    void SetUsage(std::string usage) { m_usage = usage; }

    OptionInit AddOptions() { return OptionInit(*this); }

    void Parse(int argc, char *argv[]);

    void PrintSelf(std::ostream &o);

private:

    bool isCharTag(const char *str) { return std::strlen(str)>2 && str[0] == '-' && std::isalpha(str[1]); }

    bool isNameTag(const char *str) { return std::strlen(str)>3 && strncmp(str,"--",2) == 0 && std::isalpha(str[2]); }

    detail::value_semantic *findValueByName(const char *name) {
        foreach (detail::value_semantic *val, m_values) {
            if(val->m_name == name) return val;
        }
        return NULL;
    }

    detail::value_semantic *findValueByChar(const char *ch) {
        foreach (detail::value_semantic *val, m_values) {
            if(val->m_ch == ch[0]) return val;
        }
        return NULL;
    }

    void addValue(detail::value_semantic *val) {
        m_values.push_back(val);
    }

    std::vector< Value > m_values;
    std::string          m_usage;
};










#endif // FILEUTILS_H
