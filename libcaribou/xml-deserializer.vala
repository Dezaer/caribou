using Xml;

namespace Caribou {

    private class XmlDeserializer : Object {

        public static string? get_layout_file_inner (string data_dir,
                                                    string group,
                                                    string variant) {
            string[] files = {@"$(group)_$(variant).xml", @"$(group).xml"};

            foreach (string fn in files) {
                string layout_fn = GLib.Path.build_filename (data_dir, fn);
                GLib.File fp = GLib.File.new_for_path (layout_fn);
                if (fp.query_exists ())
                    return layout_fn;
            }

            return null;
        }

        public static string get_layout_file (string keyboard_type, string group,
                                              string variant) throws IOError {

            List<string> dirs = new List<string> ();
            string custom_dir = Environment.get_variable("CARIBOU_LAYOUTS_DIR");

            if (custom_dir != null)
                dirs.append (Path.build_filename (custom_dir, "layouts",
                                                  keyboard_type));

            dirs.append (Path.build_filename (Environment.get_user_data_dir (),
                                              "caribou", "layouts", keyboard_type));

            foreach (string dir in Environment.get_system_data_dirs ()) {
                dirs.append (Path.build_filename (
                                 dir, "caribou", "layouts", keyboard_type));
            }

            foreach (string data_dir in dirs) {
                string fn = get_layout_file_inner (data_dir, group, variant);
                if (fn != null)
                    return fn;
            }

            throw new IOError.NOT_FOUND (
                "Could not find layout file for %s %s", group, variant);                       }

        public static GroupModel? load_group (string keyboard_type,
                                              string group, string variant) {
            Doc* doc;

            try {
                string fn = get_layout_file (keyboard_type, group, variant);
                doc = Parser.parse_file (fn);
                if (doc == null)
                    throw new IOError.FAILED (
                        "Cannot load XML text reader for %s", fn);
            } catch (GLib.Error e) {
                stdout.printf ("Failed to load XML: %s\n", e.message);
                return null;
            }

            GroupModel grp = new GroupModel (group, variant);
            Xml.Node* node = doc->children;

            create_levels_from_xml (grp, node);

            delete doc;
            Parser.cleanup ();

            return grp;
        }

        public static void create_levels_from_xml (GroupModel group,
                                                   Xml.Node* node) {
            assert (node->name == "layout");
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                if (iter->type != ElementType.ELEMENT_NODE)
                    continue;

                string levelname = iter->get_prop ("name");
                string mode = iter->get_prop ("mode");

                LevelModel level = new LevelModel(mode);
                load_rows (level, iter);

                group.add_level(levelname, level);
            }
        }

        public static void load_rows (LevelModel level, Xml.Node* node) {
            assert (node->name == "level");
            int rownum = 0;
            for (Xml.Node* i = node->children; i != null; i = i->next) {
                if (i->type != ElementType.ELEMENT_NODE)
                    continue;

                int colnum = 0;
                for (Xml.Node* i2 = i->children; i2 != null; i2 = i2->next) {
                    if (i2->name == "key")
                        level.add_key (rownum, colnum, load_key(i2));
                    else if (i2->name == "column")
                        load_column (level, rownum, colnum++, i2);
                }
                rownum++;
            }
        }

        public static void load_column (LevelModel level, int row, int col,
                                        Xml.Node* node) {
            assert (node->name == "column");
            for (Xml.Node* i = node->children; i != null; i = i->next) {
                if (i->type != ElementType.ELEMENT_NODE)
                    continue;
                
                level.add_key (row, col, load_key (i));
            }
        }

        public static KeyModel load_key (Xml.Node* node) {
            assert (node->name == "key");

            string name = node->get_prop ("name");
            assert (name != null);

            KeyModel key = new KeyModel (name);

            for (Attr* prop = node->properties; prop != null; prop = prop->next) {
                if (prop->name == "toggle")
                    key.toggle = prop->children->content;
                else if (prop->name == "margin-left")
                    key.margin_left = double.parse (prop->children->content);
                else if (prop->name == "width")
                    key.width = double.parse (prop->children->content);
            }

            for (Xml.Node* i = node->children; i != null; i = i->next) {
                if (i->type != ElementType.ELEMENT_NODE)
                    continue;

                key.add_subkey (load_key (i));
            }

            return key;
        }
    }
}