#ifndef TREEUTILS_H
#define TREEUTILS_H

#include <string>

#include <stdlib.h>

#include "mdsobjects.h"
#include "FileUtils.h"

namespace mds = MDSplus;

namespace mdsip_test {
  

///
/// \brief The TreeUtils class
/// Utility for testing MDSip generating a proper tree for tests
///
class TestTree
{       
public:

    ///
    /// \brief The ClientType enum
    ///
    /// used to change Tree behavior in connection
    ///
    enum ClientType { DC,TC };

    ///
    /// \brief The TreePath
    ///
    /// struct TreePath is used within the TestTree class to parse the syntax
    /// of tree back and forth
    ///
    struct TreePath {
        std::string path;
        std::string server;
        std::string port;
        std::string protocol;
        std::string userid;

        TreePath() {}
        TreePath(const char *tree_path);

        operator std::string () { return toString(*this); }
        operator bool () { return !path.empty(); }

        static TreePath getTreePath(std::string str);
        static std::string toString(const TreePath &tn);
    };

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    TestTree() : m_tree(0), m_cnx(0), m_client(TC) {}

    TestTree(const char *name, const char *path = NULL, const ClientType cl=DC);

    TestTree(const TestTree &other);

    ~TestTree();

    TestTree & operator = (const TestTree &other);

    void Create();

    void Open(int shot = 0);

    void OpenEdit(int shot = -1);

    void OpenRead(int shot = -1);

    void Close();

    void CreatePulse(int pulse);

    void SetCurrentPulse(int pulse);

    int GetCurrentPulse();

    void AddNode(const char *name, const char *usage);

    void SetClientType(const ClientType cl);
    const ClientType GetClientType() const;

    TreePath & Path() { return m_path; }
    const TreePath & Path() const { return m_path; }

    std::string & Name() { return m_name; }
    const std::string & Name() const { return m_name; }

    mds::Tree * GetMdsTree() { return m_tree; }

    mds::Connection * GetMdsConnection() { return m_cnx; }

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
    unique_ptr<mds::Tree> m_tree;
    unique_ptr<mds::Connection> m_cnx;
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











} // mdsip_test

#endif // TREEUTILS_H
