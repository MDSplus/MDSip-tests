#include <iostream>

#include <stdlib.h>
#include <string.h>
#include <dirent.h> // POSIX only //

#include <mdsobjects.h>

#include "ClassUtils.h"
#include "FileUtils.h"

using namespace MDSplus;

///
/// \brief FileUtils::FindDir
/// \param name name of the directory to be searched
/// \param path path of the current search
/// \return true if name is a file or a directory in path
///
bool FileUtils::FindDir(const char *name, const char *path)
{
    // TODO: manage wildchards and search for dir only not files
    DIR * dr = opendir(path);
    if(!dr) return false;

    bool found = false;
    while ( dirent *dren = readdir(dr) ) {
        //  std::cout << dren->d_name << "\n";
        if( strcmp(dren->d_name,name) == 0 ) {
            found = true; break;
        }
    }
    closedir(dr);
    return found;
}

///
/// \brief FileUtils::CreateDir
void FileUtils::CreateDir(const char *name, const char *path)
{
    if( !FindDir(name,path) )
    {
        char cmd[200];
        sprintf(cmd,"mkdir %s/%s",path,name);
        system(cmd);
    }
}

///
/// \return NULL if doesn't exist
///
char * FileUtils::GetEnv(const char *name)
{
    return getenv(name);
}

///
/// \brief FileUtils::SetEnv
/// \param name name of the evironment variable to set
/// \param value vlaue of the variable
///
void FileUtils::SetEnv(const char *name, const char *value)
{
    char *env = getenv(name);
    if( env && strcmp(env,value) != 0 )
        std::cerr << "WARNING: env var already set with different value, replacing...\n";
    setenv(name,value,true);
}

void FileUtils::UnsetEnv(const char *name)
{
    char *env = getenv(name);
    if( env ) unsetenv(env);
}

const std::string FileUtils::CurrentDateTime()
{
       time_t     now = time(0);
       struct tm  tstruct;
       char       buf[80];
       tstruct = *localtime(&now);
       strftime(buf, sizeof(buf), "%Y-%m-%d.%X", &tstruct);
       return buf;
}






////////////////////////////////////////////////////////////////////////////////
//  Options  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



void Options::Parse(int argc, char *argv[])
{
    for(int i=1; i<argc; ++i) {
        detail::value_semantic *val = NULL;
        if( isNameTag(argv[i]) ) {
            val = findValueByName(argv[i]+2);
            std::stringstream arg;
            while( ++i < argc && !isCharTag(argv[i]) && !isNameTag(argv[i]) )
                arg << argv[i] << " ";
            --i;
            if(val) val->parse(arg.str());
        }
        else if( isCharTag(argv[i])) {
            val = findValueByChar(argv[i]+1);
            std::stringstream arg;
            while( ++i < argc && !isCharTag(argv[i]) && !isNameTag(argv[i]) )
                arg << argv[i] << " ";
            --i;
            if(val) val->parse(arg.str());
        }

        if(val && val->m_name == "help") {
            this->PrintSelf(std::cout);
            exit(0);
        }
    }
}


void Options::PrintSelf(std::ostream &o)
{
    o << "\n" << m_usage << "\n\n";
    foreach (detail::value_semantic *val, m_values) {
        if(val->m_ch)
            o << "-" << val->m_ch << " ";
        o << "--" << val->m_name
          << " (" << val->toString() << ") \t" << val->m_description;
        o << "\n";
    }
    o << "\n";
}
