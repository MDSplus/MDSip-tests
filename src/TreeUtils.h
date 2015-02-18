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

    static TreeName GetTreeName(const std::string str);
    static std::string GetTreePath(const TreeName &tn);

public:
    struct TreeName {
        std::string name;
        std::string server;
        std::string port;

        TreeName() {}
        TreeName(const char *tree_path) { *this = GetTreeName(tree_path); }
        operator std::string() { return GetTreePath(*this); }
    };


    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // NOT USED FOR NOW //

    TestTree() : m_tree(NULL) , m_pulse(0) {}

    ~TestTree() { Close(); }

    void Close() {
        if(m_tree) {
            UnsetEnvPath(m_tn);
            delete m_tree;
            m_tree = NULL;
        }
    }

//    bool CreateDC(const TreeName &tn) {
//        m_tn = tn;
//        SetEnvPath(m_tn);
//        m_tree = new mds::Tree(m_tn.name.c_str(),-1,"NEW");

//        m_tree->write();
//        delete m_tree;
//        m_tree = NULL;
//    }

//    bool Create(const char *tree_path) {
//        return this->Create(GetTreeName(tree_path));
//    }

//    int CreatePulse() {
//        if(!m_tree) return false;
//        else { m_tree->createPulse(m_pulse++); }
//    }

//    bool Open(const TreeName &tn, int shot = 1) {
//        if(m_tree) Close();

//        Create(tn);
//        try {
//            m_tree = new mds::Tree(tn.name.c_str(),shot);
//            m_tn = tn;
//        } catch (mds::MdsException e) {
//            // try to create and recursively open //
//            if(! Create(tn) ) return false;
//            else return Open(tn);
//        }
//        m_pulse = shot;
//        return true;
//    }

//    bool Open(const char *tree_path, int shot = 1) {
//        return this->Open(GetTreeName(tree_path),shot);
//    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

private:
    mds::Tree *m_tree;
    TreeName   m_tn;
    int m_pulse;




public:

    friend std::ostream &
    operator << (std::ostream &o, const TreeName &tn) {
        return o << GetTreePath(tn);
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

    static std::string GetRootFromName(const char *tree_name) {
        return std::string("\\") + std::string(tree_name) + "::TOP";
    }


    static mds::TreeNodeArray * PreOrderVisitTree(mds::Tree *tree, const char *path = NULL);


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
