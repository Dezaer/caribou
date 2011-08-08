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
        private Gdk.Display display;
        private Atk.TextRectangle cursor_rect;

        public GtkModule () {
            windows = new GLib.HashTable<Gtk.Window, bool> (null, null);
            try {
                display = Gdk.Display.get_default ();

                keyboard = Bus.get_proxy_sync (BusType.SESSION,
                                               "org.gnome.Caribou.Keyboard",
                                               "/org/gnome/Caribou/Keyboard");
                Gdk.window_add_filter (null, event_filter);
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }
        }

        private Gdk.FilterReturn event_filter (Gdk.XEvent xevent, Gdk.Event evt) {
            Gdk.Window? gdkwindow;
            void* data;
            Gtk.Window window;

#if GTK2
            void* pointer = &xevent;
            X.Event* xev = (X.Event *) pointer;
            gdkwindow = (Gdk.Window) Gdk.x11_xid_table_lookup_for_display (display, (X.ID) xev.xany.window);
#else
            gdkwindow = evt.any.window;
#endif

            if (gdkwindow == null ||
                gdkwindow.get_window_type () != Gdk.WindowType.TOPLEVEL)
                return Gdk.FilterReturn.CONTINUE;

            Gdk.window_get_user_data (gdkwindow, out data);
            if (data == null || !(data is Gtk.Window))
                return Gdk.FilterReturn.CONTINUE;

            window = (Gtk.Window *) data;
            if (!windows.lookup (window)) {
                windows.insert (window, true);
                window.notify["has-toplevel-focus"].connect (toplevel_focus_changed);
                window.set_focus.connect (window_focus_changed);
                window.destroy.connect (() => { windows.remove (window); });
            }

            return Gdk.FilterReturn.CONTINUE;
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
#if GTK2
            uint32 timestamp = Gdk.x11_display_get_user_time (display);
#else
            uint32 timestamp = Gdk.X11Display.get_user_time (display);
#endif

            if ((widget is Gtk.Editable &&
                 ((Gtk.Editable) widget).get_editable ()) ||
                (widget is Gtk.TextView &&
                 ((Gtk.TextView) widget).get_editable ())) {
                Gdk.Window current_window = widget.get_window ();
                Atk.Object object = widget.get_accessible ();
                int x = 0, y = 0, w = 0, h = 0;
                int caret_offset = 0;

                if (object is Atk.Text) {
                    caret_offset = ((Atk.Text) object).get_caret_offset ();
                    ((Atk.Text) object).get_range_extents (0, caret_offset, Atk.CoordType.SCREEN, cursor_rect);

                    x = cursor_rect.x; y  = cursor_rect.y; w = cursor_rect.width; h = cursor_rect.height;
                }
                else {
                    if (current_window != null)
                        get_origin_geometry (current_window, out x, out y, out w, out h);
                }

                try {
                    keyboard.show (timestamp);
                    keyboard.set_cursor_location (x, y, w, h);
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
