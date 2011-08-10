using Gdk;
using Atk;

[CCode (cprefix = "Gdk", lower_case_cprefix = "gdk_", cheader_filename = "gdk/gdk.h")]

namespace Gdk {
	// Gdk.Window.add_filter() doesn't let you pass null for window
    [CCode (cname = "gdk_window_add_filter")]
    public void window_add_filter (Gdk.Window? window,
								   Gdk.FilterFunc function);

	// Gdk.Window.remove_filter() doesn't let you pass null for window
     [CCode (cname = "gdk_window_remove_filter")]
    public void window_remove_filter (Gdk.Window? window,
                                                                   Gdk.FilterFunc function);

	// Official binding is missing the "out"
    [CCode (cname = "gdk_window_get_user_data")]
    public void window_get_user_data (Gdk.Window window,
									  out void* data);
}

[CCode (cprefix = "Atk", lower_case_cprefix = "atk_", gir_namespace = "Atk", gir_version = "1.0")]

namespace Atk {
    [CCode (cname = "atk_text_get_character_extents")]
    public void get_character_extents (Atk.Text text, int offset, out int x, out int y,
                                                      out int w, out int h, Atk.CoordType coord);
}
