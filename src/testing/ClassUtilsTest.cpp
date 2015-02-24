
#include "ClassUtils.h"

#include "testing-prototype.h"




struct CountDestructors {
    CountDestructors() : m_del(0) {}
    size_t m_del;
};


class MyClass {
public:
    ~MyClass() {
        std::cout << "~MyClass()\n";
        Singleton<CountDestructors> destructor;
        destructor->m_del++;
    }

    float f;
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

    {
        mds::Float32 *f = new mds::Float32(555.2368);
        mds::deleteData(f);
    }
    {
        unique_ptr<mds::Float32> f = new mds::Float32(555.2368);
    }



    END_TESTING;
}

