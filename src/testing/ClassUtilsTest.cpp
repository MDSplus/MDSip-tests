
#include "ClassUtils.h"
#include "testing-prototype.h"


struct CountDestructors {
    CountDestructors() : m_del(0) {}
    size_t m_del;
};


class MyClass {
public:
    ~MyClass() {
        Singleton<CountDestructors> destructor;
        destructor->m_del++;
    }

    float f;
    int i;
};


// FLAGS //

enum _MyFlags
{
    F1 = 1 << 0,
    F2 = 1 << 2,
    F3 = 1 << 3
};
typedef Flags<enum _MyFlags> MyFlags;
DEFINE_OPERATORS_FOR_FLAGS(MyFlags)





int main(int argc, char *argv[])
{
    BEGIN_TESTING(Class Utils);

    ////////////////////////////////////////////////////////////////////////////////
    //  Comma init for containers  /////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    {
        std::vector<float> vf;
        vf << (float)1,2,3,4,5,6,7,8,9,555.2368;
        TEST1_P( vf[0] == 1 );
        TEST1_P( vf[1] == 2 );
        TEST1_P( AreSame(vf[9],(float)555.2368) );
    }


    ////////////////////////////////////////////////////////////////////////////////
    //  unique_ptr  ////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    {
        unique_ptr<MyClass> ptr(new MyClass);
        unique_ptr<MyClass> ptr2 = new MyClass;
        unique_ptr<MyClass> ptr3;
        ptr3 = new MyClass;
        ptr3 = new MyClass;

        unique_ptr<MyClass> ptr4 = ptr3;
        unique_ptr<MyClass> ptr5(ptr4);
        (void)ptr5;
    }
    TEST1(Singleton<CountDestructors>::get_const_instance().m_del == 4);

    ////////////////////////////////////////////////////////////////////////////////
    //  // VALGRIND TEST FOR MDS DELETION //  //////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    {
        mds::Float32 *f = new mds::Float32(555.2368);
        mds::deleteData(f);
    }

    {
        unique_ptr<mds::Float32> f = new mds::Float32(555.2368);
    }

    ////////////////////////////////////////////////////////////////////////////////
    //  // TEST MPL TT IS_CONSTANT //  /////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    {
        TEST0_P( is_const<       float   >::value );
        TEST1_P( is_const< const float   >::value );
        TEST0_P( is_const<       float * >::value );
        TEST1_P( is_const< const float * >::value );
        TEST0_P( is_const<       float & >::value );
        TEST1_P( is_const< const float & >::value );
    }

    ////////////////////////////////////////////////////////////////////////////////
    //  // TEST FOREACH EXPANSION //  //////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    {
        std::vector<MyClass> container;
        for(size_t i=0; i<10; ++i) {
            container.push_back(MyClass());
            container.back().f = 555.2368;
            container.back().i = i;
        }

        foreach (MyClass &el, container) {
            static int count = 0;
            TEST1( AreSame<float>(el.f,555.2368) );
            TEST1( el.i == count++ );
        }

        foreach (const MyClass &el, container) {
            static int count = 0;
            TEST1( AreSame<float>(el.f,555.2368) );
            TEST1( el.i == count++ );
        }

        std::vector<MyClass> &cntref = container;
        foreach (MyClass &el, cntref) {
            static int count = 0;
            TEST1( AreSame<float>(el.f,555.2368) );
            TEST1( el.i == count++ );
        }

        std::vector<MyClass> *cntptr = &container;
        foreach (MyClass &el, *cntptr) {
            static int count = 0;
            TEST1( AreSame<float>(el.f,555.2368) );
            TEST1( el.i == count++ );
        }

        const std::vector<MyClass> &const_cntptr = container;
        foreach (const MyClass &el, const_cntptr) {
            static int count = 0;
            TEST1( AreSame<float>(el.f,555.2368) );
            TEST1( el.i == count++ );
        }
    }


    ////////////////////////////////////////////////////////////////////////////////
    //  FLAGS  /////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    {
        MyFlags f;
        f = F1 | F2;
        TEST1_P(f.testFlag(F1));
        TEST1_P(f.testFlag(F2));
        TEST0_P(f.testFlag(F3));
    }

    END_TESTING;
}

