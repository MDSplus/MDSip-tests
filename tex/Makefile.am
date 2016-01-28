SUBDIRS = . img

CLEANFILES = *.log *.idx *.out *.toc *.aux

all: report


.PHONY: report
if HAVE_PDFLATEX
report: report.tex
	$(PDFLATEX) $<
else
report:
	@echo "pdflatex is not installed"
endif
