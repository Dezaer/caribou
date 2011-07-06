using GLib;

namespace Caribou {
    public class GroupModel : Object, IKeyboardObject {
        public string active_level { get; private set; }

        public string group;
        public string variant;
        private string default_level;
        private Gee.HashMap<string, LevelModel> levels;

        public GroupModel (string group, string variant) {
            this.group = group;
            this.variant = variant;
            levels = new Gee.HashMap<string, LevelModel> (str_hash, str_equal);
            active_level = default_level;
        }

        public static string create_group_name (string group, string variant) {
            if (variant != "")
                return @"$(group)_$(variant)";
            else
                return group;
        }

        internal void add_level (string lname, LevelModel level) {
            levels.set (lname, level);
            level.level_toggled.connect (on_level_toggled);
            level.key_clicked.connect ((k) => { key_clicked (k); });
            level.key_pressed.connect ((k) => { key_pressed (k); });
            level.key_released.connect ((k) => { key_released (k); });
            if (level.mode == "default") {
                default_level = lname;
                active_level = lname;
            }
        }

        public string[] get_levels () {
            return (string[]) levels.keys.to_array ();
        }

        public LevelModel get_level (string level_name) {
            return levels.get (level_name);
        }

        private void on_level_toggled (string new_level) {
            if (new_level == "default")
                active_level = default_level;
            else
                active_level = new_level;
        }

        public IKeyboardObject[] get_children () {
            return (IKeyboardObject[]) levels.values.to_array ();
        }

    }
}
