
#include "DataUtils.h"
#include "testing-prototype.h"


int main(int argc, char *argv[])
{
    BEGIN_TESTING(Data Utils);

    { // TEST TUPLE FLOAT //
        Vector4f v4f;
        TEST1_P( AreSame<float>(v4f(0),0) );
        TEST1_P( AreSame<float>(v4f(1),0) );
        TEST1_P( AreSame<float>(v4f(2),0) );
        TEST1_P( AreSame<float>(v4f(3),0) );

        v4f << 0,1,2,3;
        TEST1_P( AreSame<float>(v4f(0),0) );
        TEST1_P( AreSame<float>(v4f(1),1) );
        TEST1_P( AreSame<float>(v4f(2),2) );
        TEST1_P( AreSame<float>(v4f(3),3) );
    }

    END_TESTING;
}

