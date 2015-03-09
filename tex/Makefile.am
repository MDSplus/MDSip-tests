SUBDIRS = . img

CLEANFILES = $(MANPDF) $(MANNAME).log $(MANNAME).idx $(MANNAME).out \
 $(MANNAME).toc $(MANAUX)

all: images report

MKDIR_P = mkdir -p

TARGET = rat.rfx.local:8200


# //////////////////////////////////////////////////////////////////////////// #
# // GENERATE IMAGES //

.PHONY: images
images:
	${MKDIR_P} img
	${top_builddir}/recipes/SegmentSize tcp://${TARGET} img/size_tcp
	${top_builddir}/recipes/SegmentSize udt://${TARGET} img/size_udt

# //////////////////////////////////////////////////////////////////////////// #




.PHONY: report

if HAVE_PDFLATEX
report: report.tex
	$(PDFLATEX) $<
else
report:

endif
