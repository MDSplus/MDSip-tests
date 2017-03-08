#ifndef MDSTEST_H
#define MDSTEST_H

////////////////////////////////////////////////////////////////////////////////
//  DEBUG ACCESS  //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace mdsip_test {
template <class T> struct debug_access {};
} // mdsip_test
# ifdef MDS_DEBUG_ACCESS
#  undef MDS_DEBUG_ACCESS
# endif
# define MDS_DEBUG_ACCESS template<class T> \
                          friend struct ::mdsip_test::debug_access;
# include <mdsobjects.h>  // included with backdor access to private members  //


/// Shortcut to MDSplus namespace
namespace mdsip_test {
namespace mds = MDSplus;
} // mdsip_test


#endif // MDSTEST_H

