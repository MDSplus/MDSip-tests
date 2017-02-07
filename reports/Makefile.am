SUBDIRS = segment_size speed_spread speed_trend jscope_streamtest jscope_hugefile
include $(top_srcdir)/Common.am

TARGET_HOST    ?= localhost
TARGET_PORT    ?= 8000
TARGET_SPOOL   ?= /tmp/mdsip_test
TARGET_USER    ?= ${USER}

export TARGET_HOST
export TARGET_PORT
export TARGET_SPOOL
export TARGET_USER


TARGET  = "$(TARGET_HOST):$(TARGET_PORT)"
recipes = ${top_builddir}/recipes

setup-client:
	. $(builddir)/setup_client.sh

setup-server:
	. $(builddir)/setup_server.sh gui_main ||:

start-server:
	. $(builddir)/setup_server.sh xinetd

stop-server:
	. $(builddir)/setup_server.sh stop


# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

# IMAGES = 

# distr-tcp-speed.csv distr-tcp-time.csv:
#	${recipes}/SpeedDistribution tcp://${TARGET} "distr-tcp-" \
#	--channels 1 --segments 40 --samples 100 --speed_limits 0,0.8 --time_limits 0,0.5 

# distr-udt-speed.csv distr-udt-time.csv:
#	${recipes}/SpeedDistribution udt://${TARGET} "distr-udt-" \
#	--channels 1 --segments 40 --samples 100 --speed_limits 0,0.8 --time_limits 0,0.5

# content-udt.csv:
#	${recipes}/SegmentContent udt://${TARGET} conent-udt \
#	--channels 1 --segments 128,128,512 --samples 10

# PHONY: all_images
# all_images: ${IMAGES}




# //////////////////////////////////////////////////////////////////////////// #
# ///  REPORTS  ////////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #



#CLEANFILES += *.log *.idx *.out *.toc *.aux
#SUFFIXES   += .pdf .dvi
#.PRECIOUS: %.pdf %.dvi
#if HAVE_PDFLATEX
#.tex.pdf:
#	@ \
#	set -e; \
#	-$(PDFLATEX) -interaction nonstopmode $<; \
#	-$(PDFLATEX) -interaction nonstopmode $<; \
#	-$(PDFLATEX) -interaction nonstopmode $<;
#else
#.tex.pdf:
#	@echo "pdflatex not found in path"
#endif



#
# Set of m4 macro definitions to insert command and confguration in TeX report
# 
define M4_TEX_SUBST =
dnl ------------------------------------------------------------------------

dnl # change quote to a m4_sugar stile that is more friendly with sh
changequote(\`[',\`]')

dnl # change comment to a tex friendly character
changecom(\`%', \`')

dnl # commands printing the packets route
define([_HOSTNAME_],[${HOSTNAME}])
define([_TARGET_HOST_],[${TARGET_HOST}])
define([_TARGET_PORT_],[${TARGET_PORT}])
define([_LOCAL_TIME_], [esyscmd([date])])
define([_route_tcp_],[esyscmd([traceroute ${TARGET_HOST}])])
define([_route_udp_],[esyscmd([traceroute -U ${TARGET_HOST}])])



dnl ------------------------------------------------------------------------
endef






.PHONY: tex_subst.m4
CLEANFILES += tex_subst.m4
tex_subst.m4:
	@ ## Build of script macros ##
	cat > $@ << EOF
	${M4_TEX_SUBST}
	EOF


SUFFIXES   += .tex.template .tex
.tex.template.tex:
	@ ## building tex from template ##
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@


.PHONY: segment_size.pdf
CLEANFILES += segment_size.pdf
segment_size.pdf:
	@echo "Making segment size test"
	@$(MAKE) -k -C segment_size clean $@;
	 cp -a $(builddir)/segment_size/$@ $@


.PHONY: speed_trend.pdf
CLEANFILES += speed_trend.pdf
speed_trend.pdf:
	@echo "Making speed trend test"
	@$(MAKE) -k -C speed_trend clean $@;
	 cp -a $(builddir)/speed_trend/$@ $@


.PHONY: speed_spread.pdf
CLEANFILES += speed_spread.pdf
speed_spread.pdf:
	@echo "Making speed trend test"
	@$(MAKE) -k -C speed_spread clean $@;
	 cp -a $(builddir)/speed_spread/$@ $@

.PHONY: jscope_streamtest
jscope_streamtest:
if HAVE_MDSPLUS_STREAMING
	@echo "Making sreaming test example "
	@$(MAKE) -k -C jscope_streamtest $@;
else	
	@ \
	 echo " Streaming is not supported by the installed mdsplus version "; \
	 read -p "Press any key to continue... " -n1 -s;
endif

.PHONY: jscope_hugefile
jscope_hugefile:
	@echo "Making hugefile view example "
	@$(MAKE) -k -C jscope_hugefile $@;



#.PHONY: segment_size speed_spread speed_trend
segment_size: segment_size.pdf
speed_spread: speed_spread.pdf
speed_trend: speed_trend.pdf


TESTS = segment_size \
	speed_spread \
	speed_trend \
	jscope_streamtest



# all: ${TESTS}
reports: setup




