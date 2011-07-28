gtk_modulesdir = @GTK2_MODULES_DIR@
gtk_modules_LTLIBRARIES = libcaribou.la

libcaribou_la_SOURCES = \
	caribou-gtk-modules.vala \
	caribou-module.c \
	$(NULL)

libcaribou_la_VALAFLAGS = \
	-h caribou-gtk-modules.h \
    --vapidir=. \
	--pkg vapi-fixes \
	--pkg gtk+-2.0 \
	-D GTK2 \
	$(VALAGLAFS)

libcaribou_la_CFLAGS = \
        @GTK2_CFLAGS@ \
        -DG_LOG_DOMAIN=\"CARIBOU\" \
        $(NULL)

libcaribou_la_LIBADD = \
        @GTK2_LIBS@ \
        $(NULL)

libcaribou_la_LDFLAGS = \
        -avoid-version \
        -module \
        $(NULL)

EXTRA_DIST = \
	vapi-fixes.vapi \
	$(NULL)
