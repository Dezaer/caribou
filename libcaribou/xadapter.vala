using Xkl;
using Gdk;
using Xkb;
using XTest;
using X;

namespace Caribou {
    public class XAdapter : Object {

        /* Signals */
        public signal void modifiers_changed (uint modifiers);
        public signal void group_changed (uint gid, string group, string variant);

        /* Private properties */
        static XAdapter instance;
        X.Display xdisplay;
        X.ID xid;
        Xkb.Desc xkbdesc;
        Xkl.Engine xkl_engine;
        uint reserved_keysym;
        uchar reserved_keycode;
        uchar modifiers;
        uchar group;

        public delegate void KeyButtonCallback (uint keybuttoncode, bool pressed);

        private class KeyButtonHandler {
            public KeyButtonCallback cb { get; private set; }
            public KeyButtonHandler (KeyButtonCallback cb) {
                this.cb = cb;
            }
        }

        HashTable<uint, KeyButtonHandler> button_funcs;
        HashTable<uint, KeyButtonHandler> key_funcs;

        construct {
            Xkb.State xkb_state;
            unowned Xkl.State xkl_state;

            Gdk.Window rootwin = Gdk.get_default_root_window();
            this.xdisplay = Gdk.X11Display.get_xdisplay (rootwin.get_display ());
            xid = Gdk.X11Window.get_xid (rootwin);
            this.xkbdesc = Xkb.get_keyboard (this.xdisplay,
                                             Xkb.GBN_AllComponentsMask,
                                             Xkb.UseCoreKbd);
            this.xkl_engine = Xkl.Engine.get_instance (this.xdisplay);
            xkl_engine.start_listen (Xkl.EngineListenModes.TRACK_KEYBOARD_STATE);
            xkl_state = this.xkl_engine.get_current_state ();
            this.group = (uchar) xkl_state.group;
            Signal.connect_object (xkl_engine, "X-state-changed",
                                   (Callback) xkl_state_changed,
                                   this, ConnectFlags.AFTER);

            Xkb.get_state (this.xdisplay, Xkb.UseCoreKbd, out xkb_state);
            this.modifiers = xkb_state.mods;

            this.reserved_keycode = 0;

            button_funcs = new HashTable<uint, KeyButtonHandler> (direct_hash,
                                                                  direct_equal);

            key_funcs = new HashTable<uint, KeyButtonHandler> (direct_hash,
                                                               direct_equal);

            Xkb.select_events (
                this.xdisplay, Xkb.UseCoreKbd,
                Xkb.StateNotifyMask | Xkb.AccessXNotifyMask,
                Xkb.StateNotifyMask | Xkb.AccessXNotifyMask);

            ((Gdk.Window) null).add_filter (x_event_filter); // Did I blow your mind?
        }

        ~XAdapter () {
            Xkb.free_keyboard(this.xkbdesc, Xkb.GBN_AllComponentsMask, true);
        }

        public static XAdapter get_default() {
            if (instance == null)
                instance = new XAdapter ();
            return instance;
        }

        private Gdk.FilterReturn x_event_filter (Gdk.XEvent xevent, Gdk.Event event) {
            void* pointer = &xevent;
            Xkb.Event* xkbev = (Xkb.Event *) pointer;
            X.Event* xev = (X.Event *) pointer;

			this.xkl_engine.filter_events(xev);

            if (xev.type == X.EventType.ButtonPress ||
                xev.type == X.EventType.ButtonRelease) {
                KeyButtonHandler handler =
                    (KeyButtonHandler) button_funcs.lookup (xev.xbutton.button);
                if (handler != null)
                    handler.cb (xev.xbutton.button,
                                xev.type == X.EventType.ButtonPress);
            } else if (xev.type == X.EventType.KeyPress ||
                       xev.type == X.EventType.KeyRelease) {

                KeyButtonHandler handler =
                    (KeyButtonHandler) key_funcs.lookup (xev.xkey.keycode);
                if (handler != null)
                    handler.cb (xev.xkey.keycode,
                                xev.type == X.EventType.KeyPress);
            } else if (xkbev.any.xkb_type == Xkb.StateNotify) {
                Xkb.StateNotifyEvent *sevent = &xkbev.state;
				if ((sevent.changed & Xkb.ModifierStateMask) != 0) {
                    this.modifiers = (uchar) sevent.mods;
                }
            }

            return Gdk.FilterReturn.CONTINUE;
        }

		private static void xkl_state_changed (Xkl.Engine xklengine, int type, int group, bool restore, XAdapter self) {
			string group_name;
			string variant_name;

			self.group = (uchar) group;
			self.get_current_group (out group_name, out variant_name);
			self.group_changed (self.group, group_name, variant_name);
		}

        private uchar get_reserved_keycode () {
            uchar i;
            unowned Xkb.Desc xkbdesc = this.xkbdesc;

            for (i = xkbdesc.max_key_code; i >= xkbdesc.min_key_code; --i) {
                if (xkbdesc.map.key_sym_map[i].kt_index[0] == Xkb.OneLevelIndex) {
                    if (X.keycode_to_keysym (this.xdisplay, i, 0) != 0) {
                        Gdk.error_trap_push ();
                        this.xdisplay.grab_key (i, 0,
                                    Gdk.x11_get_default_root_xwindow (), true,
                                    X.GrabMode.Sync, X.GrabMode.Sync);
                        this.xdisplay.flush ();
                        this.xdisplay.ungrab_key (
                            i, 0, Gdk.x11_get_default_root_xwindow ());
                        if (Gdk.error_trap_pop () == 0)
                            return i;
                    }
                }
            }

            return (uchar) this.xdisplay.keysym_to_keycode (0x0023); // XK_numbersign
        }

        private void replace_keycode (uint keysym) {
            if (this.reserved_keycode == 0) {
                this.reserved_keycode = get_reserved_keycode ();
                this.reserved_keysym = X.keycode_to_keysym (this.xdisplay,
                                                            this.reserved_keycode, 0);
            }

            this.xdisplay.flush ();
            uint offset = this.xkbdesc.map.key_sym_map[this.reserved_keycode].offset;

            this.xkbdesc.map.syms[offset] = keysym;

            Xkb.set_map (this.xdisplay, Xkb.AllMapComponentsMask, this.xkbdesc);
            /**
             *  FIXME: the use of XkbChangeMap, and the reuse of the priv->xkb_desc
             *  structure, would be far preferable. HOWEVER it does not seem to work
             *  using XFree 4.3.
             **/

            this.xdisplay.flush ();

            if (keysym != this.reserved_keysym)
                GLib.Timeout.add (500, reset_reserved);
        }

        private bool reset_reserved () {
            replace_keycode (this.reserved_keysym);
            return false;
        }

        private bool best_keycode_keyval_match (uint keyval,
                                                out uchar keycode,
                                                out uint modmask) {
            Gdk.Keymap kmap= Gdk.Keymap.get_default ();
            Gdk.KeymapKey[] kmk;

            if (!kmap.get_entries_for_keyval (keyval, out kmk))
                return false;

            Gdk.KeymapKey best_match = kmk[0];

            foreach (KeymapKey km in kmk)
               if (km.group == this.group)
                   best_match = km;

               keycode = (uchar) best_match.keycode;
               modmask = (best_match.level == 1) ? Gdk.ModifierType.SHIFT_MASK : 0;

               return true;
        }

        private uchar keycode_for_keyval (uint keyval, out uint modmask) {
            uchar keycode = 0;

            if (!best_keycode_keyval_match (keyval, out keycode, out modmask)) {
                replace_keycode (keyval);
                keycode = this.reserved_keycode;
                modmask = 0;
            }

            return keycode;
        }

        public void keyval_press (uint keyval) {
            uint mask;
            uchar keycode = keycode_for_keyval (keyval, out mask);

            if (mask != 0)
                mod_latch (mask);

            XTest.fake_key_event (this.xdisplay, keycode, true, X.CURRENT_TIME);
            this.xdisplay.flush ();
        }

        public void keyval_release (uint keyval) {
            uchar keycode = keycode_for_keyval (keyval, null);

            XTest.fake_key_event (this.xdisplay, keycode, false, X.CURRENT_TIME);
            this.xdisplay.flush ();
        }

        public void mod_lock (uint mask) {
            Xkb.lock_modifiers (this.xdisplay, Xkb.UseCoreKbd, mask, mask);
            this.xdisplay.flush ();
        }

        public void mod_unlock (uint mask) {
            Xkb.lock_modifiers (this.xdisplay, Xkb.UseCoreKbd, mask, 0);
            this.xdisplay.flush();
        }

        public void mod_latch (uint mask) {
            Xkb.latch_modifiers (this.xdisplay, Xkb.UseCoreKbd, mask, mask);
            this.xdisplay.flush ();
        }

        public void mod_unlatch (uint mask) {
            Xkb.latch_modifiers (this.xdisplay, Xkb.UseCoreKbd, mask, 0);
            this.xdisplay.flush ();
        }

        public uint get_current_group (out string group_name,
                                       out string variant_name) {
            Xkl.ConfigRec config_rec = new Xkl.ConfigRec ();
            config_rec.get_from_server (this.xkl_engine);
            group_name = config_rec.layouts[this.group];
            variant_name = config_rec.variants[this.group];
            if (variant_name == null)
                variant_name = "";

            return this.group;
        }

        public void get_groups (out string[] group_names,
                                out string[] variant_names) {
            int i;
            Xkl.ConfigRec config_rec = new Xkl.ConfigRec ();
            config_rec.get_from_server (this.xkl_engine);

            for (i=0; i<4; i++)
                if (config_rec.layouts[i] == null) {
                    i--;
                    break;
                }

            group_names = new string[i+1];
            variant_names = new string[i+1];

            for (; i>=0; i--) {
                group_names[i] = config_rec.layouts[i];
                if (config_rec.variants[i] != null)
                    variant_names[i] = config_rec.variants[i];
                else
                    variant_names[i] = "";
            }
        }

        public void register_key_func (uint keyval, KeyButtonCallback? func) {
            uchar keycode;
            uint modmask;

            if (!best_keycode_keyval_match (keyval, out keycode, out modmask)) {
                GLib.warning ("No good keycode for %d", (int) keyval);
                return;
            }

            if (func != null) {
                var handler = new KeyButtonHandler (func);
                key_funcs.insert (keycode, handler);
                xdisplay.grab_key ((int)keycode, 0, xid,
                                   true, GrabMode.Async, GrabMode.Async);

            } else {
                key_funcs.remove (keycode);
                xdisplay.ungrab_key ((int)keycode, 0, xid);
            }
        }

        public void register_button_func (uint button, KeyButtonCallback? func) {
            if (func != null) {
                var handler = new KeyButtonHandler (func);
                button_funcs.insert (button, handler);
                xdisplay.grab_button (button, 0, xid, true,
                                      X.EventMask.ButtonPressMask |
                                      X.EventMask.ButtonReleaseMask,
                                      GrabMode.Async, GrabMode.Async, 0, 0);

            } else {
                button_funcs.remove (button);
                xdisplay.ungrab_button (button, 0, xid);
            }
        }

    }
}
