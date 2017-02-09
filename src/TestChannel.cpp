
#include <mdsobjects.h>

#include "SerializeUtils.h"
#include "DataUtils.h"
#include "Threads.h"
#include <unistd.h>
#include "TestChannel.h"


#define MAX_CONNECTION_ATTEMPTS 500
#define WAIT_CONNECTION_USECONDS 20000



using namespace MDSplus;

namespace mdsip_test {


class ChannelImpl {
public:
    ChannelImpl(const Channel *parent) : p(parent), m_nodisk(0) {}
    virtual ~ChannelImpl() {}
    virtual void Open(TestTree &tree) = 0;
    virtual void Close() = 0;
    virtual void PutSegment(Content::Element &el) = 0;

    bool     m_nodisk;
    const Channel *p;
};
        
////////////////////////////////////////////////////////////////////////////////
//  CHANNEL DC  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class ChannelDC : public ChannelImpl {
    typedef ChannelImpl BaseClass;
public:
    ChannelDC(const Channel *parent) :
        BaseClass(parent),
        m_tree(NULL)
    {}

    ~ChannelDC() { Close(); }

    void Open(TestTree &tree) {
        Close();
        tree.Open();
        m_tree = tree.GetMdsTree();
    }

    void Close() {
        if(m_tree) delete m_tree;
        m_tree = NULL;
    }

    void PutSegment(Content::Element &el) /*const*/ {
        TreeNode *node = m_tree->getNode(el.path.c_str());
        node->makeSegment(el.dim->getBegin(), el.dim->getEnding(), el.dim, el.data);
    }
    
private:
    Tree  *m_tree;
};



////////////////////////////////////////////////////////////////////////////////
//  CHANNEL TC  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class ChannelTC : public ChannelImpl {
    typedef ChannelImpl BaseClass;
public:
    ChannelTC(const Channel *parent) :
        BaseClass(parent)
    {}

    void Open(TestTree &tree) {
        m_tree = tree;
        m_tree.Open();
    }

    void Close() {
        m_tree.Close();
    }
    
    void PutSegment(Content::Element &el) /*const*/ {

        Data * args[1];
        args[0] = el.data;

        mds::Connection * cnx = m_tree.GetMdsConnection();
        if(!cnx) {
            std::cout << "error connection\n";
            exit (1);
        }

        if(m_nodisk) {
            // write only into memory simply getting the size of sent array
            cnx->get("size($1)",args,1);
        }
        else {
            // write to disk making segment into parse file
            char * begin = el.dim->getBegin()->getString();
            char * end = el.dim->getEnding()->getString();
            char * delta = el.dim->getDeltaVal()->getString();
            std::stringstream ss;
            // TDI: public fun MakeSegment(as_is _node, in _start, in _end, 
            //          as_is _dim, in _array, optional _idx, in _rows_filled)
            ss << "MakeSegment(" 
               << el.path << "," 
               << begin << ","
               << end << ","
               << "make_range(" << begin << "," << end << "," << delta << ")" << ","
               << "$1" << ",,"
               << el.data->getSize() << ")";            
            cnx->get(ss.str().c_str(),args,1);
            delete[] begin;
            delete[] end;
            delete[] delta;
        }
    }

private:
    //    mds::Connection *m_cnx;
    TestTree m_tree;
    Channel *m_parent;
};


////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Channel::Channel(int size_KB, const ChannelTypeEnum &kind) : 
    m_cnxerr_count(0), 
    m_cnxerr_threshold(MAX_CONNECTION_ATTEMPTS), 
    m_cnxerr_usleep(WAIT_CONNECTION_USECONDS),
    m_size(size_KB),

    m_rate_rx("rate rx",100,0,10),
    m_rate_tx("rate tx",100,0,10),
    m_rate_rx_drop("rx drop",100,0,400),
    m_rate_tx_drop("tx drop",100,0,400),
    m_rate_rx_error("rx error",100,0,400),
    m_rate_tx_error("tx error",100,0,400),
    m_rate_collisions("collisions",100,0,400)

{
    switch (kind) {
    case DC:
        d = new ChannelDC(this);
        break;
    case TC:
    default:
        d = new ChannelTC(this);
        break;
    }
}

Channel::~Channel()
{
    delete d;
}

Channel *Channel::NewTC(int size_KB)
{
    return new Channel(size_KB,Channel::TC);
}

Channel *Channel::NewDC(int size_KB)
{
    return new Channel(size_KB,Channel::DC);    
}



void Channel::Open(TestTree &tree)
{
    for(int count = 0;; ++count, ++m_cnxerr_count) {
        try{ d->Open(tree); break; }
        catch (MdsException &e) {
            std::cerr << " Error opening tree (exception caught: " 
                      << e.what() << ")" << std::endl;
            if(count > m_cnxerr_threshold) { throw e;  }
            usleep(m_cnxerr_usleep);
        }
    }        
}

void Channel::Close()
{
    for(int count = 0;; ++count, ++m_cnxerr_count) {
        try{ d->Close(); break; }
        catch (MdsException &e) {
            std::cerr << " Error closing tree (exception caught: " 
                      << e.what() << ")" << std::endl;
            if(count > m_cnxerr_threshold) { throw e;  }
            usleep(m_cnxerr_usleep);
        }
    }            
}

size_t Channel::Size()
{
    return m_size;
}

void Channel::PutSegment(Content::Element &el) {
    for(int count = 0;; ++count, ++m_cnxerr_count) {
        try{
            {
                TIMER_PAUSE(m_timer);
                m_netlink_stats.Start();
            }
            d->PutSegment(el);
            {
                TIMER_PAUSE(m_timer);
                m_netlink_stats.Stop();
                struct rtnl_link_stats stats = m_netlink_stats.GetDiff();
                double dt = m_netlink_stats.GetTimer().GetElapsed_s();
                m_rate_rx << stats.rx_bytes/dt/1024/1024;
                m_rate_tx << stats.tx_bytes/dt/1024/1024;
                m_rate_rx_drop << stats.rx_dropped;
                m_rate_tx_drop << stats.tx_dropped;
                m_rate_rx_error << stats.rx_errors;
                m_rate_tx_error << stats.tx_errors;
                m_rate_collisions << stats.collisions;
            }
            break;
        }
        catch (MdsException &e) {
            std::cout << " ERROR - Putsegment: " << e.what() << "\n";
            if(count > m_cnxerr_threshold) { throw e;  }
            usleep(m_cnxerr_usleep);
        }
    }                
}

const size_t &Channel::GetErrorsCount() const { return m_cnxerr_count; }

void Channel::Reset()
{
    this->Close();
    m_cnxerr_count = 0;
}

void Channel::SetNoDisk(bool value) { d->m_nodisk = value; }

void Channel::SetInterfaceName(const std::string &name) {
    m_netlink_stats.SetName(name);
}





} // mdsip_test
