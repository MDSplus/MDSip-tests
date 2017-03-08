#ifndef NL_LINK_H
#define NL_LINK_H

#include <sys/socket.h>
#include <linux/if_link.h>

#ifdef __cplusplus
extern "C" {
#endif

struct nlsock_link_stats;
struct rtnl_link_stats;

struct nlsock_link_stats * nl_link_setup(const char *devname);
int nl_link_read(struct nlsock_link_stats *nlsk);
void nl_link_release(struct nlsock_link_stats *sock);
int nl_link_getstats(struct nlsock_link_stats *sock, struct rtnl_link_stats *stats);
int nl_link_getstats64(struct nlsock_link_stats *nlsk, struct rtnl_link_stats64 *stats);

#ifdef __cplusplus
} // C
#endif


#endif // NL_LINK_H
