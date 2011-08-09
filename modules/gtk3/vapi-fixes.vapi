using Gdk;

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
