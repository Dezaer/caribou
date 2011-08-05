gtk_modulesdir = @GTK2_MODULES_DIR@
gtk_modules_LTLIBRARIES = libcaribou-gtk-module.la

libcaribou_gtk_module_la_SOURCES = \
	caribou-gtk-module.vala \
	caribou-module.c \
	$(NULL)

libcaribou_gtk_module_la_VALAFLAGS = \
	-h caribou-gtk-module.h \
	--vapidir=. \
	--pkg gdk-x11-2.0 \
	--pkg gtk+-2.0 \
	-D GTK2 \
	$(VALAGLAFS)

libcaribou_gtk_module_la_CFLAGS = \
	@GTK2_CFLAGS@ \
	-DG_LOG_DOMAIN=\"CARIBOU\" \
	$(NULL)

libcaribou_gtk_module_la_LIBADD = \
	@GTK2_LIBS@ \
	$(NULL)

libcaribou_gtk_module_la_LDFLAGS = \
	-avoid-version \
	-module \
	$(NULL)

