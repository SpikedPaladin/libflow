namespace Flow {
    
    [GtkTemplate (ui = "/me/paladin/libflow/ui/node-view.ui")]
    public class NodeView : Gtk.Widget {
        private Gtk.Popover menu;
        private Gtk.Widget _menu_content;
        private int _grid_size = 1;
        /**
         * If this property is set to true, the nodeview will not perform
         * any check wheter newly created connections will result in cycles
         * in the graph. It's completely up to the application programmer
         * to make sure that the logic inside the nodes he uses avoids
         * endlessly backpropagated loops
         */
        public bool allow_recursion { get; set; default = false; }
        
        public Gtk.Widget menu_content { get { return _menu_content; } set { _menu_content = value; menu.set_child(value); } }
        public int grid_size { get { return _grid_size; } set { if (value < 1) _grid_size = 1; else _grid_size = value; } }
        /**
         * The current extents of the temporary connector
         * if null, there is no temporary connector drawn at the moment
         */
        private Gdk.Rectangle? temp_connector = null;
        /**
         * The socket that the temporary connector will be attched to
         */
        private Socket? temp_connected_socket = null;
        /**
         * The socket that was clicked to invoke the temporary connector
         */
        private Socket? clicked_socket = null;
        /**
         * Widget that used to draw selection
         */
        public Rubberband? rubberband;
        /**
         * The node that is being moved right now via mouse drag.
         * The node that receives the button press event registers
         * itself with this property
         */
        internal NodeRenderer? move_node { get; set; default = null; }
        internal NodeRenderer? resize_node { get; set; default = null; }
        
        public ConnectionRenderer renderer = new ConnectionRenderer();
        
        static construct {
            set_css_name("node-view");
        }
        
        construct {
            new CssLoader().ensure();
            
            set_layout_manager(new NodeViewLayoutManager());
        }
        
        /**
         * Instantiate a new NodeView
         */
        public NodeView() {
            menu = new Gtk.Popover();
            menu.set_parent(this);
            menu.set_has_arrow(false);
        }
        
        /**
         * {@inheritDoc}
         */
        public override void dispose() {
            var child = get_first_child();
            
            while (child != null) {
                var delchild = child;
                child = child.get_next_sibling();
                delchild.unparent();
            }
            
            base.dispose();
        }
        
        public NodeViewLayoutChild get_layout(Gtk.Widget widget) {
            return (NodeViewLayoutChild) layout_manager.get_layout_child(widget);
        }
        
        public List<unowned NodeRenderer> get_nodes() {
            var result = new List<unowned NodeRenderer>();
            
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                if (!(child is NodeRenderer))
                    continue;
                
                result.append(child as NodeRenderer);
            }
            
            return result;
        }
        
        public List<unowned NodeRenderer> get_selected_nodes() {
            var result = new List<unowned NodeRenderer>();
            
            foreach (var node in get_nodes()) {
                if (node.selected)
                    result.append(node);
            }
            
            return result;
        }
        
        public void move(NodeRenderer node, int x, int y) {
            var layout = get_layout(node);
            
            layout.x = x;
            layout.y = y;
        }
        
        private int round_to_multiply(int number, int multiply) {
            return (int) (multiply * Math.round(number / multiply));
        }
        
        [GtkCallback]
        private void process_motion(double x, double y) {
            if (move_node != null) {
                var layout = get_layout(move_node);
                int old_x = layout.x;
                int old_y = layout.y;
                
                int new_x = ((int) x - (int) move_node.click_offset_x);
                int new_y = ((int) y - (int) move_node.click_offset_y);
                
                if (old_x == new_x && old_y == new_y)
                    return;
                
                if (new_x < 0) new_x = 0;
                if (new_y < 0) new_y = 0;
                
                layout.x = _grid_size == 1 ? new_x : round_to_multiply(new_x, _grid_size);
                layout.y = _grid_size == 1 ? new_y : round_to_multiply(new_y, _grid_size);
                
                if (move_node.selected) {
                    foreach (NodeRenderer node in get_selected_nodes()) {
                        if (node == move_node) continue;
                        
                        var selected_layout = get_layout(node);
                        selected_layout.x -= old_x - layout.x;
                        selected_layout.y -= old_y - layout.y;
                    }
                }
                
                queue_allocate();
            }
            
            if (resize_node != null) {
                int d_x, d_y;
                Graphene.Rect node_bounds;
                
                resize_node.compute_bounds(this, out node_bounds);
                
                d_x = (int) (x - resize_node.click_offset_x - node_bounds.origin.x);
                d_y = (int) (y - resize_node.click_offset_y - node_bounds.origin.y);
                
                int new_width = (int) resize_node.resize_start_width + d_x;
                int new_height = (int) resize_node.resize_start_height + d_y;
                
                if (new_width < 0) new_width = 0;
                if (new_height < 0) new_height = 0;
                
                resize_node.set_size_request(new_width, new_height);
            }
            
            if (temp_connector != null) {
                temp_connector.width = (int) (x - temp_connector.x);
                temp_connector.height = (int) (y - temp_connector.y);
                
                queue_draw();
            }
            
            if (rubberband != null) {
                rubberband.process_motion(get_layout(rubberband), (int) x, (int) y);
                
                foreach (var node in get_nodes()) {
                    Graphene.Rect node_bounds, rubberband_bounds, result;
                    
                    node.compute_bounds(this, out node_bounds);
                    rubberband.compute_bounds(this, out rubberband_bounds);
                    node_bounds.intersection(rubberband_bounds, out result);
                    node.selected = result.size.width > 0 && result.size.height > 0;
                }
            }
        }
        
        [GtkCallback]
        private void start_selection(int n_clicks, double x, double y) {
            if (pick(x, y, Gtk.PickFlags.DEFAULT) == this) {
                rubberband?.unparent();
                rubberband = new Rubberband((int) x, (int) y);
                rubberband.set_parent(this);
            }
        }
        
        [GtkCallback]
        private void open_menu(int n_clicks, double x, double y) {
            menu.set_pointing_to({ (int) x, (int) y, 1, 1 });
            menu.popup();
        }
        
        internal void start_temp_connector(Socket socket) {
            clicked_socket = socket;
            if (socket is Sink && socket.is_linked()) {
                var sink = (Sink) socket;
                
                temp_connected_socket = sink.sources.last().nth_data(0);
            } else {
                temp_connected_socket = socket;
            }
            
            Graphene.Point point;
            temp_connected_socket.compute_point(this, { 8, 8 }, out point);
            
            temp_connector = { (int) point.x, (int) point.y, 0, 0 };
        }
        
        [GtkCallback]
        internal void end_temp_connector(int n_clicks, double x, double y) {
            if (temp_connector != null) {
                var widget = pick(x, y, Gtk.PickFlags.DEFAULT);
                
                if (widget is Socket) {
                    var socket = (Socket) widget;
                    
                    // Relink Sinks
                    if (
                        socket is Sink && clicked_socket != null &&
                        clicked_socket is Sink &&
                        temp_connected_socket is Source
                    ) {
                        if (is_suitable_target(socket, temp_connected_socket)) {
                            clicked_socket.unlink(temp_connected_socket);
                            socket.link(temp_connected_socket);
                        } else
                            temp_connector = null;
                    
                    // Link Sockets
                    } else if (
                        socket is Source && temp_connected_socket is Sink ||
                        socket is Sink && temp_connected_socket is Source
                    ) {
                        if (is_suitable_target(socket, temp_connected_socket))
                            socket.link(temp_connected_socket);
                        else 
                            temp_connector = null;
                    }
                    socket.queue_draw();
                } else {
                    if (
                        temp_connected_socket is Source &&
                        clicked_socket != null &&
                        clicked_socket is Sink
                    ) {
                        clicked_socket.unlink(temp_connected_socket);
                    }
                }
                
                clicked_socket = null;
                temp_connected_socket = null;
                temp_connector = null;
                
                queue_draw();
            }
            
            move_node = null;
            resize_node = null;
            rubberband?.unparent();
            rubberband = null;
            
            queue_resize();
            queue_allocate();
        }
        
        /**
         * Add a node to this nodeview
         */
        public void add(NodeRenderer node) {
            node.set_parent(this);
        }
        
        /**
         * Remove a node from this nodeview
         */
        public void remove(NodeRenderer node) {
            node.unlink_all();
            node.unparent();
        }
        
        /**
         * Determines wheter one socket can be dropped on another
         */
        private bool is_suitable_target(Socket from, Socket to) {
            // Check whether the sockets have the same type
            if (!from.has_same_type(to))
                return false;
            // Check if the target would lead to a recursion
            // If yes, return the value of allow_recursion. If this
            // value is set to true, it's completely fine to have
            // a recursive graph
            if (to is Source && from is Sink) {
                if (!allow_recursion)
                    if (
                        from.node.is_recursive_forward(to.node) ||
                        to.node.is_recursive_backward(from.node)
                    ) return false;
            }
            if (to is Sink && from is Source) {
                if (!allow_recursion)
                    if (
                        to.node.is_recursive_forward(from.node) ||
                        from.node.is_recursive_backward(to.node)
                    ) return false;
            }
            if (to is Sink && from is Sink) {
                Source? s = ((Sink) from).sources.last().nth_data(0);
                if (s == null)
                    return false;
                if (!allow_recursion)
                    if (
                        to.node.is_recursive_forward(s.node) ||
                        s.node.is_recursive_backward(to.node)
                    ) return false;
            }
            // If the from from-target is a sink, check if the
            // to target is either a source which does not belong to the own node
            // or if the to target is another sink (this is valid as we can
            // move a connection from one sink to another
            if (
                from is Sink
                && ((to is Sink
                && to != from)
                || (to is Source
                && (!to.node.has_socket(from) || allow_recursion)))
            ) return true;
            
            // Check if the from-target is a source. if yes, make sure the
            // to-target is a sink and it does not belong to the own node
            else if (
                from is Source
                && to is Sink
                && (!to.node.has_socket(from) || allow_recursion)
            ) return true;
            
            return false;
        }
        
        internal signal void draw_minimap();
        
        protected override void snapshot(Gtk.Snapshot snapshot) {
            // Snapshot all childs not including 'Rubberband'
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                if (child is Rubberband)
                    continue;
                
                snapshot_child(child, snapshot);
            }
            
            foreach (var node in get_nodes()) {
                Graphene.Point sink_point, source_point;
                
                foreach (Sink sink in node.get_sinks()) {
                    
                    foreach (Source source in sink.sources) {
                        if (
                            temp_connected_socket != null && source == temp_connected_socket
                            && clicked_socket != null && sink == clicked_socket
                        ) continue;
                        
                        sink.compute_point(this, { 8, 8 }, out sink_point);
                        source.compute_point(this, { 8, 8 }, out source_point);
                        
                        renderer.snapshot_connection(
                            snapshot,
                            source, sink,
                            {
                                (int) source_point.x, (int) source_point.y,
                                (int) (sink_point.x - source_point.x), (int) (sink_point.y - source_point.y)
                            }
                        );
                    }
                }
            }
            draw_minimap();
            if (temp_connector != null)
                renderer.snapshot_temp_connector(snapshot, temp_connected_socket, temp_connector);
            
            // Snapshot rubberband over all widgets & custom drawing
            if (rubberband != null)
                snapshot_child(rubberband, snapshot);
        }
    }
    
    protected class NodeViewLayoutChild : Gtk.LayoutChild {
        public int x = 0;
        public int y = 0;
        
        public NodeViewLayoutChild(Gtk.Widget widget, Gtk.LayoutManager layout_manager) {
            Object(child_widget: widget, layout_manager: layout_manager);
        }
    }
    
    private class NodeViewLayoutManager : Gtk.LayoutManager {
        
        protected override Gtk.SizeRequestMode get_request_mode(Gtk.Widget widget) {
            return Gtk.SizeRequestMode.CONSTANT_SIZE;
        }
        
        protected override void measure(Gtk.Widget widget, Gtk.Orientation orientation, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            var node_view = widget as NodeView;
            
            int lower_bound = 0;
            int upper_bound = 0;
            
            foreach (var node in node_view.get_nodes()) {
                var layout = (NodeViewLayoutChild) get_layout_child(node);
                
                switch (orientation) {
                    case Gtk.Orientation.HORIZONTAL:
                        if (layout.x < 0)
                            lower_bound = int.min(layout.x, lower_bound);
                        else
                            upper_bound = int.max(layout.x + node.get_width(), upper_bound);
                        
                        break;
                    case Gtk.Orientation.VERTICAL:
                        if (layout.y < 0)
                            lower_bound = int.min(layout.y, lower_bound);
                        else
                            upper_bound = int.max(layout.y + node.get_height(), upper_bound);
                        
                        break;
                }
            }
            
            min = upper_bound - lower_bound;
            pref = upper_bound - lower_bound;
            min_base = -1;
            pref_base = -1;
        }
        
        protected override void allocate(Gtk.Widget widget, int height, int width, int baseline) {
            for (var child = widget.get_first_child(); child != null; child = child.get_next_sibling()) {
                if (child is Gtk.Native)
                    continue;
                
                int child_width, child_height, _;
                
                child.measure(Gtk.Orientation.HORIZONTAL, -1, out child_width, out _, out _, out _);
                child.measure(Gtk.Orientation.VERTICAL, -1, out child_height, out _, out _, out _);
                
                var layout = (NodeViewLayoutChild) get_layout_child(child);
                
                child.queue_allocate();
                child.allocate_size({
                    layout.x, layout.y,
                    child_width, child_height
                }, -1);
            }
        }
        
        public override Gtk.LayoutChild create_layout_child(Gtk.Widget widget, Gtk.Widget for_child)  {
            return new NodeViewLayoutChild(for_child, this);
        }
    }
}
