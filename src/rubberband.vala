namespace Flow {
    
    
    protected class Rubberband : Gtk.Widget {
        public int start_x { get; construct set; }
        public int start_y { get; construct set; }
        
        static construct {
            set_css_name("rubberband");
        }
        
        public Rubberband(int x, int y) {
            start_x = x;
            start_y = y;
        }
        
        public new void set_parent(NodeView parent) {
            base.set_parent(parent);
            
            var layout = (NodeViewLayoutChild) parent.layout_manager.get_layout_child(this);
            layout.x = start_x;
            layout.y = start_y;
        }
        
        public void process_motion(NodeViewLayoutChild layout, int x, int y) {
            Gdk.Rectangle selection = {
                start_x, start_y,
                (x - start_x), (y - start_y)
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
