SUBDIRS = src . recipes

ACLOCAL_AMFLAGS = -I m4

include Common.am


#library_includedir = $(includedir)/libMDSipTest
#library_include_HEADERS = config.h
#test_SOURCES = src/main.cpp
#bin_PROGRAMS = test
#test_LDADD = libMDSipTest.la


##PACKAGE_MAJOR=@PACKAGE_MAJOR@
##PACKAGE_MINOR=@PACKAGE_MINOR@

# fix !
LIBRARY_VERSION = 1:0:0

CONLIBS = src/libMDSipTest.la

lib_LTLIBRARIES = libMDSipTest.la
libMDSipTest_la_SOURCES = ${_uLib_SOURCES}
libMDSipTest_la_LDFLAGS = -version-info $(LIBRARY_VERSION)
# -release $(PACKAGE_VERSION)
libMDSipTest_la_LIBADD  = $(AM_LIBS_ALL) ${CONLIBS}


# pkgconfigdir   = $(libdir)/pkgconfig
# pkgconfig_DATA = libmutom-${PACKAGE_VERSION}.pc

