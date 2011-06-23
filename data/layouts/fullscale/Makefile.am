fullscalelayoutsdir = $(datadir)/caribou/layouts/fullscale
fullscalelayouts_in_files =\
    us.xml.in
fullscalelayouts_DATA = $(fullscalelayouts_in_files:.xml.in=.xml)

common_files = \
	common/qwerty.xml \
	common/symbols.xml

%.xsl: %.xml.in
	xsltproc --xinclude $(top_srcdir)/tools/basic.xsl $< > $@

%.xml: %.xsl %.xml.in
	xsltproc --xinclude $^ > $@

EXTRA_DIST = $(fullscalelayouts_in_files) $(common_files)

CLEANFILES = $(fullscalelayouts_DATA) $(fullscalelayouts_in_files:.xml.in=.xsl)
