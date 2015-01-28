#ifndef FILEUTILS_H
#define FILEUTILS_H


class FileUtils
{
public:
    static bool FindDir(const char *name, const char *path = ".");
    static void CreateDir(const char *name, const char *path = ".");
    static void SetEnv(const char *name, const char *value);

    void SetFile(char * ciao, int parm);



};

#endif // FILEUTILS_H
