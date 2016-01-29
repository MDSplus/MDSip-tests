.ONESHELL:
include $(top_srcdir)/Common.am


TARGET_HOST    ?= rat
TARGET_PORT    ?= 8100



TARGET = "$(TARGET_HOST):$(TARGET_PORT)"
recipes = ${top_builddir}/recipes


IMAGES = \
	distr-tcp-speed.eps \
	distr-tcp-time.eps \
	distr-udt-speed.eps \
	distr-udt-time.eps





distr_tcp_command = $(builddir)/SpeedSpread tcp://${TARGET} "distr-tcp-" \
                    --channels "1 2" --segments 40 --samples 50 --speed_limits 0,0.8 --time_limits 0,0.5 

distr_udt_command = $(builddir)/SpeedSpread udt://${TARGET} "distr-udt-" \
                    --channels "1 2" --segments 40 --samples 50 --speed_limits 0,0.8 --time_limits 0,0.5


	
distr-tcp-speed.csv distr-tcp-time.csv: SpeedSpread
	@${distr_tcp_command}

distr-udt-speed.csv distr-udt-time.csv: SpeedSpread
	@${distr_udt_command}
	

define COMMAND =
${distr_tcp_command}
${distr_udt_command}
endef



# //////////////////////////////////////////////////////////////////////////// #
# ////  PROGRAM   //////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

bin_PROGRAMS = \
               SpeedSpread

SpeedSpread_SOURCES = SpeedSpread.cpp

LDADD = $(top_builddir)/libMDSipTest.la


# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

CLEANFILES = *.csv *.dat *.plt
SUFFIXES = .csv .dat .plt .eps
.PRECIOUS: %.csv %.dat %.plt



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



CLEANFILES += header.tex speed_spread.tex
.PHONY: header.tex speed_spread.tex
header.tex: ../header.tex.template
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@

CLEANFILES += speed_spread.tex
speed_spread.tex: speed_spread.tex.template distr-tcp-speed.eps distr-udt-speed.eps header.tex
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@



CLEANFILES += *.pdf *.eps
speed_spread.pdf: speed_spread.tex










