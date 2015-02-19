#include <iostream>
#include <cstring>
// #include <regex>


#include "TreeUtils.h"

using namespace MDSplus;


static bool is_integer(const std::string & s){
    //return std::regex_match(s, std::regex("[(-|+)|][0-9]+"));
    return( std::strspn( s.c_str(), "0123456789" ) == s.size() );
}


TestTree::TreeName TestTree::GetTreeName(std::string str)
{
    TreeName out; 
    int pos = str.rfind("::");
    if( pos != std::string::npos ) {
        out.name = str.substr( pos+2 );
        str = str.substr(0, pos);

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
    }
    else {
        out.name = str;
    }

    return out;
}

std::string TestTree::GetTreePath(const TestTree::TreeName &tn)
{
    std::stringstream ss;
    if(!tn.server.empty()) {
        if(!tn.protocol.empty())
            ss << tn.protocol << "://";
        ss << tn.server;
        if(!tn.port.empty())
            ss  << ":" << tn.port;
        ss << "::";
    }
    ss << tn.name;
    return ss.str();
}



TreeNodeArray * TestTree::PreOrderVisitTree(Tree *tree, const char *path)
{
    if(path)
        tree->setDefault( tree->getNode( path ) );
    TreeNodeArray * ar = tree->getNodeWild("***");
    return ar;
}


