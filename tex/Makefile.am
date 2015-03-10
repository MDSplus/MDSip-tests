SUBDIRS = . img

CLEANFILES = *.log *.idx *.out *.toc *.aux

all: report

.PHONY: report
if HAVE_PDFLATEX
report: report.tex bashful.sty
	$(PDFLATEX) $<
else
report:

endif
