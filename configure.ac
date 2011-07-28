AC_PREREQ([2.63])
AC_INIT([caribou],
        [0.3.3],
        [https://bugzilla.gnome.org/enter_bug.cgi?product=caribou],
        [caribou])

AC_CONFIG_MACRO_DIR([m4])

AM_PROG_LIBTOOL

AM_INIT_AUTOMAKE([1.11 -Wno-portability])
AM_MAINTAINER_MODE([enable])
# Support silent build rules. Disable by either passing --disable-silent-rules
# to configure or passing V=1 to make
AM_SILENT_RULES([yes])

AM_PATH_GLIB_2_0(2.27.5,,,gobject)
if test "$GLIB_LIBS" = ""; then
   AC_MSG_ERROR(GLIB 2.27.5 or later is required to build libcaribou)
fi

dnl == check for python ==
AM_PATH_PYTHON(2.4)

dnl == Library dependencies ==
PYGOBJECT_REQUIRED=2.27.92
GTK_REQUIRED=3.0.0
CLUTTER_REQUIRED=1.5.11
GDK_REQUIRED=3.0.0

PKG_CHECK_MODULES(CARIBOU, [
  pygobject-2.0 >= $PYGOBJECT_REQUIRED,
  gtk+-3.0      >= $GTK_REQUIRED,
  clutter-1.0   >= $CLUTTER_REQUIRED
  ])
AC_SUBST(CARIBOU_CFLAGS)
AC_SUBST(CARIBOU_LIBS)

AM_PROG_VALAC([0.9.3])
AC_SUBST(VALAC)
AC_SUBST(VALAFLAGS)

PKG_CHECK_MODULES(LIBCARIBOU, [
  gdk-3.0 >= $GDK_REQUIRED,
  xtst,
  x11,
  libxklavier,
  libxml-2.0,
  gee-1.0
  ])
AC_SUBST(LIBCARIBOU_CFLAGS)
AC_SUBST(LIBCARIBOU_LIBS)

dnl == i18n ==
GETTEXT_PACKAGE=caribou
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", [The gettext package])
AM_GLIB_GNU_GETTEXT

dnl == GTK modules ==
AC_ARG_ENABLE(gtk3_module,
    AS_HELP_STRING([--enable-gtk3-module],
                   [Build GTK3 module]),
    [enable_gtk3_module=$enableval],
    [enable_gtk3_module=yes]
)
AM_CONDITIONAL([ENABLE_GTK3_MODULES], [test x"$enable_gtk3_module" = x"yes"])

if test x"$enable_gtk3_module" = x"yes"; then
    PKG_CHECK_MODULES(GTK3, [
        gtk+-3.0
    ])

    GTK3_MODULES_DIR="$libdir"/gtk-3.0/modules
    AC_SUBST(GTK3_MODULES_DIR)
fi

AC_ARG_ENABLE(gtk2_module,
    AS_HELP_STRING([--enable-gtk2-module],
                   [Build GTK2 module]),
    [enable_gtk2_module=$enableval],
    [enable_gtk2_module=yes]
)
AM_CONDITIONAL([ENABLE_GTK2_MODULES], [test x"$enable_gtk2_module" = x"yes"])

if test x"$enable_gtk2_module" = x"yes"; then
    PKG_CHECK_MODULES(GTK2, [
        gtk+-2.0
    ])

    GTK2_MODULES_DIR="$libdir"/gtk-2.0/modules
    AC_SUBST(GTK2_MODULES_DIR)
fi

dnl == GSettings ==
GLIB_GSETTINGS

dnl == intltool check ==
IT_PROG_INTLTOOL([0.35.0])

dnl == Documentation ==
GNOME_DOC_INIT

dnl == GObject introspection ==
GOBJECT_INTROSPECTION_REQUIRE([0.10.7])

dnl == generate makefiles ==
AC_OUTPUT([
Makefile
po/Makefile.in
caribou/Makefile
caribou/i18n.py
caribou/antler/Makefile
caribou/settings/Makefile
caribou/daemon/Makefile
bin/Makefile
bin/caribou
bin/caribou-preferences
bin/antler-keyboard
data/Makefile
data/antler/Makefile
data/layouts/Makefile
data/layouts/touch/Makefile
data/layouts/scan/Makefile
data/layouts/fullscale/Makefile
libcaribou/Makefile
modules/Makefile
modules/gtk3/Makefile
modules/gtk2/Makefile
tools/Makefile
])
