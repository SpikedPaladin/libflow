namespace Flow {

    protected class Rubberband : NodeViewChild {
        public float start_x { get; construct set; }
        public float start_y { get; construct set; }

        static construct {
            set_css_name("rubberband");
        }

        public Rubberband(Gtk.Widget parent, double x, double y) {
            this.x = start_x = (float) x;
            this.y = start_y = (float) y;

            set_parent(parent);
        }
    }
}
