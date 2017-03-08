include $(top_srcdir)/Common.am


bin_PROGRAMS = ping
ping_SOURCES = ping.c


noinst_LTLIBRARIES = libnllink.la
libnllink_la_SOURCES = nl_link.c

bin_PROGRAMS += nl_link_test
nl_link_test_LDADD = libnllink.la

LDADD = -lm
