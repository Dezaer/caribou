lib_LTLIBRARIES = libcaribou.la

INCLUDES = \
	-DG_LOG_DOMAIN=\"caribou\" \
	-I$(top_srcdir) \
	$(LIBCARIBOU_CFLAGS)

libcaribou_la_VALAFLAGS = \
	-H caribou.h --vapi caribou-1.0.vapi \
	-h caribou-internals.h \
	--vapidir=. \
	--pkg x11 --pkg gdk-3.0 --pkg gio-2.0 --pkg gee-1.0 \
	--pkg libxklavier --pkg external-libs --pkg gdk-x11-3.0 --pkg libxml-2.0 \
	--internal-vapi caribou-internals-1.0.vapi \
	--library caribou-1.0 --gir _Caribou-1.0.gir \
	$(VALAFLAGS)

libcaribou_la_CPPFLAGS = \
	$(INCLUDES)

libcaribouincludedir = $(includedir)/libcaribou

caribouinclude_headers = \
	caribou.h

libcaribouinclude_HEADERS = \
	$(caribou_headers)

libcaribou_la_LIBADD = \
	$(LIBCARIBOU_LIBS)

libcaribou_la_SOURCES = \
	xadapter.vala \
	keyboard-model.vala \
	keyboard-service.vala \
	group-model.vala \
	level-model.vala \
	row-model.vala \
	key-model.vala \
	column-model.vala \
	scanner.vala \
	iscannable-item.vala \
	iscannable-group.vala \
	scannable-group.vala \
	ikeyboard-object.vala \
	xml-deserializer.vala

EXTRA_DIST = \
	external-libs.vapi \
	libxklavier.vapi

#
# Introspection support
#

girdir = $(datadir)/gir-1.0
gir_DATA = Caribou-1.0.gir

typelibdir = $(libdir)/girepository-1.0
typelib_DATA = Caribou-1.0.typelib

Caribou-1.0.gir: _Caribou-1.0.gir
	$(top_srcdir)/tools/fix_gir.py $< > $@

Caribou-1.0.typelib: Caribou-1.0.gir
	@INTROSPECTION_COMPILER@ --shared-library=libcaribou -o $@ $^

Caribou-1.0.gir caribou-internals-1.0.vapi caribou-1.0.vapi: libcaribou.la

CLEANFILES = \
	caribou-1.0.vapi \
	caribou-internals-1.0.vapi \
	Caribou-1.0.typelib \
	Caribou-1.0.gir \
	_Caribou-1.0.gir \
	*.[ch]
