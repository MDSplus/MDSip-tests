.ONESHELL:
include $(top_srcdir)/Common.am
include $(builddir)/test.conf

setup:
	nano $(builddir)/test.conf


TARGET = "$(TARGET_HOST):$(TARGET_PORT)"
recipes = ${top_builddir}/recipes





# //////////////////////////////////////////////////////////////////////////// #
# ////  PROGRAM   //////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

bin_PROGRAMS = \
	       SpeedTrend \
	       timertest

SpeedTrend_SOURCES = SpeedTrend.cpp
timertest_SOURCES = timertest.cpp


LDADD = $(top_builddir)/libMDSipTest.la -lrt


# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #


IMAGES = 

distr_tcp_command = $(builddir)/SpeedTrend tcp://${TARGET} "distr-tcp-" \
		    --channels ${channels} --segments ${segments} --samples ${samples} \
		    --speed_limits ${speed_limits} --time_limits ${time_limits}

distr_udt_command = $(builddir)/SpeedTrend udt://${TARGET} "distr-udt-" \
		    --channels ${channels} --segments ${segments} --samples ${samples} \
		    --speed_limits ${speed_limits} --time_limits ${time_limits}



distr-tcp-speed.csv distr-tcp-trend.csv: SpeedTrend
	@${distr_tcp_command}

distr-udt-speed.csv distr-udt-trend.csv: SpeedTrend
	@${distr_udt_command}


define COMMAND =
endef


PHONY: all_images
all_images: ${IMAGES}




# //////////////////////////////////////////////////////////////////////////// #
# ///  REPORTS  ////////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #


#
# Set of m4 macro definitions to insert command and confguration in TeX report
# 
define M4_TEX_SUBST =
dnl ------------------------------------------------------------------------

dnl # change quote to a m4_sugar stile that is more friendly with sh
changequote(\`[',\`]')

dnl # change comment to a tex friendly character
changecom(\`%', \`')

dnl # substitutions 
define([_HOSTNAME_],[${HOSTNAME}])
define([_TARGET_HOST_],[${TARGET_HOST}])
define([_TARGET_PORT_],[${TARGET_PORT}])
define([_LOCAL_TIME_], [esyscmd([date])])
define([_route_tcp_],[esyscmd([traceroute ${TARGET_HOST}])])
define([_route_udp_],[esyscmd([traceroute -U ${TARGET_HOST}])])
define([_recipe_command_],[${COMMAND}])

define([_ping_result_],[esyscmd([ping ${TARGET_HOST} -i .2 -c 20 | tail -n 1 | tr -d '\n' ])])

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



CLEANFILES += header.tex speed_trend.tex
.PHONY: header.tex speed_trend.tex
header.tex: ../header.tex.template
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@

CLEANFILES += speed_trend.tex
speed_trend.tex: speed_trend.tex.template distr-tcp-speed.eps distr-tcp-trend.eps header.tex
	@ ## building tex from template ##
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@


CLEANFILES += *.pdf *.eps
speed_trend.pdf: speed_trend.tex










