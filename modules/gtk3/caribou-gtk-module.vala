namespace Caribou {
    [DBus(name = "org.gnome.Caribou.Keyboard")]
    interface Keyboard : Object {
        public abstract void set_cursor_location (int x, int y, int w, int h)
            throws IOError;
        public abstract void set_entry_location (int x, int y, int w, int h)
            throws IOError;
        public abstract void show (uint32 timestamp) throws IOError;
        public abstract void hide (uint32 timestamp) throws IOError;
    }

    class GtkModule {
        private GLib.List<Gtk.Window> windows;
        private Keyboard keyboard;

        public GtkModule () {
            windows = new GLib.List<Gtk.Window>();
            try {
                keyboard = Bus.get_proxy_sync (BusType.SESSION,
                                               "org.gnome.Caribou.Keyboard",
                                               "/org/gnome/Caribou/Keyboard");
                add_tracker ();

                GLib.Timeout.add (60, () => { add_tracker ();
                                              return true; });
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }

        }

        private void add_tracker () {
            GLib.List<weak Gtk.Window> toplevels;

            toplevels = Gtk.Window.list_toplevels();
            foreach (Gtk.Window window in toplevels) {
                if (windows.find(window) == null) {
                    window.notify["has-toplevel-focus"].connect(get_top_level_focus);
                    windows.append(window);
                }
            }
        }

        private void get_top_level_focus (Object obj, ParamSpec prop) {
            Gtk.Window window = (Gtk.Window) obj;
            if (window.has_toplevel_focus)
                focus_tracker (window, window.get_focus());
        }

        private void focus_tracker (Gtk.Window window, Gtk.Widget? widget) {
            uint32 timestamp = Gtk.get_current_event_time();
            if (widget != null && (widget is Gtk.Entry || widget is Gtk.TextView) && widget is Gtk.Editable) {
                Atk.Object focus_object = widget.get_accessible();
                Gdk.Window current_window = widget.get_window();
                int x=0, y=0, w=0, h=0;
                if (current_window != null && !get_acc_geometry (focus_object, out x, out y, out w, out h)) {
                    get_origin_geometry (current_window, out x, out y, out w, out h);
                }
                try {
                    keyboard.show (timestamp);
                    keyboard.set_entry_location (x, y, w, h);
                } catch (IOError e) {
                    stderr.printf ("%s\n", e.message);
                }
            }
            else {
                try {
                    keyboard.hide (timestamp);
                } catch (IOError e) {
                    stderr.printf("%s\n", e.message);
                }
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
