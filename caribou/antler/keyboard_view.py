from caribou.settings.preferences_window import PreferencesDialog
from caribou.settings import CaribouSettings
from antler_settings import AntlerSettings
from gi.repository import Gtk
from gi.repository import Gdk
from gi.repository import Caribou
import gobject
import glib
import os

PRETTY_LABELS = {
    "BackSpace" : u'\u232b',
    "space" : u' ',
    "Return" : u'\u23ce',
    'Caribou_Prefs' : u'\u2328',
    'Caribou_ShiftUp' : u'\u2b06',
    'Caribou_ShiftDown' : u'\u2b07',
    'Caribou_Emoticons' : u'\u263a',
    'Caribou_Symbols' : u'123',
    'Caribou_Symbols_More' : u'{#*',
    'Caribou_Alpha' : u'Abc',
    'Caribou_Repeat' : u'\u267b'
}

class AntlerKey(Gtk.Button):
    def __init__(self, key):
        gobject.GObject.__init__(self)
        self.caribou_key = key.weak_ref()
        self.connect("pressed", self._on_pressed)
        self.connect("released", self._on_released)
        self.set_label(self._get_key_label())

        label = self.get_child()
        label.set_use_markup(True)
        label.props.margin = 6

        ctx = self.get_style_context()
        ctx.add_class("antler-keyboard-button")

        if key.get_extended_keys ():
            self._sublevel = AntlerSubLevel(self)

        self._key_pressed_handler = key.connect(
            'key-pressed',
            lambda x: self.set_state_flags(Gtk.StateFlags.ACTIVE, False))
        self._key_released_handler = key.connect(
            'key-released',
            lambda x: self.unset_state_flags(Gtk.StateFlags.ACTIVE))

    def set_dwell_scan(self, dwell):
        if dwell:
            self.set_state_flags(Gtk.StateFlags.SELECTED, False)
        else:
            self.unset_state_flags(Gtk.StateFlags.SELECTED)

    def set_group_scan_active(self, active):
        if active:
            self.set_state_flags(Gtk.StateFlags.INCONSISTENT, False)
        else:
            self.unset_state_flags(Gtk.StateFlags.INCONSISTENT)

    def _get_key_label(self):
        label = self.caribou_key().props.name
        if PRETTY_LABELS.has_key(self.caribou_key().props.name):
            label = PRETTY_LABELS[self.caribou_key().props.name]
        elif self.caribou_key().props.name.startswith('Caribou_'):
            label = self.caribou_key().name.replace('Caribou_', '')
        else:
            unichar = unichr(Gdk.keyval_to_unicode(self.caribou_key().props.keyval))
            if not unichar.isspace() and unichar != u'\x00':
                label = unichar

        return "<b>%s</b>" % glib.markup_escape_text(label.encode('utf-8'))

    def _on_pressed(self, button):
        self._block_key_signal(self._key_pressed_handler)
        self._press_caribou_key()
        self._unblock_key_signal(self._key_pressed_handler)

    def _on_released(self, button):
        self._block_key_signal(self._key_released_handler)
        self._release_caribou_key()
        self._unblock_key_signal(self._key_released_handler)

    def _press_caribou_key(self):
        if self.caribou_key():
            self.caribou_key().press()

    def _release_caribou_key(self):
        if self.caribou_key():
            self.caribou_key().release()

    def _block_key_signal(self, handler):
        if self.caribou_key():
            self.caribou_key().handler_block(handler)

    def _unblock_key_signal(self, handler):
        if self.caribou_key():
            self.caribou_key().handler_unblock(handler)

    def do_get_preferred_width_for_height(self, w):
        return (w, w)

    def do_get_request_mode(self):
        return Gtk.SizeRequestMode.WIDTH_FOR_HEIGHT

class AntlerSubLevel(Gtk.Window):
    def __init__(self, key):
        gobject.GObject.__init__(self, type=Gtk.WindowType.POPUP)

        self.set_decorated(False)
        self.set_resizable(False)
        self.set_accept_focus(False)
        self.set_position(Gtk.WindowPosition.MOUSE)
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        ctx = self.get_style_context()
        ctx.add_class("antler-keyboard-window")

        key.caribou_key().connect("notify::show-subkeys", self._on_show_subkeys)
        self._key = key

        layout = AntlerLayout()
        layout.add_row([key.caribou_key().get_extended_keys()])
        self.add(layout)

    def _on_show_subkeys(self, key, prop):
        parent = self._key.get_toplevel()
        if key.props.show_subkeys:
            self.set_transient_for(parent)
            parent.set_sensitive(False)
            self.show_all()
        else:
            parent.set_sensitive(True)
            self.hide()

class AntlerLayout(Gtk.Box):
    KEY_SPAN = 4

    def __init__(self, level=None):
        gobject.GObject.__init__(self, orientation=Gtk.Orientation.HORIZONTAL)
        self.set_spacing(12)
        self._columns = []
        self._keys_map = {}
        self._active_scan_group = []
        self._dwelling_scan_group = []

        ctx = self.get_style_context()
        ctx.add_class("antler-keyboard-layout")

        if level:
            self.load_rows(level.get_rows ())
            level.connect("selected-item-changed", self._on_active_group_changed)
            level.connect("step-item-changed", self._on_dwelling_group_changed)
            level.connect("scan-cleared", self._on_scan_cleared)

    def add_column (self):
        col = Gtk.Grid()
        col.set_column_homogeneous(True)
        col.set_row_homogeneous(True)
        col.set_row_spacing(6)
        col.set_column_spacing(6)
        self.pack_start (col, True, True, 0)
        self._columns.append(col)
        return col

    def _on_scan_cleared (self, level):
        self._foreach_key(self._active_scan_group,
                          lambda x: x.set_group_scan_active (False))

        self._active_scan_group = []

        self._foreach_key(self._dwelling_scan_group,
                          lambda x: x.set_dwell_scan (False))

        self._dwelling_scan_group = []

    def _on_active_group_changed(self, level, active_item):
        self._foreach_key(self._active_scan_group,
                          lambda x: x.set_group_scan_active (False))

        if isinstance(active_item, Caribou.KeyModel):
            self._active_scan_group = [active_item]
        else:
            self._active_scan_group = active_item.get_keys()

        self._foreach_key(self._active_scan_group,
                          lambda x: x.set_group_scan_active (True))

    def _on_dwelling_group_changed(self, level, dwell_item):
        self._foreach_key(self._dwelling_scan_group,
                          lambda x: x.set_dwell_scan (False))

        if isinstance(dwell_item, Caribou.KeyModel):
            self._dwelling_scan_group = [dwell_item]
        else:
            self._dwelling_scan_group = dwell_item.get_keys()

        self._foreach_key(self._dwelling_scan_group,
                          lambda x: x.set_dwell_scan (True))

    def _foreach_key(self, keys, cb):
        for key in keys:
            try:
                cb(self._keys_map[key])
            except KeyError:
                continue

    def add_row(self, row, row_num=0):
        x = 0
        for c, col in enumerate(row):
            try:
                column = self._columns[c]
            except IndexError:
                column = self.add_column()

            for i, key in enumerate(col):
                antler_key = AntlerKey(key)
                self._keys_map[key] = antler_key
                ctx = antler_key.get_style_context()
                ctx.add_class("antler-keyboard-row%d" % row_num)
                column.attach(antler_key,
                              x + int(key.props.margin_left * self.KEY_SPAN),
                              row_num * self.KEY_SPAN,
                              int(self.KEY_SPAN * key.props.width),
                              self.KEY_SPAN)
                x += int((key.props.width + key.props.margin_left ) * self.KEY_SPAN)
 
    def load_rows(self, rows):
        for row_num, row in enumerate(rows):
            self.add_row([c.get_children() for c in row.get_columns()], row_num)

class AntlerKeyboardView(Gtk.Notebook):
    def __init__(self):
        gobject.GObject.__init__(self)
        settings = AntlerSettings()
        self.set_show_tabs(False)

        use_system = settings.use_system
        use_system.connect("value-changed", self._on_use_system_theme_changed)

        self._app_css_provider = Gtk.CssProvider()
        self._load_style(
            self._app_css_provider, "style.css",
            [glib.get_user_data_dir()] + list(glib.get_system_data_dirs()))

        if not use_system.value:
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(), self._app_css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

        self._user_css_provider = Gtk.CssProvider()
        self._load_style(self._user_css_provider, "user-style.css",
                         [glib.get_user_data_dir()])
        Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(), self._user_css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1)

        self.scanner = Caribou.Scanner()
        self.set_keyboard_model(settings.keyboard_type.value)
        settings.keyboard_type.connect('value-changed', self._on_kb_type_changed)

    def set_keyboard_model(self, keyboard_type):
        self.keyboard_model = Caribou.KeyboardModel(keyboard_type=keyboard_type)

        self.scanner.set_keyboard(self.keyboard_model)
        self.keyboard_model.connect("notify::active-group", self._on_group_changed)
        self.keyboard_model.connect("key-activated", self._on_key_activated)

        self.layers = {}

        for gname in self.keyboard_model.get_groups():
            group = self.keyboard_model.get_group(gname)
            self.layers[gname] = {}
            group.connect("notify::active-level", self._on_level_changed)
            for lname in group.get_levels():
                level = group.get_level(lname)
                layout = AntlerLayout(level)
                layout.show()
                self.layers[gname][lname] = self.append_page(layout, None)

        self._set_to_active_layer()

    def _on_kb_type_changed(self, setting, value):
        is_visible = self.get_visible()
        for l in [self.get_nth_page(i) for i in xrange(self.get_n_pages ())]:
            self.remove(l)
        self.set_keyboard_model(value)
        if is_visible:
            self.show_all ()

    def _on_key_activated(self, model, key):
        if key.props.name == "Caribou_Prefs":
            p = PreferencesDialog(AntlerSettings())
            p.populate_settings(CaribouSettings())
            p.show_all()
            p.run()
            p.destroy()

    def _on_use_system_theme_changed(self, setting, value):
        if value:
            Gtk.StyleContext.remove_provider_for_screen(
                Gdk.Screen.get_default(), self._app_css_provider)
        else:
            Gtk.StyleContext.add_provider_for_screen(
                Gdk.Screen.get_default(), self._app_css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def _load_style(self, provider, filename, search_path):
        spath = search_path[:]
        if os.environ.has_key("ANTLER_THEME_PATH"):
            spath.insert(0, os.environ["ANTLER_THEME_PATH"])

        for directory in spath:
            fn = os.path.join(directory, "antler", filename)
            if os.path.exists(fn):
                provider.load_from_path(fn)
                break

    def _on_level_changed(self, group, prop):
        self._set_to_active_layer()

    def _on_group_changed(self, kb, prop):
        self._set_to_active_layer()

    def _set_to_active_layer(self):
        active_group_name = self.keyboard_model.props.active_group
        active_group = self.keyboard_model.get_group(active_group_name)
        active_level_name = active_group.props.active_level

        self.set_current_page(self.layers[active_group_name][active_level_name])

if __name__ == "__main__":
    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    w = Gtk.Window()
    w.set_accept_focus(False)

    kb = AntlerKeyboardView()
    w.add(kb)

    w.show_all()

    Gtk.main()
