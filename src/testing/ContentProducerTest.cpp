#include "ProducerConsumer.h"
#include "TestContent.h"

#include "Threads.h"




#include "testing-prototype.h"




class ContentProd : public Thread {

public:

    ContentProd(Content *cnt) : m_pool(10), m_content(cnt)  {}

    void InternalThreadEntry() {
        Content::Element el;
        while( m_content->GetNextElement(32,el) )
            m_pool.Push( el );
    }

    bool GetElement(Content::Element &el) {
        if( m_content->GetSize() > 0 || m_pool.Size() > 0 ) {
            el = m_pool.Pop();
            return true;
        }
        return false;
    }

private:
    Pool<Content::Element> m_pool;
    Content *m_content;
};




int main(int argc, char *argv[])
{
    BEGIN_TESTING(Content Producer);

    ContentFunction cnt("sine",1024);
    ContentProd producer(&cnt);
    producer.StartThread();

    std::cout << "consume\n" << std::flush;

    Content::Element el;
    while( producer.GetElement(el) ) {
        std::cout << '.' << std::flush;
    }
    std::cout << " < \n";

    producer.WaitForThreadToExit();


    END_TESTING;
}

