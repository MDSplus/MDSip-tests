#include <iostream>
#include <fstream>
#include <time.h>

#include "SerializeUtils.h"
#include "FileUtils.h"
#include "DataUtils.h"

#include "testing-prototype.h"


////////////////////////////////////////////////////////////////////////////////
//  TEST SERIALIZATION  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

struct MyObj {
    float i;
    float f[2];
    Vector2f p;
    std::string str;
    MyObj *next;

    MyObj() : next(0) {}

    friend std::ostream &
    operator << (std::ostream &o, const MyObj &ob) {
        o << "i:" << ob.i << " "
          << "f[0]:" << ob.f[0] << " "
          << "f[1]:" << ob.f[1] << " "
          << "p:" << ob.p << " "
          << "str:" << ob.str << " "
          << "next:" << ob.next;
        return o;
    }

};

template < class Archive >
void  serialize(Archive &ar, MyObj &ob) {
    ar & ob.i;
    ar & ob.f;
    ar & ob.p;
    ar & ob.str;
    ar & ob.next;
}


int main(int argc, char *argv[])
{
    BEGIN_TESTING(Serialize To Bin);


    MyObj ob;
    ob.i = 368;
    ob.f[0] = 1.23;
    ob.f[1] = 4.56;
    ob.p << 55,2368;
    ob.str = "ciao";

    MyObj ob2 = ob;
    ob.next = &ob2;
    ob2.str = "ciao2";

    SerializeToBin sr;
    sr.Write() & ob;
    sr.Store();

    ob.i = 0;
    ob.f[0] = 0;
    ob.f[1] = 0;
    ob.p << 0,0;
    ob.str = "no";

    ob2.i = 0;
    ob2.f[0] = 0;
    ob2.f[1] = 0;
    ob2.p << 0,0;
    ob2.str = "no";

    sr.Read() & ob;

    std::cout << ob << "\n";
    std::cout << ob2 << "\n";

    TEST1(ob.i == 368);
    TEST1( AreSame<float>(ob.f[0] , 1.23) );
    TEST1( AreSame<float>(ob.f[1] , 4.56) );
    TEST1(ob.p(0) == 55 && ob.p(1) == 2368);
    TEST1(ob.str == "ciao");

    TEST1(ob2.i == 368);
    TEST1( AreSame<float>(ob2.f[0] , 1.23) );
    TEST1( AreSame<float>(ob2.f[1] , 4.56) );
    TEST1(ob2.p(0) == 55 && ob.p(1) == 2368);
    TEST1(ob2.str == "ciao2");

    END_TESTING;
}


