namespace Caribou {
    public class RowModel : ScannableGroup, IScannableItem, IKeyboardObject {
        public bool scan_stepping { get; set; }
        public bool scan_selected { get; set; }

        Gee.ArrayList<ColumnModel> columns;

        public RowModel () {
            columns = new Gee.ArrayList<ColumnModel> ();
        }

        internal void add_column (ColumnModel column) {
            column.key_clicked.connect ((k) => { key_clicked (k); });
            column.key_pressed.connect ((k) => { key_pressed (k); });
            column.key_released.connect ((k) => { key_released (k); });

            columns.add(column);
        }

        public ColumnModel[] get_columns () {
            return (ColumnModel[]) columns.to_array ();
        }

        public override IScannableItem[] get_scan_children () {
            if (scan_grouping == ScanGrouping.ROWS)
                return (IScannableItem[]) get_keys ();
            else
                return (IScannableItem[]) columns.to_array ();
        }

        public IKeyboardObject[] get_children () {
            return (IKeyboardObject[]) get_columns ();
        }
    }
}
