include $(top_srcdir)/Common.am

#AM_DEFAULT_SOURCE_EXT = .cpp

# if HAVE_CHECK
TESTS = BuildTest


# UuidTest

# else
# TEST =
# endif

LDADD = $(top_builddir)/libMDSipTest.la

check_PROGRAMS = $(TESTS)


all: $(TESTS)

