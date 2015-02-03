#include <iostream>

#include "TreeUtils.h"

using namespace MDSplus;

TestTree::TreeName TestTree::GetTreeName(const std::string str)
{
    TreeName out;
    out.name = str;
    if(int pos = str.find_last_of("::") != std::string::npos ) {
        out.name = str.substr( pos );
        out.server = str.substr( 0, str.find_first_of(":") );
        out.port = str.substr( str.find_first_of(":")+1, str.find_last_of("::") );
    }
    return out;
}

std::string TestTree::GetTreePath(const TestTree::TreeName &tn)
{

    std::stringstream ss;
    if(!tn.server.empty()) {
        ss << tn.server << ":";
        if(!tn.port.empty())
            ss << tn.port << "::";
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


