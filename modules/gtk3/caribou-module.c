#include <gtk/gtk.h>
#include <gtk/gtkimmodule.h>
#include "caribou-gtk-modules.h"
#include <stdio.h>

#define CARIBOU_LOCALDIR ""

G_MODULE_EXPORT CaribouGtkModules *
gtk_module_init (gint *argc, gchar ***argv[]) {
    CaribouGtkModules *context = caribou_gtk_modules_new ();
        return context;
}

G_MODULE_EXPORT const gchar*
g_module_check_init (GModule *module)
{
    return glib_check_version (GLIB_MAJOR_VERSION,
                               GLIB_MINOR_VERSION,
                               0);
}

