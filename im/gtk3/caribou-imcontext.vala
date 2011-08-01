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

    class IMContext {
        private GLib.List<Gtk.Window> windows;
        private Gdk.Window current_window;
        private Keyboard keyboard;
        private uint focus_tracker_id;

        public IMContext () {
            try {
                keyboard = Bus.get_proxy_sync (BusType.SESSION,
                                               "org.gnome.Caribou.Keyboard",
                                               "/org/gnome/Caribou/Keyboard");
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }


            GLib.Timeout.add (60, () => {
                Atk.Object acc;
                GLib.List<Gtk.Window> toplevels;

                toplevels = Gtk.Window.list_toplevels();
                foreach (Gtk.Window widget in toplevels) {
                    widget.grab_focus();
                    acc = widget.get_accessible();
                    current_window = widget.get_root_window();
                    caribou_focus_tracker(acc);

                    // FIXME: vala's annotation for Gtk.Window.list_toplevels()
                    // is wrong, so we have to leak the windows to avoid
                    // a double-free.
                    windows.append(widget);
                }
                return true;

            });

            //focus_tracker_id = Atk.add_focus_tracker (caribou_focus_tracker);
        }


        private void caribou_focus_tracker (Atk.Object focus_object) {
            int x=0, y=0, w=0, h=0;
            if (!get_acc_geometry (focus_object, out x, out y, out w, out h)) {
                get_origin_geometry (current_window, out x, out y, out w, out h);
            }

            try {
                keyboard.show ();
                keyboard.set_entry_location (x, y, w, h);
            } catch (IOError e) {
                stderr.printf ("%s\n", e.message);
            }
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
            Atk.Object child = null;


            if (acc.get_role () == Atk.Role.REDUNDANT_OBJECT) {
                /* It is probably Gecko */
                child = Atk.get_focus_object ();
            } else {
                child = find_focused_accessible (acc);
            }

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

    }
}
