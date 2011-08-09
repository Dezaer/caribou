#include <gtk/gtk.h>
#include <gtk/gtkimmodule.h>
#include "caribou-gtk-module.h"
#include <stdio.h>

#define CARIBOU_LOCALDIR ""

G_MODULE_EXPORT CaribouGtkModule * gtk_module;

G_MODULE_EXPORT CaribouGtkModule *
gtk_module_init (gint *argc, gchar ***argv[]) {
    CaribouGtkModule *context = caribou_gtk_module_new ();
    gtk_module = context;
        return context;
}

G_MODULE_EXPORT const gchar*
g_module_check_init (GModule *module)
{
    return gtk_check_version (GTK_MAJOR_VERSION, 0, 0);
}

G_MODULE_EXPORT void
g_module_unload(GModule *module) {
    caribou_gtk_module_unload (gtk_module);
}
