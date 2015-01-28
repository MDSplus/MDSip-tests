#ifndef TREEUTILS_H
#define TREEUTILS_H

#include <stdlib.h>

#include "mdsobjects.h"
#include "FileUtils.h"

namespace mds = MDSplus;


///
/// \brief The TreeUtils class
/// Utility for testing MDSip generating a proper tree for tests
class TreeUtils
{
public:
    TreeUtils() {}
    ~TreeUtils() {}

    static void SetEnvPath(const char *name) {
        std::string env_name = std::string(name) + "_path";
        FileUtils::SetEnv(env_name.c_str(),name);
    }

    static mds::Tree * CreateTree(const char *name) {
        FileUtils::CreateDir(name);
        SetEnvPath(name);
        return new mds::Tree(name,-1,"NEW");
    }

    static mds::Tree * OpenTree(const char *name, int shot = 0) {
        SetEnvPath(name);
        return new mds::Tree(name,shot);
    }

    static std::string GetRootFromName(const char *tree_name) {
        return std::string("\\") + std::string(tree_name) + "::TOP";
    }

    static mds::TreeNodeArray * PreOrderVisitTree(mds::Tree *tree, const char *path = NULL);

};


///
/// \brief operator << for TreeNodeArray
///
inline std::ostream &
operator << (std::ostream &o, mds::TreeNodeArray *array) {
    for (int i=0; i<array->getNumNodes(); ++i) {
        o << " nid["
          << array->operator [](i)->getNid()
          << "] - path: "
          << array->operator [](i)->getFullPath()
          << "\n";
    }
    return o;
}



#endif // TREEUTILS_H
