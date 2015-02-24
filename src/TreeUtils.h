#ifndef TREEUTILS_H
#define TREEUTILS_H

#include <string>

#include <stdlib.h>

#include "mdsobjects.h"
#include "FileUtils.h"

namespace mds = MDSplus;


///
/// \brief The TreeUtils class
/// Utility for testing MDSip generating a proper tree for tests
class TestTree
{       


public:


    struct TreePath {
        std::string path;
        std::string server;
        std::string port;
        std::string protocol;

        TreePath() {}
        TreePath(const char *tree_path) {
            if(tree_path) *this = getTreePath(tree_path);
        }
        operator std::string () { return toString(*this); }

        operator bool () { return !path.empty(); }

        static TreePath getTreePath(std::string str);
        static std::string toString(const TreePath &tn);
    };

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    enum ClientType { DC,TC };


    TestTree() {}

    TestTree(const char *name, const char *path = NULL, const ClientType cl=DC);

    void Create();

    mds::Tree * Open(int shot = 0) {
        return new mds::Tree(m_name.c_str(),shot);
    }

    mds::Tree * Edit(int shot = -1) {
        return  new mds::Tree(m_name.c_str(),shot,"EDIT");
    }

    void SetClientType(const ClientType cl) { m_client = cl; }

    void CreatePulse(int pulse);

    void SetCurrentPulse(int pulse);

    int GetCurrentPulse() {
        unique_ptr<mds::Tree> tree = this->Open();
        return tree->getCurrent(m_name.c_str());
    }

    void AddNode(const char *name, const char *usage);

    TreePath & Path() { return m_path; }
    const TreePath & Path() const { return m_path; }

    std::string & Name() { return m_name; }
    const std::string & Name() const { return m_name; }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////


    friend std::ostream &
    operator << (std::ostream &o, const TreePath &tn) {
        return o << TreePath::toString(tn);
    }

    /// \return NULL if path doesn't exist
    static char * GetEnvPath(const char *name) {
        std::string env_name = std::string(name) + "_path";
        return FileUtils::GetEnv(env_name.c_str());
    }

    static void SetEnvPath(const char *name, const TreePath &tn) {
        std::string env_name = std::string(name) + "_path";
        FileUtils::SetEnv(env_name.c_str(), TreePath::toString(tn).c_str() );
    }

    static void UnsetEnvPath(const char *name) {
        std::string env_name = std::string(name) + "_path";
        FileUtils::UnsetEnv( env_name.c_str() );
    }

    static std::string GetRootFromPath(const char *tree_name) {
        return std::string("\\") + std::string(tree_name) + "::TOP";
    }

    static mds::TreeNodeArray * PreOrderVisitTree(mds::Tree *tree, const char *path = NULL);    

private:
    ClientType  m_client;
    std::string m_name;
    TreePath    m_path;

};


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
