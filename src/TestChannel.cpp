
#include <mdsobjects.h>

#include "SerializeUtils.h"
#include "DataUtils.h"
#include "Threads.h"

#include "TestChannel.h"

using namespace MDSplus;

namespace mdsip_test {



////////////////////////////////////////////////////////////////////////////////
//  CHANNEL DC  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class ChannelDC : public Channel {
public:
    ChannelDC(int size) :
        m_size(size),
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
    
    void Evaluate(std::string cmd) {        
        throw( new MDSplus::MdsException("remote evaluation not available in DC channels\n") );
    }

    size_t Size() const { return m_size; }

private:
    size_t m_size;
    Tree  *m_tree;    
};



////////////////////////////////////////////////////////////////////////////////
//  CHANNEL TC  ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////



class ChannelTC : public Channel {
public:
    ChannelTC(int size) :
        m_cnx(0),
        m_size(size)
    {}

    ~ChannelTC() {
        // Close();
    }

    void Open(TestTree &tree) {
        if(m_cnx) Close();       
        std::string cnx_path = TestTree::TreePath::toString(tree.Path());
        m_cnx = new mds::Connection((char *)cnx_path.c_str());
        m_cnx->openTree((char*)tree.Name().c_str(), 0);
    }

    void Close() {
        if(m_cnx) {
            m_cnx->closeAllTrees();
            delete m_cnx;
            m_cnx = NULL;
        }
    }
    
    void PutSegment(Content::Element &el) /*const*/ {
        
      Data * args[1];
      args[0] = el.data;      
      
      char * begin = el.dim->getBegin()->getString();
      char * end = el.dim->getEnding()->getString();
      char * delta = el.dim->getDeltaVal()->getString();
      
      std::stringstream ss;
      ss << "MakeSegment(" 
         << el.path << "," 
         << begin << ","
         << end << ","
         << "make_range(" << begin << "," << end << "," << delta << ")" << ",,"
         << "$1" << ","
         << el.data->getSize() << ")";            
      // TDI: public fun MakeSegment(as_is _node, in _start, in _end, as_is _dim, in _array, optional _idx, in _rows_filled)
      m_cnx->get(ss.str().c_str(),args,1);

      delete[] begin;
      delete[] end;
      delete[] delta;
    }

    void Evaluate(std::string cmd) {
        m_cnx->get(cmd.c_str());
    }
    
    size_t Size() const { return m_size; }

private:
    mds::Connection *m_cnx;
    size_t m_size;
};


////////////////////////////////////////////////////////////////////////////////
//  Channel  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Channel *Channel::NewDC(int size_KB) {
    return new ChannelDC(size_KB);
}

Channel *Channel::NewTC(int size_KB) {
    return new ChannelTC(size_KB);
}




} // mdsip_test
