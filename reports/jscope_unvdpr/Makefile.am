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


JSCP ?= \
	EAST.jscp \
	rt_camere.jscp \
	rt_reference.jscp

.PHONY: start_jscope
start_jscope: $(JSCP)
	@ \
	  ${_envset}; \
	  for j in $(JSCP_FILES); do \
	   java jScope ${builddir}/$$j & \
	  done



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

MOSTLYCLEANFILES = $(JSCP)

SUFFIXES += .jscp.m4 .jscp
.jscp.m4.jscp:
	@ \
	  echo "building $@ from template"; \
	  (echo "${M4_SUBST}"; cat $<) | m4 > $@



all: start_jscope
