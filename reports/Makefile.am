.ONESHELL:


all: ;

MKDIR_P  = mkdir -p

TARGET_HOST    ?= rat
TARGET_PORT    ?= 8100



TARGET = "$(TARGET_HOST):$(TARGET_PORT)"
recipes = ${top_builddir}/recipes





# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

CLEANFILES = *.csv *.dat *.plt
SUFFIXES = .csv .dat .plt .eps
.PRECIOUS: %.csv %.dat %.plt

IMAGES = \
	size-tcp.eps \
	size-udt.eps \
	distr-tcp-speed.eps \
	distr-tcp-time.eps \
	distr-udt-speed.eps \
	distr-udt-time.eps \
	content-udt.eps 

size-tcp.csv:
	${recipes}/SegmentSize tcp://${TARGET} size-tcp \
	--channels "1 2 4" --segments 128,128,512 --samples 10

size-udt.csv:
	${recipes}/SegmentSize udt://${TARGET} size-udt \
	--channels "1 2 4" --segments 128,128,512 --samples 10

distr-tcp-speed.csv distr-tcp-time.csv:
	${recipes}/SpeedDistribution tcp://${TARGET} "distr-tcp-" \
	--channels 1 --segments 40 --samples 100 --speed_limits 0,0.8 --time_limits 0,0.5 

distr-udt-speed.csv distr-udt-time.csv:
	${recipes}/SpeedDistribution udt://${TARGET} "distr-udt-" \
	--channels 1 --segments 40 --samples 100 --speed_limits 0,0.8 --time_limits 0,0.5

content-udt.csv:
	${recipes}/SegmentContent udt://${TARGET} conent-udt \
	--channels 1 --segments 128,128,512 --samples 10



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
	-$(PDFLATEX) -interaction nonstopmode $<
	-$(PDFLATEX) -interaction nonstopmode $<
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

dnl # commands printing the packets route
define([_HOSTNAME_],[${HOSTNAME}])
define([_TARGET_HOST_],[${TARGET_HOST}])
define([_TARGET_PORT_],[${TARGET_PORT}])
define([_LOCAL_TIME_], [esyscmd([date])])
define([_route_tcp_],[esyscmd([traceroute ${TARGET_HOST}])])
define([_route_udp_],[esyscmd([traceroute -U ${TARGET_HOST}])])

define([_recipe_command_],[${_recipe_command_}])
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



segment_size.tex: export _recipe_command_=cacconazza

segment_size.pdf: header.tex route.tex size-tcp.eps size-udt.eps 











