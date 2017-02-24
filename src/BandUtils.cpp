#include <BandUtils.h>

#include <arpa/inet.h>
#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/if_link.h>


#include <sys/types.h>          /* See NOTES */
#include <sys/socket.h>


#include <linux/if_link.h>
#include "ext_tools/nl_link.h"


////////////////////////////////////////////////////////////////////////////////
//  NLSTATS  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


// struct rtnl_link_stats //
//	__u32	rx_packets;		/* total packets received	*/
//	__u32	tx_packets;		/* total packets transmitted	*/
//	__u32	rx_bytes;		/* total bytes received 	*/
//	__u32	tx_bytes;		/* total bytes transmitted	*/
//	__u32	rx_errors;		/* bad packets received		*/
//	__u32	tx_errors;		/* packet transmit problems	*/
//	__u32	rx_dropped;		/* no space in linux buffers	*/
//	__u32	tx_dropped;		/* no space available in linux	*/
//	__u32	multicast;		/* multicast packets received	*/
//	__u32	collisions;

//	/* detailed rx_errors: */
//	__u32	rx_length_errors;
//	__u32	rx_over_errors;		/* receiver ring buff overflow	*/
//	__u32	rx_crc_errors;		/* recved pkt with crc error	*/
//	__u32	rx_frame_errors;	/* recv'd frame alignment error */
//	__u32	rx_fifo_errors;		/* recv'r fifo overrun		*/
//	__u32	rx_missed_errors;	/* receiver missed packet	*/

//	/* detailed tx_errors */
//	__u32	tx_aborted_errors;
//	__u32	tx_carrier_errors;
//	__u32	tx_fifo_errors;
//	__u32	tx_heartbeat_errors;
//	__u32	tx_window_errors;

//	/* for cslip etc */
//	__u32	rx_compressed;
//	__u32	tx_compressed;

//	__u32	rx_nohandler;		/* dropped, no handler found	*/


int mdsip_test::NLStats::get_link_stats(const char *_iface, struct rtnl_link_stats *stats)
{
    struct ifaddrs *ifaddr, *ifa;
    int family, n;
    char *iface = strdup(_iface);

    if (getifaddrs(&ifaddr) == -1) throw ifa_error();

    for (ifa = ifaddr, n = 0; ifa != NULL; ifa = ifa->ifa_next, n++) {
        if (ifa->ifa_addr == NULL ||  strcmp(ifa->ifa_name,iface) )
            continue;
        family = ifa->ifa_addr->sa_family;
        if (family == AF_PACKET && ifa->ifa_data != NULL) {
            memcpy(stats,ifa->ifa_data,sizeof(struct rtnl_link_stats));
            freeifaddrs(ifaddr);
            return 1;
        }
    }
    memset(stats,0,sizeof(struct rtnl_link_stats));
    freeifaddrs(ifaddr);
    return 0;
}



////////////////////////////////////////////////////////////////////////////////
//  CONNECTION MONITOR  ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// #include <mdsip_connections.h> //////////////////////////////////////////////

#define MDSIP_MAX_ARGS 256
extern "C" typedef struct _treecontext { void *tree; } TreeContext;
extern "C" typedef struct _connection {
  int id; /* unique connection id */
  char *protocol;
  char *info_name;
  void *info;
  size_t info_len;
  TreeContext context;
  unsigned char message_id;
  int client_type;
  int nargs;
  struct descriptor *descrip[MDSIP_MAX_ARGS]; ///< list of descriptors for the
  /// message arguments
  struct _eventlist *event;
  void *tdicontext[6];
  int addr;
  int compression_level;
  int readfd;
  struct _io_routines *io;
  char deleted;
  struct _connection *next;
} Connection;

extern "C" Connection *FindConnection(int id, Connection ** prev);


////////////////////////////////////////////////////////////////////////////////
//  CONNECTION DEBUG ACCESS  ///////////////////////////////////////////////////
namespace mdsip_test {
template <> struct debug_access<mds::Connection> {
    static int getSockId(const mds::Connection *cnx) { return cnx->sockId; }
};
} // mdsip_test
////////////////////////////////////////////////////////////////////////////////


mdsip_test::SocketOptMonitor::SocketOptMonitor()
{
    d.id = 0;
    d.rcvbuf = 0;
    d.sndbuf = 0;
}


void mdsip_test::SocketOptMonitor::SetFromMdsConnection(const MDSplus::Connection *cnx)
{
    // ADD AC_DEFINE to check for getSockId() //
    // int c_id = cnx->getSockId();
    int c_id = debug_access<mds::Connection>::getSockId(cnx);
    Connection * c = FindConnection(c_id,0);
    if(c)
        d.id = c->readfd;
}

int mdsip_test::SocketOptMonitor::Update()
{
    socklen_t len;
    int status = 0;
    status |= getsockopt(d.id, SOL_SOCKET, SO_RCVBUF, &d.rcvbuf, &len);
    status |= getsockopt(d.id, SOL_SOCKET, SO_SNDBUF, &d.sndbuf, &len);
    return status;
}

template< typename C, typename Event, typename = void >
struct has_receive
        : std::false_type
{};

template< typename C, typename Event >
struct has_receive< C, Event, typename std::enable_if<
        std::is_same<
        decltype( std::declval<C>().receive( std::declval<const Event&>() ) ),
void
>::value
>::type >
    : std::true_type
{};


















