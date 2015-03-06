#include <iostream>
#include <cstring>
// #include <regex>


#include "TreeUtils.h"

using namespace MDSplus;

////////////////////////////////////////////////////////////////////////////////
//  TREE PATH  /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


static bool is_integer(const std::string & s){
    //return std::regex_match(s, std::regex("[(-|+)|][0-9]+"));
    return( std::strspn( s.c_str(), "0123456789" ) == s.size() );
}

TestTree::TreePath TestTree::TreePath::getTreePath(std::string str)
{
    TreePath out;
    int pos = str.rfind("::");
    if( pos != std::string::npos ) {
        out.path = str.substr( pos+2 );
        str = str.substr(0, pos);
    }

    // find protocol //
    pos = str.find("://");
    if( pos != std::string::npos ) {
        out.protocol = str.substr(0,pos);
        str = str.substr(pos+3);
    }

    // find port //
    pos = str.rfind(":");
    if( pos != std::string::npos ) {
        std::string item = str.substr( pos+1 );
        if(is_integer(item)) { out.port = item; }
        str = str.substr(0,pos);
    }
    out.server = str;

    return out;
}


std::string TestTree::TreePath::toString(const TestTree::TreePath &tn)
{
    std::stringstream ss;
    if(!tn.server.empty()) {
        if(!tn.protocol.empty())
            ss << tn.protocol << "://";
        ss << tn.server;
        if(!tn.port.empty())
            ss  << ":" << tn.port;
    }
    if(!tn.path.empty()) {
        ss << "::";
        ss << tn.path;
    }
    return ss.str();
}




////////////////////////////////////////////////////////////////////////////////
//  TestTree  //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



TestTree::TestTree(const char *name, const char *path, const TestTree::ClientType cl) :
    m_client(cl),
    m_name(name),
    m_path(path)
{
    if(m_path.path.empty()) m_client = TC;
//    else if(m_path.server.empty()) {
//        // only path DC local connection //
//        SetEnvPath(name,m_path.path.c_str());
//    }
//    else { // server and path DC connection //
//        TreePath path = m_path;
//        path.protocol.clear();
//        SetEnvPath(name,path);
//    }
}


void TestTree::Create()
{
    switch (m_client) {
    case DC:
    {
        unique_ptr<mds::Tree> tree = new mds::Tree(m_name.c_str(),-1,"NEW");
        tree->write();
    }
        break;
    case TC:
    {
        // TODO: only tcp allowed .. fix MDSConnection
        TreePath path = m_path; path.protocol.clear(); // tcp

        mds::Connection cnx((char *)TreePath::toString(path).c_str());
        //cnx.openTree((char *)m_name.c_str(),-1);
        mds::Data * args[1];
        args[0] = new mds::String(m_name.c_str());
        cnx.get(
                    "write(*,' ------ CREATE TREE  ---------');"

                    "  _status = TreeOpenNew($1,-1);"
                    "  _status = TreeShr->TreeWriteTree($1,val(-1));"
                    "  _status = TreeClose($1,-1);"

                    ,args,1);

        mds::deleteData(args[0]);
    }
        break;
    }
}

void TestTree::CreatePulse(int pulse)
{
    switch (m_client) {
    case TestTree::DC:
    {
        // DC create pulse //
        unique_ptr<mds::Tree> tree = this->Open(-1);
        tree->createPulse(pulse); // create from model //
    }
        break;
    case TestTree::TC:
    {
        // TODO: only tcp allowed .. fix MDSConnection
        TreePath path = m_path; path.protocol.clear(); // tcp

        mds::Connection cnx((char *)TreePath::toString(path).c_str());
        cnx.openTree((char *)m_name.c_str(),-1);
        mds::Data * args[1];
        args[0] = new mds::Int32(pulse);
        cnx.get(
                    "_nids = 0;"
                    "_status = TreeCreatePulseFile($1,_nids,0);"
                    ,args,1);
        mds::deleteData(args[0]);
        cnx.closeAllTrees();
    }
        break;
    }
}

void TestTree::SetCurrentPulse(int pulse)
{
    switch (m_client) {
    case TestTree::DC:
    {
        unique_ptr<mds::Tree> tree = this->Open(pulse);
        if(tree) tree->setCurrent(m_name.c_str(),pulse);
    }
        break;
    case TestTree::TC:
    {
        // TODO: only tcp allowed .. fix MDSConnection
        TreePath path = m_path; path.protocol.clear(); // tcp

        mds::Connection cnx((char *)TreePath::toString(path).c_str());
        cnx.openTree((char *)m_name.c_str(),-1);
        mds::Data * args[2];
        args[0] = new mds::String(m_name.c_str());
        args[1] = new mds::Int32(pulse);
        cnx.get("TreeSetCurrentShot($1,$2)",args,2);
        mds::deleteData(args[0]);
        mds::deleteData(args[1]);
        cnx.closeAllTrees();
    }
        break;
    }
}


static int convertUsage(std::string const & usage)
{
    if (usage == "ACTION")
        return TreeUSAGE_ACTION;
    else if (usage == "ANY")
        return TreeUSAGE_ANY;
    else if (usage == "AXIS")
        return TreeUSAGE_AXIS;
    else if (usage == "COMPOUND_DATA")
        return TreeUSAGE_COMPOUND_DATA;
    else if (usage == "DEVICE")
        return TreeUSAGE_DEVICE;
    else if (usage == "DISPATCH")
        return TreeUSAGE_DISPATCH;
    else if (usage == "STRUCTURE")
        return TreeUSAGE_STRUCTURE;
    else if (usage == "NUMERIC")
        return TreeUSAGE_NUMERIC;
    else if (usage == "SIGNAL")
        return TreeUSAGE_SIGNAL;
    else if (usage == "SUBTREE")
        return TreeUSAGE_SUBTREE;
    else if (usage == "TASK")
        return TreeUSAGE_TASK;
    else if (usage == "TEXT")
        return TreeUSAGE_TEXT;
    else if (usage == "WINDOW")
        return TreeUSAGE_WINDOW;
    else
        return TreeUSAGE_ANY;
}

void TestTree::AddNode(const char *name, const char *usage)
{
    switch (m_client) {
    case TestTree::DC:
    {
        unique_ptr<mds::Tree> tree = this->Edit();
        if(tree) {
            tree->addNode((char*)name,(char*)usage);
            tree->write();
        }

    }
        break;
    case TestTree::TC:
    {
        // TODO: only tcp allowed .. fix MDSConnection
        TreePath path = m_path; path.protocol.clear(); // tcp

        mds::Connection cnx((char *)TreePath::toString(path).c_str());
        mds::Data * args[3];
        args[0] = new mds::String(m_name.c_str());
        args[1] = new mds::String(name);
        args[2] = new mds::Int8(convertUsage(std::string(usage)));
        cnx.get(
                    "write(*, 'Add node to tree: ',$1);"
                    "_status = TreeOpenEdit($1,-1);"

                    "_nid = 0;"
                    "_status = TreeShr->TreeAddNode($2,ref(_nid),val($3));"
                    "_status = TreeShr->TreeWriteTree($1,val(-1));"
                    "TreeClose($1,-1);"
                    ,args,3);

        mds::deleteData(args[0]);
        mds::deleteData(args[1]);
        mds::deleteData(args[2]);
    }
        break;
    }
}





TreeNodeArray * TestTree::PreOrderVisitTree(Tree *tree, const char *path)
{
    if(path)
        tree->setDefault( tree->getNode( path ) );
    TreeNodeArray * ar = tree->getNodeWild("***");
    return ar;
}






















