#include <iostream>

#include <stdlib.h>
#include <string.h>
#include <dirent.h> // POSIX only //

#include <mdsobjects.h>

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
    // TODO: manage wildchards and search for dir onbly not files
    DIR *dr = opendir(path);
    //    dirent *dren = NULL;

    while ( dirent *dren = readdir(dr) ) {
        //  std::cout << dren->d_name << "\n";
        if( strcmp(dren->d_name,name) == 0 )
            return true;
    }
    return false;
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


