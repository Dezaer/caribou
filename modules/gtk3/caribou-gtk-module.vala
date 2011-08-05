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
        private GLib.HashTable<Gtk.Window, bool> windows;
        private Keyboard keyboard;

        public GtkModule () {
            windows = new GLib.HashTable<Gtk.Window, bool> (null, null);
            try {
                keyboard = Bus.get_proxy_sync (BusType.SESSION,
                                               "org.gnome.Caribou.Keyboard",
                                               "/org/gnome/Caribou/Keyboard");
                add_tracker ();

                // Need to use a timeout because there is currently no other
                // way to know whether a new window has been created
                // https://bugzilla.gnome.org/show_bug.cgi?id=655828
                GLib.Timeout.add_seconds (10, () => { add_tracker ();
                                                      return true; });
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }

        }

        private void add_tracker () {
            GLib.List<weak Gtk.Window> toplevels;

            toplevels = Gtk.Window.list_toplevels ();
            foreach (Gtk.Window window in toplevels) {
                if (!windows.lookup (window)) {
                    window.notify["has-toplevel-focus"].connect (toplevel_focus_changed);
                    window.set_focus.connect (window_focus_changed);
                    window.destroy.connect (() => { windows.remove (window); });
                    windows.insert (window, true);
                }
            }
        }

        private void toplevel_focus_changed (Object obj, ParamSpec prop) {
            Gtk.Window window = (Gtk.Window) obj;
            if (window.has_toplevel_focus)
                do_focus_change (window.get_focus ());
        }

        private void window_focus_changed (Gtk.Window window,
                                           Gtk.Widget? widget) {
            do_focus_change (widget);
        }

        private void do_focus_change (Gtk.Widget? widget) {
            uint32 timestamp = Gtk.get_current_event_time ();
            if (widget != null && (widget is Gtk.Entry || widget is Gtk.TextView) && widget is Gtk.Editable) {
                Gdk.Window current_window = widget.get_window ();
                int x = 0, y = 0, w = 0, h = 0;
                if (current_window != null)
                    get_origin_geometry (current_window, out x, out y, out w, out h);

                try {
                    keyboard.show (timestamp);
                    keyboard.set_entry_location (x, y, w, h);
                } catch (IOError e) {
                    stderr.printf ("%s\n", e.message);
                }
            } else {
                try {
                    keyboard.hide (timestamp);
                } catch (IOError e) {
                    stderr.printf ("%s\n", e.message);
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

    }
}
