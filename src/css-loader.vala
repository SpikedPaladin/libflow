namespace Flow {
    
    [SingleInstance]
    protected class CssLoader : Object {
        public Gtk.CssProvider provider;
        
        public void ensure() {
            if (provider != null) return;
            
            provider = new Gtk.CssProvider();
            provider.load_from_resource("/me/paladin/libflow/css/flow.css");
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
    }
}
