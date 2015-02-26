
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



int main(int argc, char *argv[])
{
    BEGIN_TESTING(Class Utils);

    { // unique pointer test //
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

    { // VALGRIND TEST FOR MDS DELETION //
        mds::Float32 *f = new mds::Float32(555.2368);
        mds::deleteData(f);
    }

    { // VALGRIND TEST FOR UNIQUE_PTR MDS DELETION //
        unique_ptr<mds::Float32> f = new mds::Float32(555.2368);
    }


    { // TEST MPL TT IS_CONSTANT //
        TEST0_P( is_const<       float   >::value );
        TEST1_P( is_const< const float   >::value );
        TEST0_P( is_const<       float * >::value );
        TEST1_P( is_const< const float * >::value );
        TEST0_P( is_const<       float & >::value );
        TEST1_P( is_const< const float & >::value );
    }

    { // TEST FOREACH EXPANSION //
        std::vector<MyClass> container;
        for(size_t i=0; i<1; ++i) {
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

    END_TESTING;
}
