
#include "ClassUtils.h"
#include "TreeUtils.h"
#include "testing-prototype.h"


namespace mds = MDSplus;


//class TreeConnection {

//    typedef TestTree::TreeName TreeName;

//public:

//    enum ClientModel {
//        DC, TC
//    };

//    TreeConnection() {}

//    unique_ptr<mds::Tree> Create(const TreeName &conn) {
//        m_name = conn;
//        SetEnvPath(m_tn);

//        mds::Tree * tree;
//        try {
//            tree = new mds::Tree(m_tn.name.c_str(),-1,"NEW");
//            tree->write();
//        }
//        return *tree;
//    }



//private:
//    TreeName m_name;
//};



int main(int argc, char *argv[])
{
    BEGIN_TESTING(Tree Utils);




    END_TESTING;
}

