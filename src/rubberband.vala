namespace Flow {
    
    protected class Rubberband : Gtk.Widget {
        private NodeViewLayoutChild layout;
        
        public int start_x { get; construct set; }
        public int start_y { get; construct set; }
        
        static construct {
            set_css_name("rubberband");
        }
        
        public Rubberband(NodeView parent, double x, double y) {
            set_parent(parent);
            
            layout = parent.get_layout(this);
            layout.x = start_x = (int) x;
            layout.y = start_y = (int) y;
        }
        
        public void process_motion(double x, double y) {
            Gdk.Rectangle selection = {
                start_x, start_y,
                (int) x, (int) y
            };
            
            if (selection.width < 0) {
                selection.width *= -1;
                selection.x -= selection.width;
            }
            
            if (selection.height < 0) {
                selection.height *= -1;
                selection.y -= selection.height;
            }
            
            layout.x = selection.x;
            layout.y = selection.y;
            set_size_request(selection.width, selection.height);
        }
    }
}
