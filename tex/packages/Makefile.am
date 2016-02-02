.ONESHELL:
include $(top_srcdir)/Common.am

PKG = fetamont.zip \
      fontaxes.zip \
      mweights.zip \
      pgfplots.tds.zip \
      roboto.tds.zip

PKG_URL = http://mirrors.ctan.org/fonts/fetamont.zip \
          http://mirrors.ctan.org/macros/latex/contrib/fontaxes.zip \
          http://mirrors.ctan.org/macros/latex/contrib/mweights.zip \
          http://mirrors.ctan.org/install/graphics/pgf/contrib/pgfplots.tds.zip \
          http://mirrors.ctan.org/install/fonts/roboto.tds.zip
          

DISTCLEANFILES = ${PKG}
${PKG}:
	@echo "downloading"
	for i in ${PKG_URL}; do
	 echo "downloading from: $$i ...";
	 wget -q $$i;
	done

define prepare_texinstall =
 unzip -o $<
 export TEXMFHOME=${TEXMFHOME}
 export TEXMFCONFIG=${TEXMFCONFIG}
 cd $@
 latex -interaction nonstopmode $@.ins
endef


.PHONY: fetamont
fetamont: fetamont.zip
	@ echo "fetamont"
	${prepare_texinstall}
	mkdir -p ${TEXMFHOME}/fonts/tfm/public/fetamont
	install tfm/* ${TEXMFHOME}/fonts/tfm/public/fetamont
	mkdir -p ${TEXMFHOME}/fonts/afm/public/fetamont
	install afm/* ${TEXMFHOME}/fonts/afm/public/fetamont
	mkdir -p ${TEXMFHOME}/fonts/type1/public/fetamont
	install type1/* ${TEXMFHOME}/fonts/type1/public/fetamont
	mkdir -p ${TEXMFHOME}/fonts/opentype/public/fetamont
	install opentype/* ${TEXMFHOME}/fonts/opentype/public/fetamont
	mkdir -p ${TEXMFHOME}/tex/latex/fetamont
	install fetamont.sty T1ffm.fd T1ffmw.fd ${TEXMFHOME}/tex/latex/fetamont
	mkdir -p ${TEXMFHOME}/fonts/map/dvips/fetamont
	install fetamont.map ${TEXMFHOME}/fonts/map/dvips/fetamont
	updmap --enable Map fetamont.map
	updmap
	
fontaxes: fontaxes.zip
	@ echo "fontaxes"
	eval ${prepare_texinstall}
	mkdir -p ${TEXMFHOME}/tex/latex/fontaxes
	install fontaxes.sty ${TEXMFHOME}/tex/latex/fontaxes
	
mweights: mweights.zip
	@ echo "mweights"
	unzip -o $<
	cd $@
	mkdir -p ${TEXMFHOME}/tex/latex/$@
	install $@.sty ${TEXMFHOME}/tex/latex/$@
	
.PHONY: pgfplots
pgfplots: pgfplots.tds.zip
	@ echo "pgfplots"
	cd ${TEXMFHOME}
	unzip -o ../$<
	
.PHONY: roboto
roboto: roboto.tds.zip
	@ echo "roboto"
	mkdir -p ${TEXMFHOME}
	cd ${TEXMFHOME}
	unzip -o ../$<
	updmap --enable Map roboto.map
	updmap
	
	
	
