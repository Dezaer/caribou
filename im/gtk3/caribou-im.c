#include <gtk/gtk.h>
#include <gtk/gtkimmodule.h>
#include "caribou-imcontext.h"
#include <stdio.h>

#define CARIBOU_LOCALDIR ""
static const GtkIMContextInfo caribou_im_info = {
    "caribou",
    "Caribou OSK helper module",
    "caribou",
    "",
    "*"
};

G_MODULE_EXPORT CaribouIMContext *
gtk_module_init (gint *argc, gchar ***argv[]) {
    g_print("Caribou module loaded \n");
    CaribouIMContext *context = caribou_im_context_new ();
        return context;
}

G_MODULE_EXPORT const gchar*
g_module_check_init (GModule *module)
{
    return glib_check_version (GLIB_MAJOR_VERSION,
                               GLIB_MINOR_VERSION,
                               0);
}

