touchlayoutsdir = $(datadir)/caribou/layouts/touch
touchlayouts_in_files =\
    ara.xml.in \
    il.xml.in \
    us.xml.in
touchlayouts_DATA = $(touchlayouts_in_files:.xml.in=.xml)

common_files = \
	common/qwerty.xml \
	common/symbols.xml

%.xsl: %.xml.in
	xsltproc --xinclude $(top_srcdir)/tools/basic.xsl $< > $@

%.xml: %.xsl %.xml.in
	xsltproc --xinclude $^ > $@

EXTRA_DIST = $(touchlayouts_in_files) $(common_files)

CLEANFILES = $(touchlayouts_DATA) $(touchlayouts_in_files:.xml.in=.xsl)