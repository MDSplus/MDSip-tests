#include <iostream>

#include "TreeUtils.h"

using namespace MDSplus;

TreeNodeArray * TreeUtils::PreOrderVisitTree(Tree *tree, const char *path)
{
    if(path)
        tree->setDefault( tree->getNode( path ) );

    TreeNodeArray * ar = tree->getNodeWild("***");
    return ar;
}
