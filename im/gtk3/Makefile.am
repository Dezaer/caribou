gtk_modulesdir = @GTK3_MODULES_DIR@
gtk_modules_LTLIBRARIES = libcaribou.la

libcaribou_la_SOURCES = \
	caribou-imcontext.vala \
	caribou-im.c \
	$(NULL)

libcaribou_la_VALAFLAGS = \
	-h caribou-imcontext.h \
    --vapidir=. \
	--pkg vapi-fixes \
	--pkg gtk+-3.0 \
	$(VALAGLAFS)

libcaribou_la_CFLAGS = \
        @GTK3_CFLAGS@ \
        -DG_LOG_DOMAIN=\"CARIBOU\" \
        $(NULL)

libcaribou_la_LIBADD = \
        @GTK3_LIBS@ \
        $(NULL)

libcaribou_la_LDFLAGS = \
        -avoid-version \
        -module \
        $(NULL)

EXTRA_DIST = \
	vapi-fixes.vapi \
	$(NULL)
