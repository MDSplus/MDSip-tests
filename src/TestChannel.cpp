
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
        m_tree = tree.Open();
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
        BaseClass(parent),
        m_cnx(NULL)
    {}

    void Open(TestTree &tree) {
        if(m_cnx) Close();
        std::string cnx_path = TestTree::TreePath::toString(tree.Path());

        ////////////////////////////////////////////////////////////////////////
        // added to support ssh connection /////////////////////////////////////
        if(std::string("ssh") == tree.Path().protocol) {
            // force tcp to get env variable via TDI //
            TestTree::TreePath tcp = tree.Path();
            tcp.protocol = "tcp";
            m_cnx = new mds::Connection((char *)TestTree::TreePath::toString(tcp).c_str());
            Data * args[3];
            unique_ptr<Data> tree_name = new mds::String(tree.Name().c_str());
            args[0] = tree_name;
            unique_ptr<Data> ans = m_cnx->get("getenv($1//'_path')",args,1);
            args[1] = ans;
            unique_ptr<Data> path_env = m_cnx->get("getenv('PATH')",args,1);
            args[2] = path_env;
            delete m_cnx;

            TestTree::TreePath p = tree.Path();
            p.port.clear();
            cnx_path = TestTree::TreePath::toString(p);
            m_cnx = new mds::Connection((char *)cnx_path.c_str());
            m_cnx->get("setenv($1//'_path='//$2)",args,2);
            m_cnx->get("setenv('PATH='//$3)",args,3);
            ans = m_cnx->get("getenv($1//'_path')",args,1);
        }
        ////////////////////////////////////////////////////////////////////////
        else {
            m_cnx = new mds::Connection((char *)cnx_path.c_str());
        }
        m_cnx->openTree((char*)tree.Name().c_str(), 0);
    }

    void Close() {
        if(m_cnx) m_cnx->closeAllTrees();
        delete m_cnx;
        m_cnx = NULL;
    }
    
    void PutSegment(Content::Element &el) /*const*/ {
        Data * args[1];
        args[0] = el.data;            
            
        if(m_nodisk) {
            // write only into memory simply getting the size of sent array
            m_cnx->get("size($1)",args,1); 
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
            m_cnx->get(ss.str().c_str(),args,1);
            delete[] begin;
            delete[] end;
            delete[] delta;
        }
    }

private:
    mds::Connection *m_cnx;

};


////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Channel::Channel(int size_KB, const ChannelTypeEnum &kind) : 
    m_cnxerr_count(0), 
    m_cnxerr_threshold(MAX_CONNECTION_ATTEMPTS), 
    m_cnxerr_usleep(WAIT_CONNECTION_USECONDS),
    m_size(size_KB)
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
        try{ d->PutSegment(el); break; }
        catch (MdsException &e) {
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





} // mdsip_test
