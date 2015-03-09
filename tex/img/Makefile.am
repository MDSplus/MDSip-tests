SUBDIRS = .

# CLEANFILES = *.dat

# all: size_images

MKDIR_P = mkdir -p

TARGET = rat.rfx.local:8200
recipes = ${top_builddir}/recipes

# //////////////////////////////////////////////////////////////////////////// #
# // GENERATE IMAGES //

SIZE_TCP_OPTIONS = --channels 1 --segments 128,128,512 --samples 10
SIZE_UDP_OPTIONS = --channels 1 --segments 128,128,1024 --samples 10

.PHONY: size_images

SUFFIXES = .csv .dat .plt .eps
.PRECIOUS: %.csv %.dat %.plt

size_tcp.csv:
	${recipes}/SegmentSize tcp://${TARGET} size_tcp ${SIZE_TCP_OPTIONS}

size_udt.csv:
	${recipes}/SegmentSize udt://${TARGET} size_tcp ${SIZE_UDT_OPTIONS}


.csv.dat:
	echo $^

.dat.plt:
	echo $^

.plt.eps:
	gnuplot $<


size_images: size_tcp.eps


# //////////////////////////////////////////////////////////////////////////// #


