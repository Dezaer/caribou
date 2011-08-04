namespace Caribou {
    [DBus(name = "org.gnome.Caribou.Keyboard")]
    public abstract class KeyboardService : Object {
        public abstract void set_cursor_location(int x, int y, int w, int h);
        public abstract void set_entry_location(int x, int y, int w, int h);
        public abstract void show(uint32 timestamp);
        public abstract void hide(uint32 timestamp);

        protected void register_keyboard (string name) {
            string dbus_name = @"org.gnome.Caribou.$name";
            Bus.own_name (BusType.SESSION, dbus_name, BusNameOwnerFlags.NONE,
                          on_bus_acquired, on_impl_name_acquired, on_impl_name_lost);
        }

        private void on_bus_acquired (DBusConnection conn) {
        }

        private void on_impl_name_lost (DBusConnection conn, string name) {
            stderr.printf ("Could not acquire %s\n", name);
        }

        private void on_name_lost (DBusConnection conn, string name) {
            stderr.printf ("Could not acquire %s\n", name);
            name_lost (name);
        }

        protected virtual void name_lost (string name) {
            stderr.printf ("default\n");
        }

        private void on_impl_name_acquired (DBusConnection conn, string name) {
            Bus.own_name (
                BusType.SESSION, "org.gnome.Caribou.Keyboard",
                BusNameOwnerFlags.ALLOW_REPLACEMENT | BusNameOwnerFlags.REPLACE,
                on_bus_acquired, on_generic_name_acquired, on_name_lost);
        }

        private void on_generic_name_acquired (DBusConnection conn, string name) {
            try {
                string path = @"/org/gnome/Caribou/Keyboard";
                conn.register_object (path, this);
            } catch (IOError e) {
                stderr.printf ("Could not register service: %s\n", e.message);
            }
        }

    }
}
