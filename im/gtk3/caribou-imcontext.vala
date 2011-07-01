namespace Caribou {
    [DBus(name = "org.gnome.Caribou.Keyboard")]
    interface Keyboard : Object {
        public abstract void set_cursor_location (int x, int y, int w, int h)
            throws IOError;
        public abstract void set_entry_location (int x, int y, int w, int h)
            throws IOError;
        public abstract void show () throws IOError;
        public abstract void hide () throws IOError;
    }

    class IMContext : Gtk.IMContextSimple {
        private Gdk.Window window;
        private Keyboard keyboard;

        public IMContext () {
        }

        private void get_origin_geometry (Gdk.Window window,
                                          out int x, out int y,
                                          out int w, out int h) {
            window.get_origin (out x, out y);
#if GTK2
            window.get_geometry (null, null, out w, out h, null);
#else
            window.get_geometry (null, null, out w, out h);
#endif
        }

        private Atk.Object? find_focused_accessible (Atk.Object acc) {
            Atk.StateSet state = acc.ref_state_set ();

            bool match = (state.contains_state (Atk.StateType.EDITABLE) &&
                          state.contains_state (Atk.StateType.FOCUSED) &&
                          acc.get_n_accessible_children () == 0);

            if (match)
                return acc;

            for (int i=0;i<acc.get_n_accessible_children ();i++) {
                 Atk.Object child = acc.ref_accessible_child (i);
                 Atk.Object focused_child = find_focused_accessible (child);
                 if (focused_child != null)
                     return focused_child;
            }

            return null;
        }

        private bool get_acc_geometry (Atk.Object acc,
                                       out int x, out int y, out int w, out int h) {
            Atk.Object child = find_focused_accessible (acc);

            if (child == null)
                return false;

            if (!(child is Atk.Component)) {
                stderr.printf ("Accessible is not a component\n");
                return false;
            }

            /* We don't want the keyboard on the paragraph in OOo */
            if (child.get_role() == Atk.Role.PARAGRAPH)
                child = child.get_parent();

            Atk.component_get_extents ((Atk.Component) child,
                                       out x, out y, out w, out h,
                                       Atk.CoordType.SCREEN);
            return true;
        }

        private Gtk.Widget get_window_widget () {
            void *p = null;
            window.get_user_data (&p);
            return p as Gtk.Widget;
        }

        public override void focus_in () {
            GLib.Timeout.add (100, () => {
                    int x=0, y=0, w=0, h=0;
                    Gtk.Widget widget = get_window_widget ();

                    if (widget is Gtk.Editable) {
                        /* Well behaved app */
                        get_origin_geometry (window, out x, out y, out w, out h);
                    } else {
                        Atk.Object acc = widget.get_accessible ();
                        if (acc.get_role () == Atk.Role.REDUNDANT_OBJECT) {
                            /* It is probably Gecko */
                            acc = Atk.get_focus_object ();
                        }

                        if (!get_acc_geometry (acc, out x, out y, out w, out h)) {
                            return false;
                        }
                    }

                    try {
                        keyboard.show ();
                        keyboard.set_entry_location (x, y, w, h);
                    } catch (IOError e) {
                        stderr.printf ("%s\n", e.message);
                    }
                    return false;
                });
        }


        public override void focus_out () {
            try {
                keyboard.hide ();
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
            }
        }

        public override void set_client_window (Gdk.Window window) {
            this.window = window;

            try {
                keyboard = Bus.get_proxy_sync (BusType.SESSION,
                                               "org.gnome.Caribou.Keyboard",
                                               "/org/gnome/Caribou/Keyboard");
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }
        }
    }
}
