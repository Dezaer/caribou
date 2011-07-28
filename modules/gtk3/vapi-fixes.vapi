using Atk;

[CCode (cprefix = "Atk", lower_case_cprefix = "atk_", cheader_filename = "atk/atk.h")]

namespace Atk {
    [CCode (cname = "atk_component_get_extents")]
    public void component_get_extents (Atk.Component component,
                                       out int x, out int y, out int w, out int h,
                                       Atk.CoordType coord_type);
}