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
    struct TreeName;

    static TreeName GetTreeName(std::string str);
    static std::string GetTreePath(const TreeName &tn);

public:
    struct TreeName {
        std::string name;
        std::string server;
        std::string port;
        std::string protocol;

        TreeName() {}
        TreeName(const char *tree_path) { *this = GetTreeName(tree_path); }
        operator std::string () { return GetTreePath(*this); }

    };


    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // NOT USED FOR NOW //

    TestTree() : m_tree(NULL) , m_pulse(0) {}

    TestTree(const char *name) : m_tn(name), m_tree(NULL) , m_pulse(0) {
        // if env take server and port from it //
        if( char * env_path = GetEnvPath(m_tn) ) {
            std::cout << "taking target from env variable: " << env_path << "\n";
            m_tn = env_path;
        }
        SetEnvPath(m_tn);
    }

    ~TestTree() { Close(); }

    void Close() {
        if(m_tree) {            
            delete m_tree;
            m_tree = NULL;
        }
    }

    mds::Tree * Create() {

        // DC connection to create tree //
        mds::Tree * tree = new mds::Tree(m_tn.name.c_str(),-1,"NEW");
        tree->write();
        delete tree;

    }

    int CreatePulse() {

        // DC create pulse //
        unique_ptr<mds::Tree> tree = this->Open(-1);
        tree->createPulse(++m_pulse); // create from model //
        return m_pulse;
    }

    mds::Tree * Open(int shot = 0) {
        return new mds::Tree(m_tn.name.c_str(),shot);
    }

    mds::Tree * Edit(int shot = -1) {
        return new mds::Tree(m_tn.name.c_str(),shot,"EDIT");
    }



    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////




    friend std::ostream &
    operator << (std::ostream &o, const TreeName &tn) {
        return o << GetTreePath(tn);
    }

    static char * GetEnvPath(const TreeName &tn) {
        std::string env_name = std::string(tn.name) + "_path";
        return FileUtils::GetEnv(env_name.c_str());
    }

    static void SetEnvPath(const TreeName &tn) {
        std::string env_name = std::string(tn.name) + "_path";
        FileUtils::SetEnv(env_name.c_str(), GetTreePath(tn).c_str() );
    }

    static void UnsetEnvPath(const TreeName &tn) {
        std::string env_name = std::string(tn.name) + "_path";
        FileUtils::UnsetEnv( env_name.c_str() );
    }


    static mds::Tree * CreateTree(const char *name) {
        // SetEnvPath(name);
        return new mds::Tree(name,-1,"NEW");
    }

    static mds::Tree * OpenTree(const char *name, int shot = 0) {
        // SetEnvPath(name);
        return new mds::Tree(name,shot);
    }

    static mds::Tree * OpenTreeForEdit(const char *name, int shot = 0) {
        // SetEnvPath(name);
        return new mds::Tree(name,shot,"EDIT");
    }

    static std::string GetRootFromPath(const char *tree_name) {
        return std::string("\\") + std::string(tree_name) + "::TOP";
    }

    static mds::TreeNodeArray * PreOrderVisitTree(mds::Tree *tree, const char *path = NULL);

private:
    mds::Tree *m_tree;
    TreeName   m_tn;
    int m_pulse;

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
