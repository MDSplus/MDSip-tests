SUBDIRS = .

CLEANFILES = *.csv *.dat *.plt

all: images

MKDIR_P = mkdir -p

TARGET = rat.rfx.local:8200
ROKKASHO = test10g.nifs.ac.jp:8000

recipes = ${top_builddir}/recipes

SUFFIXES = .csv .dat .plt .eps
.PRECIOUS: %.csv %.dat %.plt


# //////////////////////////////////////////////////////////////////////////// #
# // GENERATE IMAGES //

IMAGES = \
	size-tcp.eps \
	size-udt.eps \
	distr-tcp-speed.eps \
	distr-tcp-time.eps \
	distr-udt-speed.eps \
	distr-udt-time.eps 

size-tcp.csv:
	${recipes}/SegmentSize tcp://${TARGET} size-tcp \
	--channels 1 --segments 128,128,512 --samples 10

size-udt.csv:
	${recipes}/SegmentSize udt://${TARGET} size-udt \
	--channels 1 --segments 128,128,512 --samples 10

distr-tcp-speed.csv distr-tcp-time.csv:
	${recipes}/SpeedDistribution tcp://${TARGET} "distr-tcp-" \
	--channels 1 --segments 40 --samples 100 --speed_limits 0,0.8 --time_limits 0,0.5 

distr-udt-speed.csv distr-udt-time.csv:
	${recipes}/SpeedDistribution udt://${TARGET} "distr-udt-" \
	--channels 1 --segments 40 --samples 100 --speed_limits 0,0.8 --time_limits 0,0.5


#### implicit rules ####

.csv.dat:
	echo $<

.dat.plt:
	echo $<

.plt.eps:
	gnuplot $<

PHONY: images
images: ${IMAGES}


# //////////////////////////////////////////////////////////////////////////// #


