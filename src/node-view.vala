namespace Flow {
    
    public class NodeView : Gtk.Widget {
        /**
         * If this property is set to true, the nodeview will not perform
         * any check wheter newly created connections will result in cycles
         * in the graph. It's completely up to the application programmer
         * to make sure that the logic inside the nodes he uses avoids
         * endlessly backpropagated loops
         */
        public bool allow_recursion { get; set; default = false; }
        
        /**
         * The eventcontrollers to receive events
         */
        private Gtk.EventControllerMotion motion;
        private Gtk.GestureClick click;
        
        private Gtk.Popover menu;
        private Gtk.Widget _menu_content;
        public Gtk.Widget menu_content { get { return _menu_content; } set { _menu_content = value; menu.set_child(value); } }
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
         * The node that is being moved right now via mouse drag.
         * The node that receives the button press event registers
         * itself with this property
         */
        internal NodeRenderer? move_node { get; set; default = null; }
        internal NodeRenderer? resize_node { get; set; default = null; }
        
        /**
         * A rectangle detailing the extents of a rubber marking
         */
        private Gdk.Rectangle? mark_rubberband = null;
        public ConnectionRenderer renderer = new ConnectionRenderer();
        public Rubberband rubberband;
        
        static construct {
            set_css_name("flownodeview");
        }
        
        /**
         * Instantiate a new NodeView
         */
        public NodeView() {
            var css = new Gtk.CssProvider();
            css.load_from_resource("/me/paladin/libflow/css/flow.css");
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            
            set_layout_manager(new NodeViewLayoutManager());
            set_size_request(100, 100);
            
            motion = new Gtk.EventControllerMotion();
            add_controller(motion);
            motion.motion.connect(process_motion);
            
            click = new Gtk.GestureClick();
            add_controller(click);
            click.set_button(0);
            click.pressed.connect(start_marking);
            click.released.connect(end_temp_connector);
            
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
        
        private NodeViewLayoutChild get_layout(Gtk.Widget widget) {
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
        
        private List<unowned NodeRenderer> get_selected_nodes() {
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
        
        private void process_motion(double x, double y) {
            if (move_node != null) {
                var layout = get_layout(move_node);
                int old_x = layout.x;
                int old_y = layout.y;
                
                int new_x = ((int) x - (int) move_node.click_offset_x);
                int new_y = ((int) y - (int) move_node.click_offset_y);
                
                if (old_x == new_x && old_y == new_y)
                    return;
                
                layout.x = new_x;
                layout.y = new_y;
                
                if (move_node.selected) {
                    foreach (NodeRenderer node in get_selected_nodes()) {
                        if (node == move_node) continue;
                        
                        layout = get_layout(node);
                        layout.x -= old_x - layout.x;
                        layout.y -= old_y - layout.y;
                    }
                }
                
                queue_allocate();
            }
            
            if (resize_node != null) {
                int d_x, d_y;
                Gtk.Allocation node_alloc;
                
                resize_node.get_allocation(out node_alloc);
                
                d_x = (int) (x - resize_node.click_offset_x-node_alloc.x);
                d_y = (int) (y - resize_node.click_offset_y-node_alloc.y);
                
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
            
            if (mark_rubberband != null) {
                mark_rubberband.width = (int) (x - mark_rubberband.x);
                mark_rubberband.height = (int) (y - mark_rubberband.y);
                
                Gtk.Allocation node_alloc;
                Gdk.Rectangle absolute_marked = mark_rubberband;
                
                if (absolute_marked.width < 0) {
                    absolute_marked.width *= -1;
                    absolute_marked.x -= absolute_marked.width;
                }
                
                if (absolute_marked.height < 0) {
                    absolute_marked.height *= -1;
                    absolute_marked.y -= absolute_marked.height;
                }
                
                foreach (var node in get_nodes()) {    
                    Gdk.Rectangle result;
                    
                    node.get_allocation(out node_alloc);
                    node_alloc.intersect(absolute_marked, out result);
                    node.selected = result == node_alloc;
                }
                
                var layout = (NodeViewLayoutChild) layout_manager.get_layout_child(rubberband);
                layout.x = absolute_marked.x;
                layout.y = absolute_marked.y;
                rubberband.set_size_request(absolute_marked.width, absolute_marked.height);
                queue_draw();
            }
        }
        
        private void start_marking(int n_clicks, double x, double y) {
            if (click.get_current_button() == Gdk.BUTTON_PRIMARY) {
                if (pick(x, y, Gtk.PickFlags.DEFAULT) == this) {
                    mark_rubberband = { (int) x, (int) y, 0, 0 };
                    
                    // TODO fix blinking in left top corner
                    rubberband = new Rubberband();
                    rubberband.set_parent(this);
                }
            } else if (click.get_current_button() == Gdk.BUTTON_SECONDARY) {
                menu.set_pointing_to({ (int) x, (int) y, 1, 1 });
                menu.popup();
            }
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
        
        internal void end_temp_connector(int n_clicks, double x, double y) {
            if (click.get_current_button() != Gdk.BUTTON_PRIMARY) return;
            
            if (temp_connector != null) {
                var widget = pick(x, y, Gtk.PickFlags.DEFAULT);
                
                if (widget is Socket) {
                    var socket = (Socket) widget;
                    if (
                        socket is Source && temp_connected_socket is Sink ||
                        socket is Sink && temp_connected_socket is Source
                    ) {
                        if (!is_suitable_target(socket, temp_connected_socket)) {
                            temp_connector = null;
                            return; // Can't link because is no good
                        }
                        socket.link(temp_connected_socket);
                    }
                    else if (
                        socket is Sink && clicked_socket != null &&
                        clicked_socket is Sink &&
                        temp_connected_socket is Source
                    ) {
                        if (!is_suitable_target(socket, temp_connected_socket)) {
                            temp_connector = null;
                            return; // Can't link because is no good
                        }
                        clicked_socket.unlink(temp_connected_socket);
                        socket.link(temp_connected_socket);
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
                
                queue_draw();
                temp_connected_socket.queue_draw();
                if (clicked_socket != null) {
                    clicked_socket.queue_draw();
                }
                clicked_socket = null;
                temp_connected_socket = null;
                temp_connector = null;
            }
            
            update_extents();
            queue_resize();
            mark_rubberband = null;
            rubberband.unparent();
            rubberband = null;
            queue_allocate();
        }
        
        private void update_extents() {
            int min_x = 0, min_y = 0;
            NodeViewLayoutChild layout;
            
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                layout = get_layout(child);
                
                min_x = int.min(min_x, layout.x);
                min_y = int.min(min_y, layout.y);
            }
            
            if (min_x >= 0 && min_y >= 0)
                return;
            
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                layout = get_layout(child);
                
                if (min_x < 0)
                    layout.x += -min_x;
                if (min_y < 0)
                    layout.y += -min_y;
            }
            
            var parent = get_parent();
            if (parent != null && parent is Gtk.Viewport) {
                var scrollwidget = parent.get_parent();
                
                if (parent != null && parent is Gtk.ScrolledWindow) {
                    var sw = (Gtk.ScrolledWindow) scrollwidget;
                    
                    sw.hadjustment.value += (double) (-min_x);
                    sw.vadjustment.value += (double) (-min_y);
                }
            }
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
            var child = get_first_child();
            while (child != null) {
                if (child == node) {
                    child.unparent();
                    return;
                }
                child = child.get_next_sibling();
            }
            warning("Tried to remove a node that is not a child of nodeview");
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
            base.snapshot(snapshot);
            
            var cairo = snapshot.append_cairo(
                Graphene.Rect().init(0, 0, (float) get_width(), (float) get_height())
            );
            
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
                        
                        cairo.save();
                        
                        renderer.render_connection(
                            cairo,
                            
                            source, sink,
                            {
                                (int) source_point.x, (int) source_point.y,
                                (int) (sink_point.x - source_point.x), (int) (sink_point.y - source_point.y)
                            }
                        );
                        
                        cairo.stroke();
                        cairo.restore();
                    }
                }
            }
            draw_minimap();
            if (temp_connector != null) {
                
                cairo.save();
                
                renderer.render_temp_connection(
                    cairo,
                    
                    temp_connected_socket,
                    temp_connector
                );
                
                cairo.stroke();
                cairo.restore();
            }
        }
    }
    
    private class NodeViewLayoutChild : Gtk.LayoutChild {
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
            int lower_bound = 0;
            int upper_bound = 0;
            
            for (var child = widget.get_first_child(); child != null; child = child.get_next_sibling()) {
                var layout = (NodeViewLayoutChild) get_layout_child(child);
                
                switch (orientation) {
                    case Gtk.Orientation.HORIZONTAL:
                        if (layout.x < 0)
                            lower_bound = int.min(layout.x, lower_bound);
                        else
                            upper_bound = int.max(layout.x + child.get_width(), upper_bound);
                        
                        break;
                    case Gtk.Orientation.VERTICAL:
                        if (layout.y < 0)
                            lower_bound = int.min(layout.y, lower_bound);
                        else
                            upper_bound = int.max(layout.y + child.get_height(), upper_bound);
                        
                        break;
                }
            }
            
            min = upper_bound - lower_bound;
            pref = upper_bound - lower_bound;
            min_base = -1;
            pref_base = -1;
        }
        
        protected override void allocate(Gtk.Widget widget, int height, int width, int baseline) {
            var node_view = widget as NodeView;
            
            foreach (var node in node_view.get_nodes()) {
                int node_width, node_height, _;
                
                node.measure(Gtk.Orientation.HORIZONTAL, -1, out node_width, out _, out _, out _);
                node.measure(Gtk.Orientation.VERTICAL, -1, out node_height, out _, out _, out _);
                
                var layout = (NodeViewLayoutChild) get_layout_child(node);
                
                node.queue_allocate();
                node.allocate_size({
                    layout.x, layout.y,
                    node_width, node_height
                }, -1);
            }
            
            if (node_view.rubberband != null) {
                int node_width, node_height, _;
                
                node_view.rubberband.measure(Gtk.Orientation.HORIZONTAL, -1, out node_width, out _, out _, out _);
                node_view.rubberband.measure(Gtk.Orientation.VERTICAL, -1, out node_height, out _, out _, out _);
                
                var layout = (NodeViewLayoutChild) get_layout_child(node_view.rubberband);
                node_view.rubberband.queue_allocate();
                node_view.rubberband.allocate_size({
                    layout.x, layout.y,
                    node_width, node_height
                }, -1);
            }
        }
        
        public override Gtk.LayoutChild create_layout_child(Gtk.Widget widget, Gtk.Widget for_child)  {
            return new NodeViewLayoutChild(for_child, this);
        }
    }
}
