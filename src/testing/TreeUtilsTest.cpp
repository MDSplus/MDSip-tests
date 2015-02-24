
#include "ClassUtils.h"
#include "TreeUtils.h"
#include "testing-prototype.h"


namespace mds = MDSplus;





int main(int argc, char *argv[])
{
    BEGIN_TESTING(Tree Utils);


    { // TEST STRING PARSING //
        TestTree::TreePath tn;

        tn = "server";
        TEST1( tn.path == "" );
        TEST1( tn.server == "server" );
        std::cout << tn << "\n";

        tn = "server::my_path";
        TEST1( tn.path == "my_path" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "" );
        TEST1( tn.protocol == "" );
        std::cout << tn << "\n";

        tn = "server:8000::my_path";
        TEST1( tn.path == "my_path" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "8000" );
        TEST1( tn.protocol == "" );
        std::cout << tn << "\n";

        tn = "tcp://server:8000::my_path";
        TEST1( tn.path == "my_path" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "8000" );
        TEST1( tn.protocol == "tcp" );
        std::cout << tn << "\n";

        tn = "tcp://server::my_path";
        TEST1( tn.path == "my_path" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "" );
        TEST1( tn.protocol == "tcp" );
        std::cout << tn << "\n";

        tn = "server:8000";
        TEST1( tn.path == "" );
        TEST1( tn.server == "server" );
        TEST1( tn.port == "8000" );
        TEST1( tn.protocol == "" );
        std::cout << tn << "\n";
    }

    if(0){
        // CREATE AND POPULATE TREE //

        TestTree tree("testing_tree","udt://localhost:8000",TestTree::TC);
        tree.Create();
        tree.AddNode("sig01","SIGNAL");
        tree.CreatePulse(1);
    }



    END_TESTING;
}

