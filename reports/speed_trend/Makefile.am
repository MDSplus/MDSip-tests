.ONESHELL:
include $(top_srcdir)/Common.am
include $(builddir)/test.conf

setup:
	nano $(builddir)/test.conf


TARGET = $(PROTOCOL)://$(TARGET_HOST):$(TARGET_PORT)
recipes = ${top_builddir}/recipes





# //////////////////////////////////////////////////////////////////////////// #
# ////  PROGRAM   //////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

bin_PROGRAMS = \
	       SpeedTrend

SpeedTrend_SOURCES = SpeedTrend.cpp


LDADD = $(top_builddir)/libMDSipTest.la -lrt


# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #


define COMMAND =
  $(builddir)/SpeedTrend ${TARGET} "distr-" \
  --channels ${channels} --segments ${segments} --samples ${samples} \
  --speed_limits ${speed_limits} --time_range ${time_range}
endef

IMAGES = distr-speed.eps \
         distr-trend.eps

distr-speed.csv distr-trend.csv: SpeedTrend
	@${addfunc_dialog_bar}
	@${COMMAND}  2>&1 | tee -a SpeedTrend.log | dialog_bar "SpeedTrend Test"


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
define([_PROTOCOL_],[${PROTOCOL}])
define([_LOCAL_TIME_], [esyscmd([date])])
define([_route_tcp_],[esyscmd([traceroute ${TARGET_HOST}])])
define([_route_udp_],[esyscmd([traceroute -U ${TARGET_HOST}])])
define([_recipe_command_],[${COMMAND}])

define([_ping_result_],[esyscmd([ping ${TARGET_HOST} -i .2 -c 20 | tail -n 1 | tr -d '\n' ])])

define([_channels_],[${channels}])
define([_segments_],[${segments}])
define([_samples_],[${samples}])


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
speed_trend.tex: speed_trend.tex.template all_images header.tex
	@ ## building tex from template ##
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@


CLEANFILES += *.pdf *.eps
speed_trend.pdf: speed_trend.tex










