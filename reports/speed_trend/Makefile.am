.ONESHELL:
include $(top_srcdir)/Common.am
include $(builddir)/test.conf

setup:
	nano $(builddir)/test.conf



TARGET = "$(TARGET_HOST):$(TARGET_PORT)"
recipes = ${top_builddir}/recipes



distr_tcp_command = $(builddir)/SpeedTrend tcp://${TARGET} "distr-tcp-" \
                    --channels "1 2" --segments 40 --samples 20 --speed_limits 0,0.8 --time_limits 0,0.5 

distr_udt_command = $(builddir)/SpeedTrend udt://${TARGET} "distr-udt-" \
                    --channels "1 2" --segments 40 --samples 20 --speed_limits 0,0.8 --time_limits 0,0.5


	
distr-tcp-speed.csv distr-tcp-trend.csv: SpeedTrend
	@${distr_tcp_command}

distr-udt-speed.csv distr-udt-trend.csv: SpeedTrend
	@${distr_udt_command}


define COMMAND =
endef



# //////////////////////////////////////////////////////////////////////////// #
# ////  PROGRAM   //////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

bin_PROGRAMS = \
               SpeedTrend

SpeedTrend_SOURCES = SpeedTrend.cpp

LDADD = $(top_builddir)/libMDSipTest.la


# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

CLEANFILES = *.csv *.dat *.plt
SUFFIXES = .csv .dat .plt .eps
.PRECIOUS: %.csv %.dat %.plt

IMAGES = 


#### implicit rules ####
.csv.dat:
	@echo $<

.dat.plt:
	@echo $<

.plt.eps:
	@gnuplot $<

PHONY: all_images
all_images: ${IMAGES}




# //////////////////////////////////////////////////////////////////////////// #
# ///  REPORTS  ////////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #



CLEANFILES += *.log *.idx *.out *.toc *.aux
SUFFIXES   += .pdf .dvi
.PRECIOUS: %.pdf %.dvi


if HAVE_PDFLATEX
.tex.pdf:
	set -e
	-$(PDFLATEX) -interaction nonstopmode $<
#	-$(PDFLATEX) -interaction nonstopmode $<
#	-$(PDFLATEX) -interaction nonstopmode $<
else
.tex.pdf: 
	@echo "pdflatex not found in path"
endif



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










