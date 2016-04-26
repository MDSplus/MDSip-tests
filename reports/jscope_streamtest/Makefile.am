.ONESHELL:
include $(top_srcdir)/Common.am
include $(builddir)/test.conf


setup:
	nano $(builddir)/test.conf



TARGET = "tcp://${TARGET_HOST}:${TARGET_PORT}::${TARGET_SPOOL}"

define _envset
 export LD_LIBRARY_PATH=${MDS_LIBDIR}:${LD_LIBRARY_PATH}
 export MDS_PATH=${MDS_SRCDIR}/tdi
 export PATH=${MDS_BINDIR}:${PATH}
 export CLASSPATH=${MDS_CLASSPATH}
endef



bin_PROGRAMS = write_stream

write_stream_SOURCES = write_stream.cpp

LDADD = $(AM_LIBS) $(top_builddir)/libMDSipTest.la


.PHONY: jscope_streamtest
jscope_streamtest: write_stream streamtest.jscp
	@ \
	  ${_envset}; \
	  export stream_path=${TARGET}; \
	  $(builddir)/write_stream tcp://${TARGET_HOST}:${TARGET_PORT} & _wpid="$$!"; \
	  [ -n "$${_wpid}" ] && java jScope ${builddir}/streamtest.jscp;  \
	  [ -n "$${_wpid}" ] && kill $${_wpid};


.PHONY: start_write
start_write: write_stream
	@ \
	  ${_envset}; \
	  $(builddir)/write_stream tcp://${TARGET_HOST}:${TARGET_PORT}

.PHONY: start_jscope
start_jscope: streamtest.jscp
	@ \
	  ${_envset}; \
	  java jScope ${builddir}/streamtest.jscp;



# //////////////////////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #
# Set of m4 macro definitions to insert command and confguration in scp files  #
# NOTE: Make 4 needed for this to work
define M4_SUBST =
dnl ------------------------------------------------------------------------
dnl # change quote to a m4_sugar stile that is more friendly with sh
changequote(\`[',\`]')
dnl # change comment to a tex friendly character
changecom(\`%', \`')
dnl # substitutions 
define([_TARGET_HOST_],[${TARGET_HOST}])
define([_TARGET_PORT_],[${TARGET_PORT}])
define([_TARGET_SPOOL_],[${TARGET_SPOOL}])
dnl ------------------------------------------------------------------------
endef

.PHONY: streamtest.jscp
streamtest.jscp: streamtest.jscp.m4
	@ \
	  echo "building jscp from template"; \
	  (echo "${M4_SUBST}"; cat $<) | m4 > $@


all:
