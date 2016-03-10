SUBDIRS =
if BUILD_MDSPLUS
SUBDIRS += mdsplus
endif
SUBDIRS += src . recipes


ACLOCAL_AMFLAGS = -I m4

include Common.am


LIBRARY_VERSION = 1:0:0

CONLIBS = src/libMDSipTest.la

lib_LTLIBRARIES = libMDSipTest.la
libMDSipTest_la_SOURCES = ${_uLib_SOURCES}
libMDSipTest_la_LDFLAGS = -version-info $(LIBRARY_VERSION)
# -release $(PACKAGE_VERSION)
libMDSipTest_la_LIBADD  = $(AM_LIBS) ${CONLIBS}



.PHONY: reports_gui
reports-gui: all 
	@ echo "Entering interactive report execution"
	@ $(MAKE) -C reports setup-client

.PHONY: reports
reports: all
	@ echo "Entering report execution"
	@ $(MAKE) -C reports all



.PHONY: mdsplus
mdsplus:
	@ echo "Building mdsplus submodule"
if BUILD_MDSPLUS
	@ $(MAKE) -C mdsplus all
endif



.PHONY: setup-client setup-server
setup-client: reports-gui
setup-server:
	@ echo "Entering interactive server execution"	
	@ $(MAKE) -C reports setup-server
