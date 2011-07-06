using GLib;

namespace Caribou {
    public class KeyModel : GLib.Object, IScannableItem, IKeyboardObject {
        public string align { get; set; default = "center"; }
        public double width { get; set; default = 1.0; }
        public string toggle { get; set; default = ""; }

        private Gdk.ModifierType mod_mask;
        public bool is_modifier {
            get {
                return (mod_mask != 0);
            }

            set {}
        }

        public ModifierState modifier_state;

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

        public signal void key_hold_end ();
        public signal void key_hold ();

        private const ModifierMapEntry mod_map[] = {
            { "Control_L", Gdk.ModifierType.CONTROL_MASK },
            { "Alt_L", Gdk.ModifierType.MOD1_MASK },
            { null, 0 }
        };

        public KeyModel (string name) {
            this.name = name;
            mod_mask = (Gdk.ModifierType) 0;

            int i = 0;
            for (ModifierMapEntry entry=mod_map[i];
                 entry.name != null;
                 entry=mod_map[++i]) {
                if (name == entry.name)
                    mod_mask = entry.mask;
            }

            if (mod_mask == 0)
                keyval = Gdk.keyval_from_name (name);

            xadapter = XAdapter.get_default();
            extended_keys = new Gee.ArrayList<KeyModel> ();
        }

        internal void add_subkey (KeyModel key) {
            key.key_clicked.connect(on_subkey_clicked);
            extended_keys.add (key);
        }

        private void on_subkey_clicked (KeyModel key) {
            key_clicked (key);
            show_subkeys = false;
        }

        public void press () {
            if (is_modifier) {
                if (modifier_state == ModifierState.NONE) {
                    modifier_state = ModifierState.LATCHED;
                    xadapter.mod_lock(mod_mask);
                } else {
                    modifier_state = ModifierState.NONE;
                }
            }
            hold_tid = GLib.Timeout.add(1000, on_key_held);
            key_pressed(this);
        }

        public void release () {
            if (hold_tid != 0)
                GLib.Source.remove (hold_tid);

            if (is_modifier) {
                if (modifier_state == ModifierState.NONE) {
                    xadapter.mod_unlock(mod_mask);
                } else {
                    return;
                }
            }

            if (keyval != 0) {
                xadapter.keyval_press(keyval);
                xadapter.keyval_release(keyval);
            }

            key_released(this);

            if (hold_tid != 0) {
                key_clicked (this);
                hold_tid = 0;
            } else {
                key_hold_end ();
            }
        }

        private bool on_key_held () {
            hold_tid = 0;
            if (extended_keys.size != 0)
                show_subkeys = true;
            if (is_modifier && modifier_state == ModifierState.LATCHED)
                modifier_state = ModifierState.LOCKED;
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

    public enum ModifierState {
        NONE,
        LATCHED,
        LOCKED
    }

    private struct ModifierMapEntry {
        string name;
        Gdk.ModifierType mask;
    }
}
