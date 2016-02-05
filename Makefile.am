SUBDIRS = src . recipes

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
	@echo "Entering interactive report execution"
	@$(MAKE) -C reports setup


.PHONY: reports
reports: all
	@echo "Entering report execution"
	@$(MAKE) -C reports all


mdsplus:
	@echo "Building mdsplus submodule"
if BUILD_MDSPLUS
	@$(MAKE) -C mdsplus all
endif
