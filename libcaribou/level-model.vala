using GLib;

namespace Caribou {
    public class LevelModel : ScannableGroup, IKeyboardObject {
        public signal void level_toggled (string new_level);
        public string mode { get; private set; default = ""; }

        private Gee.ArrayList<RowModel> rows;

        public LevelModel (string mode) {
            this.mode = mode;
            rows = new Gee.ArrayList<RowModel> ();
        }

        internal void add_row (RowModel row) {
            row.key_clicked.connect (on_key_clicked);
            row.key_pressed.connect ((k) => { key_pressed (k); });
            row.key_released.connect ((k) => { key_released (k); });
            rows.add(row);
        }

        public RowModel[] get_rows () {
            return (RowModel[]) rows.to_array ();
        }

        private void on_key_clicked (KeyModel key) {
            if (key.toggle != "")
                level_toggled (key.toggle);
            else if (mode == "latched")
                level_toggled ("default");
            key_clicked (key);
        }

        public override IScannableItem[] get_scan_children () {
            if (scan_grouping == ScanGrouping.LINEAR)
                return (IScannableItem[]) get_keys ();
            else
                return (IScannableItem[]) rows.to_array ();
        }

        public IKeyboardObject[] get_children () {
            return (IKeyboardObject[]) get_rows ();
        }

    }
}
