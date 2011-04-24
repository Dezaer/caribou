/*
 * Copyright (C) 2011, Eitan Isaacson <eitan@monotonous.org>
 */

#include "caribou-virtual-keyboard.h"
#include "caribou-marshal.h"
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <X11/XKBlib.h>
#include <libxklavier/xklavier.h>

#define XDISPLAY GDK_DISPLAY_XDISPLAY(gdk_display_get_default ())

struct _CaribouVirtualKeyboardPrivate {
  XkbDescPtr  xkbdesc;
  XklEngine  *xkl_engine;
  KeyCode reserved_keycode;
  KeySym reserved_keysym;
  gchar modifiers;
  gchar group;
};

G_DEFINE_TYPE (CaribouVirtualKeyboard, caribou_virtual_keyboard, G_TYPE_OBJECT)

enum {
    KB_MODIFIERS_CHANGED,
    KB_GROUP_CHANGED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL] = { 0 };

static void
dispose (GObject *object)
{
  CaribouVirtualKeyboard *self = CARIBOU_VIRTUAL_KEYBOARD (object);

  XkbFreeKeyboard (self->priv->xkbdesc, XkbGBN_AllComponentsMask, True);

  G_OBJECT_CLASS (caribou_virtual_keyboard_parent_class)->dispose (object);
}

/* A hack stolen from AT-SPI registry */
static guint64
_get_reserved_keycode (CaribouVirtualKeyboard *self)
{
  guint64 i;
  XkbDescPtr xkbdesc = self->priv->xkbdesc;

  for (i = xkbdesc->max_key_code; i >= xkbdesc->min_key_code; --i)
    {
	  if (xkbdesc->map->key_sym_map[i].kt_index[0] == XkbOneLevelIndex)
        {
	      if (XKeycodeToKeysym (XDISPLAY, i, 0) != 0)
            {
              /* don't use this one if there's a grab client! */
              gdk_error_trap_push ();
              XGrabKey (XDISPLAY, i, 0,
                        gdk_x11_get_default_root_xwindow (),
                        TRUE,
                        GrabModeSync, GrabModeSync);
              XSync (XDISPLAY, TRUE);
              XUngrabKey (XDISPLAY, i, 0,
                          gdk_x11_get_default_root_xwindow ());
              if (!gdk_error_trap_pop ())
                return i;
            }
        }
    }

  return XKeysymToKeycode (XDISPLAY, XK_numbersign);
}

static void _replace_keycode (CaribouVirtualKeyboard *self, KeySym keysym);

static gboolean
_reset_reserved (gpointer user_data)
{
  CaribouVirtualKeyboard *self = CARIBOU_VIRTUAL_KEYBOARD (user_data);

  _replace_keycode (self, self->priv->reserved_keysym);

  return FALSE;
}

static void
_replace_keycode (CaribouVirtualKeyboard *self, KeySym keysym)
{
  CaribouVirtualKeyboardPrivate *priv = self->priv;
  gint offset;
  g_return_if_fail (priv->xkbdesc != NULL && priv->xkbdesc->map != NULL);

  XFlush (XDISPLAY);
  XSync (XDISPLAY, False);

  offset = priv->xkbdesc->map->key_sym_map[priv->reserved_keycode].offset;

  priv->xkbdesc->map->syms[offset] = keysym;

  XkbSetMap (XDISPLAY, XkbAllMapComponentsMask, priv->xkbdesc);
  /**
   *  FIXME: the use of XkbChangeMap, and the reuse of the priv->xkb_desc structure,
   * would be far preferable.
   * HOWEVER it does not seem to work using XFree 4.3.
   **/
  /*	    XkbChangeMap (XDISPLAY, priv->xkb_desc, priv->changes); */
  XFlush (XDISPLAY);
  XSync (XDISPLAY, False);

  if (keysym != priv->reserved_keysym)
    g_timeout_add (500, _reset_reserved, self);
}

static GdkFilterReturn
_filter_x_evt (GdkXEvent *gdk_xevent, GdkEvent *event, gpointer data)
{
  CaribouVirtualKeyboard *self = CARIBOU_VIRTUAL_KEYBOARD (data);
  XkbEvent *xevent = gdk_xevent;

  if (xevent->any.xkb_type == XkbStateNotify) {
    XkbStateNotifyEvent *sevent = &xevent->state;
    if (sevent->changed & XkbGroupStateMask) {
      XklConfigRec *config_rec;
      self->priv->group = sevent->group;
      config_rec = xkl_config_rec_new ();
      xkl_config_rec_get_from_server (config_rec, self->priv->xkl_engine);
      g_signal_emit (self, signals[KB_GROUP_CHANGED], 0,
                     sevent->group,
                     config_rec->layouts[sevent->group],
                     config_rec->variants[sevent->group]);
      g_object_unref (config_rec);
    } else if (sevent->changed & XkbModifierStateMask) {
      self->priv->modifiers = sevent->mods;
      g_signal_emit (self, signals[KB_MODIFIERS_CHANGED], 0, sevent->mods);
    }
  }

  return GDK_FILTER_CONTINUE;
}

static void
caribou_virtual_keyboard_init (CaribouVirtualKeyboard *self)
{
  XkbStateRec sr;

  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), CARIBOU_TYPE_VIRTUAL_KEYBOARD,
                                            CaribouVirtualKeyboardPrivate);

  self->priv->xkbdesc = XkbGetKeyboard(XDISPLAY, XkbGBN_AllComponentsMask,
                                       XkbUseCoreKbd);

  self->priv->xkl_engine = xkl_engine_get_instance (XDISPLAY);

  XkbGetState(XDISPLAY, XkbUseCoreKbd, &sr);

  self->priv->modifiers = sr.mods;
  self->priv->group = sr.group;

  XkbSelectEvents (XDISPLAY,
                   XkbUseCoreKbd, XkbStateNotifyMask | XkbAccessXNotifyMask,
                   XkbStateNotifyMask | XkbAccessXNotifyMask | XkbMapNotifyMask);

  gdk_window_add_filter (NULL, (GdkFilterFunc) _filter_x_evt, self);

  self->priv->reserved_keycode = _get_reserved_keycode (self);
  self->priv->reserved_keysym = XKeycodeToKeysym (XDISPLAY,
                                                  self->priv->reserved_keycode, 0);
}

static void
caribou_virtual_keyboard_class_init (CaribouVirtualKeyboardClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	g_type_class_add_private (klass, sizeof (CaribouVirtualKeyboardPrivate));

	/* virtual method override */
	object_class->dispose = dispose;

	/* signals */

    /**
     * CaribouVirtualKeyboard::modifiers-changed:
     * @virtual_keyboard: the object that received the signal
     * @modifiers: the modifiers that are currently active
     *
     * Emitted when the keyboard modifiers change.
     */
	signals[KB_MODIFIERS_CHANGED] =
      g_signal_new ("modifiers-changed",
                    G_OBJECT_CLASS_TYPE (object_class),
                    G_SIGNAL_RUN_FIRST,
                    0,
                    NULL, NULL,
                    caribou_marshal_NONE__UINT,
                    G_TYPE_NONE, 1, G_TYPE_UINT);

    /**
     * CaribouVirtualKeyboard::group-changed:
     * @virtual_keyboard: the object that received the signal
     * @group: the currently active group
     *
     * Emitted when the keyboard group changes.
     */
	signals[KB_GROUP_CHANGED] =
      g_signal_new ("group-changed",
                    G_OBJECT_CLASS_TYPE (object_class),
                    G_SIGNAL_RUN_FIRST,
                    0,
                    NULL, NULL,
                    caribou_marshal_NONE__UINT_STRING_STRING,
                    G_TYPE_NONE, 3, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING);
}

/**
 * caribou_virtual_keyboard_new:
 *
 * Create a new #CaribouVirtualKeyboard.
 *
 * Returns: A new #CaribouVirtualKeyboard.
 */
CaribouVirtualKeyboard *
caribou_virtual_keyboard_new ()
{
  return g_object_new (CARIBOU_TYPE_VIRTUAL_KEYBOARD, NULL);
}

static KeyCode
keycode_for_keyval (CaribouVirtualKeyboard *self,
                    guint                   keyval,
                    guint                  *modmask)
{
  GdkKeymap *km = gdk_keymap_get_default ();
  GdkKeymapKey *kmk;
  gint len;
  KeyCode keycode = 0;

  g_return_val_if_fail (modmask != NULL, 0);

  if (gdk_keymap_get_entries_for_keyval (km, keyval, &kmk, &len)) {
    gint i;
    GdkKeymapKey best_match = kmk[0];

    for (i=0; i<len; i++)
      if (kmk[i].group == self->priv->group)
        best_match = kmk[i];

    keycode = best_match.keycode;
    *modmask = (best_match.level == 1) ? GDK_SHIFT_MASK : 0;
    g_free (kmk);
  } else {
    _replace_keycode (self, keyval);
    keycode = self->priv->reserved_keycode;
  }

  return keycode;
}

/**
 * caribou_virtual_keyboard_mod_latch:
 * @mask: the modifier mask
 *
 * Simulate a keyboard modifier key press
 */
void
caribou_virtual_keyboard_mod_latch (CaribouVirtualKeyboard *self,
                                    int                     mask)
{
  XkbLatchModifiers(XDISPLAY, XkbUseCoreKbd, mask, mask);

  gdk_display_sync (gdk_display_get_default ());
}

/**
 * caribou_virtual_keyboard_mod_unlatch:
 * @mask: the modifier mask
 *
 * Simulate a keyboard modifier key release
 */
void
caribou_virtual_keyboard_mod_unlatch (CaribouVirtualKeyboard *self,
                                      int                     mask)
{
  XkbLatchModifiers(XDISPLAY, XkbUseCoreKbd, mask, 0);
  gdk_display_sync (gdk_display_get_default ());
}

/**
 * caribou_virtual_keyboard_keyval_press:
 * @keyval: the keyval to simulate
 *
 * Simulate a keyboard key press with a given keyval.
 */
void
caribou_virtual_keyboard_keyval_press (CaribouVirtualKeyboard *self,
                                       guint                   keyval)
{
  guint mask;
  KeyCode keycode = keycode_for_keyval (self, keyval, &mask);

  if (mask != 0)
    caribou_virtual_keyboard_mod_latch (self, mask);

  XTestFakeKeyEvent(XDISPLAY, keycode, TRUE, CurrentTime);
  gdk_display_sync (gdk_display_get_default ());
}

/**
 * caribou_virtual_keyboard_keyval_release:
 * @keyval: the keyval to simulate
 *
 * Simulate a keyboard key press with a given keyval.
 */
void
caribou_virtual_keyboard_keyval_release (CaribouVirtualKeyboard *self,
                                         guint                   keyval)
{
  guint mask;
  KeyCode keycode = keycode_for_keyval (self, keyval, &mask);

  XTestFakeKeyEvent(XDISPLAY, keycode, FALSE, CurrentTime);

  if (mask != 0)
    caribou_virtual_keyboard_mod_unlatch (self, mask);

  gdk_display_sync (gdk_display_get_default ());
}
/**
 * caribou_virtual_keyboard_get_current_group:
 * @group_name: (out) (transfer full): Location to store name of current group,
 *   or NULL.
 * @variant_name: (out) (transfer full): Location to store name of current group's
 *   variant or NULL.
 *
 * Retrieve the keyboard's currently active group.
 *
 * Returns: Current group index.
 */
guint
caribou_virtual_keyboard_get_current_group (CaribouVirtualKeyboard  *self,
                                            gchar                  **group_name,
                                            gchar                  **variant_name)
{
  CaribouVirtualKeyboardPrivate *priv = self->priv;

  if (group_name != NULL || variant_name != NULL) {
    XklConfigRec *config_rec = xkl_config_rec_new ();
    xkl_config_rec_get_from_server (config_rec, priv->xkl_engine);

    if (group_name != NULL)
      *group_name = g_strdup (config_rec->layouts[priv->group]);

    if (variant_name != NULL)
      *variant_name = g_strdup (config_rec->variants[priv->group]);

    g_object_unref (config_rec);
  }

  return priv->group;
}

/**
 * caribou_virtual_keyboard_get_groups:
 * @group_names: (out) (transfer full) (array zero-terminated=1): Location to store
 *   names of available groups or NULL.
 * @variant_names: (out) (transfer full) (array zero-terminated=1): Location to store
 *   variants of available groups or NULL.
 *
 * Retrieve the keyboard's available groups.
 */
void
caribou_virtual_keyboard_get_groups (CaribouVirtualKeyboard   *self,
                                     gchar                  ***group_names,
                                     gchar                  ***variant_names)
{
  CaribouVirtualKeyboardPrivate *priv = self->priv;

  if (group_names != NULL || variant_names != NULL) {
    XklConfigRec *config_rec = xkl_config_rec_new ();
    xkl_config_rec_get_from_server (config_rec, priv->xkl_engine);

    if (group_names != NULL)
      *group_names = g_strdupv (config_rec->layouts);

    if (variant_names != NULL)
      *variant_names = g_strdupv (config_rec->variants);

    g_object_unref (config_rec);
  }
}
