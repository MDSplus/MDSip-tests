
#include <time.h>
#include <unistd.h>
#include <stdlib.h>

#include "ClassUtils.h"
#include "Threads.h"
#include "testing-prototype.h"

namespace mds = MDSplus;
using namespace mdsip_test;

static Lockable l;
static WaitSubscriptions w;

class ThreadTest : public Thread {

public:
    ThreadTest(const ThreadTest &other) : m_id(other.m_id+1) {
        std::cout << " -- COPY -- \n" << std::flush;
    }

    ThreadTest &operator = (const ThreadTest &other) {
        this->m_id = other.m_id+1;
        return *this;
    }

    ThreadTest() : m_id(0) {}
    ThreadTest(int id) : m_id(id) {}

    void InternalThreadEntry() {
        int n = (rand()%200) * 10000;
        usleep( n );        
        {
            MDS_LOCK_SCOPE(l);
            std::cout << "Just run thread: " << m_id << " for " << n << "us \n";
        }
//        w.Subscribe();
        {
            MDS_LOCK_SCOPE(l);
            std::cout << "Got ok in thread: " << m_id << " \n";
        }
    }

    void InternalThreadExit() {
        std::cout << "EXIT FUNCTION\n";
    }

private:

    size_t m_id;
};


static void handler(int sig, siginfo_t *si, void *args) {
    printf("Got SIG %d at address: 0x%lx\n", sig, (long) si->si_addr);
    pthread_exit(0);
}


int main(int argc, char *argv[])
{
    BEGIN_TESTING(Threads Utils);

    srand(time(NULL));

    ThreadTest t1(1),t2(2),t3(3);
    ThreadTest t4;
    t4 = t3;

    w = WaitSubscriptions(4);

    t3.SetSigAction(SIGTERM,handler);
    t4.SetSigAction(SIGTERM,handler);

    t1.StartThread();
    t2.StartThread();
    t3.StartThread();
    t4.StartThread();

    usleep(1000);
    t3.SendSignal(SIGTERM);
    t4.SendSignal(SIGTERM);

    t1.WaitForThreadToExit();
    t2.WaitForThreadToExit();
    t3.WaitForThreadToExit();
    t4.WaitForThreadToExit();



    END_TESTING;
}
