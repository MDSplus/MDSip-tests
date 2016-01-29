.ONESHELL:
include $(top_srcdir)/Common.am


TARGET_HOST    ?= rat
TARGET_PORT    ?= 8100



TARGET = "$(TARGET_HOST):$(TARGET_PORT)"
recipes = ${top_builddir}/recipes

size_tcp_command = $(builddir)/SegmentSize tcp://${TARGET} size-tcp \
                   --channels "1 2 4" --segments 128,256,1024 --samples 20

size_udt_command = $(builddir)/SegmentSize udt://${TARGET} size-udt \
                   --channels "1 2 4" --segments 128,256,1024 --samples 20

define COMMAND =
${size_tcp_command}
${size_udt_command}
endef



# //////////////////////////////////////////////////////////////////////////// #
# ////  PROGRAM   //////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

bin_PROGRAMS = \
               SegmentSize

SegmentSize_SOURCES = SegmentSize.cpp

LDADD = $(top_builddir)/libMDSipTest.la


# //////////////////////////////////////////////////////////////////////////// #
# ////  IMAGES   ///////////////////////////////////////////////////////////// #
# //////////////////////////////////////////////////////////////////////////// #

CLEANFILES = *.csv *.dat *.plt
SUFFIXES = .csv .dat .plt .eps
.PRECIOUS: %.csv %.dat %.plt

IMAGES = \
	size-tcp.eps \
	size-udt.eps 

size-tcp.csv: SegmentSize
	${size_tcp_command}

size-udt.csv: SegmentSize
	${size_udt_command}



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


tcp_max_point = "cat size-tcp.sh | grep max_pt | awk -F'=' '{print $2}'"


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

define([_ping_result_],[esyscmd([ping ${TARGET_HOST} -i .2 -c 20 | tail -n 1])])

define([_tcp_max_pt_],[esyscmd([. ./size-tcp.sh; printf \$${max_pt} ])])
define([_tcp_max_x_],[esyscmd([. ./size-tcp.sh; printf  \$${max_x} ])])
define([_tcp_max_y_],[esyscmd([. ./size-tcp.sh; printf "%.2f" \$${max_y} ])])
define([_tcp_max_e_],[esyscmd([. ./size-tcp.sh; printf "%.2f" \$${max_e} ])])

define([_udt_max_pt_],[esyscmd([. ./size-udt.sh; printf \$${max_pt} ])])
define([_udt_max_x_],[esyscmd([. ./size-udt.sh; printf  \$${max_x} ])])
define([_udt_max_y_],[esyscmd([. ./size-udt.sh; printf "%.2f" \$${max_y} ])])
define([_udt_max_e_],[esyscmd([. ./size-udt.sh; printf "%.2f" \$${max_e} ])])


dnl ------------------------------------------------------------------------
endef


#The connection present a RTT of: {\bf _RTT_ }.
#The tests results report a maximum achievable speed of _tcp_max_speed_ when the 
#connection is set to transfer data in segments of size _tcp_max_speed_size_ [[Kb]]

CLEANFILES += size-tcp.sh size-udt.sh

.PHONY: tex_subst.m4
CLEANFILES += tex_subst.m4
tex_subst.m4:
	@## Build of script macros ##
	cat > $@ << EOF
	${M4_TEX_SUBST}
	EOF


SUFFIXES   += .tex.template .tex
.tex.template.tex:
	@ ## building tex from template ##
	source $(builddir)/size-tcp.sh
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@


# LOCALTEST HEADER
CLEANFILES += header.tex segment_size.tex

.PHONY: header.tex segment_size.tex
header.tex: ../header.tex.template
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@


segment_size.tex: segment_size.tex.template size-tcp.eps size-udt.eps header.tex
	@ ## building tex from template ##	
	$(MAKE) tex_subst.m4
	cat tex_subst.m4 $< | m4 > $@



CLEANFILES += *.pdf *.eps
segment_size.pdf: segment_size.tex










