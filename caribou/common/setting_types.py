import gobject
from gi.repository import GConf

GCONF_DIR="/apps/caribou/osk/"

ENTRY_DEFAULT=0
ENTRY_COMBO=1
ENTRY_COLOR=2
ENTRY_FONT=3
ENTRY_SPIN=4
ENTRY_SLIDER=5
ENTRY_CHECKBOX=6
ENTRY_RADIO=7

class Setting(gobject.GObject):
    __gsignals__ = {'value-changed' :
                    (gobject.SIGNAL_RUN_FIRST,
                     gobject.TYPE_NONE, 
                     (gobject.TYPE_PYOBJECT,)),
                    'sensitivity-changed' : 
                    (gobject.SIGNAL_RUN_FIRST,
                     gobject.TYPE_NONE, 
                     (gobject.TYPE_BOOLEAN,))}
    def __init__(self, name, label, children=[]):
        gobject.GObject.__init__(self)
        self.name = name
        self.label = label
        self.children = children

    @property
    def sensitive(self):
        return getattr(self, '_sensitive', True)

    @sensitive.setter
    def sensitive(self, sensitive):
        changed = getattr(self, '_sensitive', sensitive) != sensitive
        self._sensitive = sensitive
        self.emit('sensitivity-changed', sensitive)

    def __len__(self):
        return len(self.children)

    def __getitem__(self, i):
        return self.children[i]

    def __setitem__(self, i, v):
        self.children[i] = v

    def __delitem__(self, i):
        del self.children[i]

    def __iter__(self):
        return self.children.__iter__()

class SettingsGroup(Setting):
    pass

class ValueSetting(Setting):
    gconf_type = GConf.ValueType.INVALID
    entry_type=ENTRY_DEFAULT
    def __init__(self, name, label, default, short_desc="", long_desc="",
                 allowed=[], entry_type=ENTRY_DEFAULT, sensitive=None,
                 user_visible=True, children=[],
                 insensitive_when_false=[], insensitive_when_true=[]):
        Setting.__init__(self, name, label, children)
        self.short_desc = short_desc
        self.long_desc = long_desc
        self.allowed = allowed
        self.entry_type = entry_type or self.__class__.entry_type
        if sensitive is not None:
            self.sensitive = sensitive
        self.user_visible = user_visible
        self.default = default
        self.insensitive_when_false = insensitive_when_false
        self.insensitive_when_true = insensitive_when_true

    @property
    def value(self):
        return getattr(self, '_value', self.default)

    @value.setter
    def value(self, val):
        _val = self.convert_value(self._from_gconf_value(val))
        if self.allowed and _val not in [a for a, b in self.allowed]:
            raise ValueError, "'%s' not a valid value" % _val
        self._value = _val
        self.emit('value-changed', _val)

    @property
    def gconf_key(self):
        return GCONF_DIR + self.name

    @property
    def is_true(self):
        return bool(self.value)

    @property
    def gconf_default(self):
        return self.default

    def set_gconf_value(self, val):
        if val.type == GConf.ValueType.BOOL:
            return val.set_bool(self.value)
        if val.type == GConf.ValueType.FLOAT:
            return val.set_float(self.value)
        if val.type == GConf.ValueType.INT:
            return val.set_int(self.value)
        if val.type == GConf.ValueType.STRING:
            return val.set_string(self.value)

    def _from_gconf_value(self, val):
        if not isinstance(val, GConf.Value):
            return val
        if val.type == GConf.ValueType.BOOL:
            return val.get_bool()
        if val.type == GConf.ValueType.FLOAT:
            return val.get_float()
        if val.type == GConf.ValueType.INT:
            return val.get_int()
        if val.type == GConf.ValueType.STRING:
            return val.get_string()

        return val.to_string()

class BooleanSetting(ValueSetting):
    gconf_type = GConf.ValueType.BOOL
    entry_type = ENTRY_CHECKBOX
    def convert_value(self, val):
        # Almost anything could be a boolean.
        return bool(val)

    @property
    def gconf_default(self):
        str(self.default).lower()

class IntegerSetting(ValueSetting):
    gconf_type = GConf.ValueType.INT
    entry_type = ENTRY_SPIN
    def __init__(self, *args, **kwargs):
        self.min = kwargs.pop('min', gobject.G_MININT)
        self.max = kwargs.pop('max', gobject.G_MAXINT)
        ValueSetting.__init__(self, *args, **kwargs)

    def convert_value(self, val):
        return int(val)

class FloatSetting(ValueSetting):
    gconf_type = GConf.ValueType.FLOAT
    entry_type = ENTRY_SPIN
    def __init__(self, *args, **kwargs):
        self.min = kwargs.pop('min', gobject.G_MINFLOAT)
        self.max = kwargs.pop('max', gobject.G_MAXFLOAT)
        ValueSetting.__init__(self, *args, **kwargs)

    def convert_value(self, val):
        return float(val)

class StringSetting(ValueSetting):
    gconf_type = GConf.ValueType.STRING
    def convert_value(self, val):
        return str(val)

class ColorSetting(StringSetting):
    entry_type = ENTRY_COLOR

class FontSetting(StringSetting):
    entry_type = ENTRY_FONT
