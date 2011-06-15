using GLib;

namespace Caribou {
    public class KeyModel : GLib.Object, IScannableItem, IKeyboardObject {
        public string align { get; set; default = "center"; }
        public double width { get; set; default = 1.0; }
        public string toggle { get; set; default = ""; }

        public bool show_subkeys { get; private set; default = false; }
        public string name { get; private set; }
        public uint keyval { get; private set; }

        public bool scan_stepping { get; internal set; }
        private bool _scan_selected;
        public bool scan_selected {
            get {
                return _scan_selected;
            }

            internal set {
                _scan_selected = value;
                if (_scan_selected)
                    activate ();
            }
        }

        private uint hold_tid;
        private XAdapter xadapter;
        private Gee.ArrayList<KeyModel> extended_keys;

        public signal void key_pressed ();
        public signal void key_released ();
        public signal void key_hold_end ();
        public signal void key_hold ();

        public KeyModel (string name) {
            this.name = name;
            xadapter = XAdapter.get_default();
            keyval = Gdk.keyval_from_name (name);
            extended_keys = new Gee.ArrayList<KeyModel> ();
        }

        internal void add_subkey (KeyModel key) {
            key.key_activated.connect(on_subkey_activated);
            extended_keys.add (key);
        }

        private void on_subkey_activated (KeyModel key) {
            key_activated (key);
            show_subkeys = false;
        }

        public void press () {
            hold_tid = GLib.Timeout.add(1000, on_key_held);
            key_pressed();
        }

        public void release () {
            key_released();
            if (hold_tid != 0) {
                GLib.Source.remove (hold_tid);
                hold_tid = 0;
                key_activated (this);
                if (keyval != 0) {
                    xadapter.keyval_press(keyval);
                    xadapter.keyval_release(keyval);
                }
            } else {
                key_hold_end ();
            }
        }

        private bool on_key_held () {
            hold_tid = 0;
            if (extended_keys.size != 0)
                show_subkeys = true;
            key_hold ();
            return false;
        }

        public KeyModel[] get_extended_keys () {
            return (KeyModel[]) extended_keys.to_array ();
        }

        public KeyModel[] get_keys () {
            Gee.ArrayList<KeyModel> all_keys = new Gee.ArrayList<KeyModel> ();
            all_keys.add (this);
            all_keys.add_all (extended_keys);
            return (KeyModel[]) all_keys.to_array ();
        }

        public IKeyboardObject[] get_children () {
            return (IKeyboardObject[]) extended_keys.to_array ();
        }

        public void activate () {
            press ();
            GLib.Timeout.add(200, () => { release (); return false; });
        }
    }
}