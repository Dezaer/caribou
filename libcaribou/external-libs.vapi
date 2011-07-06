using X;

[CCode (cprefix = "", lower_case_cprefix = "",
        cheader_filename = "X11/extensions/XTest.h")]
namespace XTest {
    [CCode (cname = "XTestFakeKeyEvent")]
    public int fake_key_event (Display dpy, uchar keycode, bool key_press,
                               ulong delay);
}

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "X11/Xlib.h")]
namespace X {
    [CCode (cname = "XKeycodeToKeysym")]
    public int keycode_to_keysym (Display dpy, uchar keycode, int index);

}

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "X11/XKBlib.h")]
namespace Xkb {

    [CCode (cname = "XkbGetKeyboard")]
    public Desc get_keyboard (X.Display dpy, uint which, uint device_spec);

    [CCode (cname = "XkbSetMap")]
    public void set_map (X.Display dpy, uint which, Desc xkb);

    [CCode (cname = "XkbFreeKeyboard")]
    public void free_keyboard (Desc xkb, uint which, bool free_all);

    [CCode (cname = "XkbGetState")]
    public void get_state (X.Display dpy, uint device_spec, out State state);

    [CCode (cname = "XkbSelectEvents")]
    public void select_events (X.Display dpy, uint device_spec, ulong bits_to_change,
        ulong values_for_bits);

    [CCode (cname = "XkbLatchModifiers")]
    public void latch_modifiers (X.Display dpy, uint device_spec, uint affect,
                                 uint values);

    [CCode (cname = "XkbLockModifiers")]
    public void lock_modifiers (X.Display dpy, uint device_spec, uint affect,
                                uint values);


    [Compact]
    [CCode (cname = "XkbAnyEvent", free_function = "")]
    public struct AnyEvent {
        int xkb_type;
    }

    [Compact]
    [CCode (cname = "XkbStateNotifyEvent", free_function = "")]
    public struct StateNotifyEvent {
        uint changed;
        int locked_group;
        uint mods;
    }

    [Compact]
    [CCode (cname = "XkbEvent", free_function = "")]
    public struct Event {
        int type;
        AnyEvent any;
        StateNotifyEvent state;
    }

    [Compact]
    [CCode (cname = "XkbStateRec", free_function = "")]
    public struct State {
        uchar   group;
        uchar   locked_group;
        ushort  base_group;
        ushort  latched_group;
        uchar   mods;
        uchar   base_mods;
        uchar   latched_mods;
        uchar   locked_mods;
        uchar   compat_state;
        uchar   grab_mods;
        uchar   compat_grab_mods;
        uchar   lookup_mods;
        uchar   compat_lookup_mods;
        ushort  ptr_buttons;
    }

    [Compact]
    [CCode (cname = "XkbDescRec", free_function = "")]
    public class Desc {
        public X.Display dpy;
        public ushort flags;
        public ushort device_spec;
        public char min_key_code;
        public char max_key_code;
        public Controls          ctrls;
        public ServerMap         server;
        public ClientMap         map;
        public Indicator         indicators;
        public Names             names;
        public CompatMap         compat;
        public Geometry          geom;
    }

    [Compact]
    [CCode (cname = "XkbControlsRec", free_function = "")]
    public class Controls {
    }

    [Compact]
    [CCode (cname = "XkbServerMapRec", free_function = "")]
    public class ServerMap {
    }

    [Compact]
    [CCode (cname = "XkbKeyTypeRec", free_function = "")]
    public struct KeyType {
    }

    [CCode (cname = "XkbSymMapRec", free_function = "")]
    public struct SymMap {
        uchar    kt_index[4];
        uchar    group_info;
        uchar    width;
        ushort   offset;
    }

    [Compact]
    [CCode (cname = "XkbClientMapRec", free_function = "")]
    public class ClientMap {
        public uchar            size_types;
        public uchar            num_types;
        public KeyType[]        types;

        public ushort           size_syms;
        public ushort           num_syms;
        public uint[]           syms;
        public SymMap[]         key_sym_map;

        public uchar[]          modmap;
    }

    [Compact]
    [CCode (cname = "XkbIndicatorRec", free_function = "")]
    public class Indicator {
    }

    [Compact]
    [CCode (cname = "XkbNamesRec", free_function = "")]
    public class Names {
    }

    [Compact]
    [CCode (cname = "XkbCompatMapRec", free_function = "")]
    public class CompatMap {
    }

    [Compact]
    [CCode (cname = "XkbGeometryRec", free_function = "")]
    public class Geometry {
    }

    [CCode (cname = "XkbUseCoreKbd")]
    public int UseCoreKbd;
    [CCode (cname = "XkbUseCorePtr")]
    public int UseCorePtr;
    [CCode (cname = "XkbDfltXIClass")]
    public int DfltXIClass;
    [CCode (cname = "XkbDfltXIId")]
    public int DfltXIId;
    [CCode (cname = "XkbAllXIClasses")]
    public int AllXIClasses;
    [CCode (cname = "XkbAllXIIds")]
    public int AllXIIds;
    [CCode (cname = "XkbXINone")]
    public int XINone;

    [CCode (cname = "XkbGBN_TypesMask")]
    public int GBN_TypesMask;
    [CCode (cname = "XkbGBN_CompatMapMask")]
    public int GBN_CompatMapMask;
    [CCode (cname = "XkbGBN_ClientSymbolsMask")]
    public int GBN_ClientSymbolsMask;
    [CCode (cname = "XkbGBN_ServerSymbolsMask")]
    public int GBN_ServerSymbolsMask;
    [CCode (cname = "XkbGBN_SymbolsMask")]
    public int GBN_SymbolsMask;
    [CCode (cname = "XkbGBN_IndicatorMapMask")]
    public int GBN_IndicatorMapMask;
    [CCode (cname = "XkbGBN_KeyNamesMask")]
    public int GBN_KeyNamesMask;
    [CCode (cname = "XkbGBN_GeometryMask")]
    public int GBN_GeometryMask;
    [CCode (cname = "XkbGBN_OtherNamesMask")]
    public int GBN_OtherNamesMask;
    [CCode (cname = "XkbGBN_AllComponentsMask")]
    public int GBN_AllComponentsMask;

    [CCode (cname = "XkbOneLevelIndex")]
    public int OneLevelIndex;

    [CCode (cname = "XkbNewKeyboardNotifyMask")]
    public int NewKeyboardNotifyMask;
    [CCode (cname = "XkbMapNotifyMask")]
    public int MapNotifyMask;
    [CCode (cname = "XkbStateNotifyMask")]
    public int StateNotifyMask;
    [CCode (cname = "XkbControlsNotifyMask")]
    public int ControlsNotifyMask;
    [CCode (cname = "XkbIndicatorStateNotifyMask")]
    public int IndicatorStateNotifyMask;
    [CCode (cname = "XkbIndicatorMapNotifyMask")]
    public int IndicatorMapNotifyMask;
    [CCode (cname = "XkbNamesNotifyMask")]
    public int NamesNotifyMask;
    [CCode (cname = "XkbCompatMapNotifyMask")]
    public int CompatMapNotifyMask;
    [CCode (cname = "XkbBellNotifyMask")]
    public int BellNotifyMask;
    [CCode (cname = "XkbActionMessageMask")]
    public int ActionMessageMask;
    [CCode (cname = "XkbAccessXNotifyMask")]
    public int AccessXNotifyMask;
    [CCode (cname = "XkbExtensionDeviceNotifyMask")]
    public int ExtensionDeviceNotifyMask;
    [CCode (cname = "XkbAllEventsMask")]
    public int AllEventsMask;

   [CCode (cname = "XkbStateNotify")]
    public int StateNotify;

   [CCode (cname = "XkbGroupStateMask")]
    public int GroupStateMask;

   [CCode (cname = "XkbModifierStateMask")]
    public int ModifierStateMask;

  [CCode (cname = "XkbAllMapComponentsMask")]
    public int AllMapComponentsMask;
}
