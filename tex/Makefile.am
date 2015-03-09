SUBDIRS = . img

CLEANFILES = $(MANPDF) $(MANNAME).log $(MANNAME).idx $(MANNAME).out \
 $(MANNAME).toc $(MANAUX)

all: report


.PHONY: report

if HAVE_PDFLATEX
report: report.tex 
	$(PDFLATEX) $<
else
report:

endif
