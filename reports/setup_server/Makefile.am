
# this makefile contains targets to embed sources of local server scripts that
# are executed to prepare the tests needed files.

.ONESHELL:


define tmp_Makefile
CXX = $${CXX:=g++}
write_huge: write_huge.cpp
\t@ echo "build write_huge.cpp"
\t@ $${CXX} $$< -o $$@ -I$${MDSPLUS_DIR}/include -L$${MDSPLUS_DIR}/lib -lMdsObjectsCppShr -lMdsShr -lTdiShr -lm
endef


# /////////////////
# // ARCHIVE  /////
# /////////////////

TMP_DIR = .setup_server.tmp
${TMP_DIR}:
	@ \
	echo " creating tmp archive "
	mkdir -p $@
	cp $(top_srcdir)/reports/jscope_hugefile/write_huge.cpp $@
	cp $(srcdir)/setup.sh $@/setup.sh
	chmod +x $@/setup.sh
	echo -e '${tmp_Makefile}' > $@/Makefile



# /////////////////////////
# // makeself stript  /////
# /////////////////////////

setup_server.sh: ${TMP_DIR}
	@ \
	echo " Making self extracting server setup script "
	. $(srcdir)/makeself.sh --header $(srcdir)/makeself-header.sh $< $@ "setup server script" "./setup.sh"
	

.PHONY: update
update: setup_server.sh
	@ \
	echo " Update the distributed version "
	cp $(builddir)/setup_server.sh $(top_srcdir)/reports/setup_server.sh
	chmod +x $(top_srcdir)/reports/setup_server.sh


all: setup_server.sh
clean:
	@ \
	rm -f setup_server.sh
	rm -rf ${TMP_DIR}
