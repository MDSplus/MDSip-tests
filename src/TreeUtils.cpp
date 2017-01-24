#include <iostream>
#include <string>
#include <cstring>
// #include <regex>


#include "TreeUtils.h"

using namespace MDSplus;

namespace mdsip_test {
  

////////////////////////////////////////////////////////////////////////////////
//  TREE PATH  /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


static bool is_unsigned_integer(const std::string & s){
    //return std::regex_match(s, std::regex("[(-|+)|][0-9]+"));
    return( std::strspn( s.c_str(), "0123456789" ) == s.size() );
}

TestTree::TreePath::TreePath(const char *tree_path) {
    if(tree_path) *this = getTreePath(tree_path);
}

///
/// \brief TestTree::TreePath::getTreePath
/// \param str the input string to parse tree path from
/// \return TreePath structure filled
///
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

    // find userid //
    pos = str.find("@");
    if( pos != std::string::npos ) {
        out.userid = str.substr(0,pos);
        str = str.substr(pos+1);
    }

    // find port //
    pos = str.rfind(":");
    if( pos != std::string::npos ) {
        std::string item = str.substr( pos+1 );
        if(is_unsigned_integer(item)) { out.port = item; }
        str = str.substr(0,pos);
    }

    out.server = str;
    return out;
}

///
/// \brief TestTree::TreePath::toString
/// \param tn tree Structure in
/// \return tree structure converted to string
///
std::string TestTree::TreePath::toString(const TestTree::TreePath &tn)
{
    std::stringstream ss;

    if(!tn.server.empty()) {
        if(!tn.protocol.empty())
            ss << tn.protocol << "://";
        if(!tn.userid.empty() && tn.protocol == "ssh")
            ss << tn.userid << "@";
            ss << tn.server;
        if(!tn.port.empty() && tn.protocol != "ssh")
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
    if(m_client == TC) {
        // setup connection //
        m_cnx = new mds::Connection((char *)TreePath::toString(m_path).c_str());
    }
}

TestTree::TestTree(const TestTree &other) :
    m_client(other.m_client),
    m_name(other.m_name),
    m_path(other.m_path),
    m_tree(0),
    m_cnx(0)
{
    //    std::cout << "OPEN COPY CONSTRUCTOR\n";
    if(m_client == TC) {
        m_cnx = new mds::Connection((char *)TreePath::toString(m_path).c_str());
    }
}

TestTree::~TestTree()
{
    this->Close();
}

TestTree &TestTree::operator =(const TestTree &other)
{
    this->m_client = other.m_client;
    this->m_name = other.m_name;
    this->m_path = other.m_path;

    if(other.m_cnx)
        m_cnx = new mds::Connection((char *)TreePath::toString(m_path).c_str());
}



void TestTree::Create()
{
    switch (m_client) {
    case DC:
    {
        m_tree = new mds::Tree(m_name.c_str(),-1,"NEW");
        m_tree->write();
    }
        break;
    case TC:
    {
        mds::Data * args[1];
        args[0] = new mds::String(m_name.c_str());
        m_cnx->get(
                    "write(*,' ------ CREATE TREE  ---------');"

                    "  _status = TreeOpenNew($1,-1);"
                    "  _status = TreeShr->TreeWriteTree($1,val(-1));"
//                    "  _status = TreeClose($1,-1);"

                    ,args,1);
        mds::deleteData(args[0]);
    }
        break;
    }
}

void TestTree::Open(int shot) {
    switch (m_client) {
    case mdsip_test::TestTree::DC:
        m_tree = new mds::Tree(m_name.c_str(),shot);
        break;
    case mdsip_test::TestTree::TC:
        // m_cnx->closeAllTrees();
        m_cnx->openTree((char *)m_name.c_str(),shot);
        break;
    }
}

void TestTree::OpenEdit(int shot) {
    switch (m_client) {
    case mdsip_test::TestTree::DC:
        m_tree = new mds::Tree(m_name.c_str(),shot,"EDIT");
        break;
    case mdsip_test::TestTree::TC:
        mds::Data * args[1];
        args[0] = new mds::String(m_name.c_str());
        m_cnx->get(
                    " _status = TreeClose();"
                    " _status = TreeOpenEdit($1,-1);"
                    ,args,1);
        mds::deleteData(args[0]);
        break;
    }
}

//public fun TreeOpenEdit(in _tree, in _shot)
//{
//  return(TreeShr->TreeOpenEdit(ref(_tree//"\0"),val(_shot)));
//}
void TestTree::OpenRead(int shot) {
    switch (m_client) {
    case mdsip_test::TestTree::DC:
        m_tree = new mds::Tree(m_name.c_str(),shot,"READONLY");
        break;
    case mdsip_test::TestTree::TC:
        mds::Data * args[2];
        args[0] = new mds::String(m_name.c_str());
        args[1] = new mds::Int32(shot);
        m_cnx->get(
                    " _status = TreeClose(); "
                    " _status = TreeShr->TreeOpen($1,val($2));"
                    ,args,2);
        mds::deleteData(args[0]);
        mds::deleteData(args[1]);
        break;
    }
}

void TestTree::Close() {
    switch (m_client) {
    case mdsip_test::TestTree::DC:
        break;
    case mdsip_test::TestTree::TC:
        //        m_cnx->get( " _status = TreeClose(); " ,0,0);
        break;
    }
}

void TestTree::CreatePulse(int pulse)
{
    switch (m_client) {
    case TestTree::DC:
    {
        this->Open(-1);
        m_tree->createPulse(pulse); // create from model //
    }
        break;
    case TestTree::TC:
    {
        //        m_cnx->closeAllTrees();
        //        m_cnx->openTree((char *)m_name.c_str(),-1);
        this->Open(-1);
        mds::Data * args[1];
        args[0] = new mds::Int32(pulse);
        unique_ptr<Data> ans = m_cnx->get(
                    "_nids = 0;"
                    "_status = TreeCreatePulseFile($1,_nids,0);"
                    "_status"
                    ,args,1);

        if(int st = ans->getInt() & 1 == 0) {
            std::cout << "ERROR: CreatePulse res-> " << MdsGetMsg(ans->getInt()) << "\n";
            mds::deleteData(args[0]);
            throw mds::MdsException( MdsGetMsg(ans->getInt()) );
        }
        mds::deleteData(args[0]);
    }
        break;
    }
}

void TestTree::SetCurrentPulse(int pulse)
{
    switch (m_client) {
    case TestTree::DC:
    {
        this->Open(pulse);
        m_tree->setCurrent(m_name.c_str(),pulse);
    }
        break;
    case TestTree::TC:
    {
        mds::Data * args[2];
        args[0] = new mds::String(m_name.c_str());
        args[1] = new mds::Int32(pulse);
        m_cnx->get("TreeSetCurrentShot($1,$2)",args,2);
        mds::deleteData(args[0]);
        mds::deleteData(args[1]);
    }
        break;
    }
}

int TestTree::GetCurrentPulse() {
    switch(m_client) {
    case mdsip_test::TestTree::DC:
        return m_tree->getCurrent(m_name.c_str());
        break;
    case mdsip_test::TestTree::TC:
        mds::Data * args[2];
        args[0] = new mds::String(m_name.c_str());
        unique_ptr<Data> ans = m_cnx->get("TreeGetCurrentShot($1)",args,1);
        mds::deleteData(args[0]);
        return ans->getInt();
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
        if(m_tree) {
            m_tree->addNode((char*)name,(char*)usage);
            m_tree->write();
        }
    }
        break;
    case TestTree::TC:
    {
        mds::Data * args[3];
        args[0] = new mds::String(m_name.c_str());
        args[1] = new mds::String(name);
        args[2] = new mds::Int8(convertUsage(std::string(usage)));
        m_cnx->get(
                    "write(*, 'Add node to tree: ',$1);"
                    "_status = TreeOpenEdit($1,-1);"

                    "_nid = 0;"
                    "_status = TreeShr->TreeAddNode($2,ref(_nid),val($3));"
                    "_status = TreeShr->TreeWriteTree($1,val(-1));"
//                    "TreeClose($1,-1);"
                    ,args,3);
        mds::deleteData(args[0]);
        mds::deleteData(args[1]);
        mds::deleteData(args[2]);
    }
        break;
    }
}

void TestTree::SetClientType(const TestTree::ClientType cl) {
    if(cl == DC) {
        if(m_path.path.empty()) m_path.path = " "; // trick //
        std::cout << "setting env: " << m_name << " -> " << TreePath::toString(m_path) <<"\n";
        SetEnvPath(m_name.c_str(),TreePath::toString(m_path).c_str());
    }
    m_client = cl;
}

const TestTree::ClientType TestTree::GetClientType() const { return m_client; }

TreeNodeArray * TestTree::PreOrderVisitTree(Tree *tree, const char *path)
{
    if(path)
        tree->setDefault( tree->getNode( path ) );
    TreeNodeArray * ar = tree->getNodeWild("***");
    return ar;
}

} // mdsip_test


















