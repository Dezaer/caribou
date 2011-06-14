using Bus;

namespace Caribou {
    public class KeyboardModel : Object, IKeyboardObject {
        public string active_group { get; private set; default = ""; }
        public string keyboard_type { get; construct; }

        private XAdapter xadapter;
        private Gee.HashMap<string, GroupModel> groups;
        private KeyModel last_activated_key;

        construct {
            uint grpid;
            string group, variant;
            string[] grps, variants;
            int i;

            assert (keyboard_type != null);

            xadapter = XAdapter.get_default ();
            xadapter.group_changed.connect (on_group_changed);

            xadapter.get_groups (out grps, out variants);

            groups = new Gee.HashMap<string, GroupModel> (str_hash, str_equal);

            for (i=0;i<grps.length;i++)
                populate_group (grps[i], variants[i]);

            grpid = xadapter.get_current_group (out group, out variant);
            on_group_changed (grpid, group, variant);
        }

        private void populate_group (string group, string variant) {
            GroupModel grp = XmlDeserializer.load_group (keyboard_type,
                                                          group, variant);
            if (grp != null) {
                groups.set (GroupModel.create_group_name (group, variant), grp);
                grp.key_activated.connect (on_key_activated);
            }
        }

        private void on_key_activated (KeyModel key) {
            if (key.name == "Caribou_Repeat")
                last_activated_key.activate ();
            else
                last_activated_key = key;

            key_activated (key);
        }

        public string[] get_groups () {
            return (string[]) groups.keys.to_array ();
        }

        public GroupModel get_group (string group_name) {
            return groups.get (group_name);
        }

        private void on_group_changed (uint grpid, string group, string variant) {
            string group_name = GroupModel.create_group_name (group, variant);
            if (groups.get (group_name) != null) {
                active_group = group_name;
            } else {
                active_group = get_groups ()[0];
            }
        }

        public IKeyboardObject[] get_children () {
            return (IKeyboardObject[]) groups.values.to_array ();
        }
    }
}