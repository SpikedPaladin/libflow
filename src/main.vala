namespace Flow {
    private static bool done = false;

    public void init() {
        if (!done) {
            init_public_types();
            
            var display = Gdk.Display.get_default();
            if (display != null) {
                var provider = new Gtk.CssProvider();
                provider.load_from_resource("/me/paladin/libflow/css/flow.css");
                Gtk.StyleContext.add_provider_for_display(display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            }

            done = true;
        }
    }

    private void init_public_types() {
        typeof(NodeView).ensure();
        typeof(Node).ensure();
    }
}
