namespace GtkFlow {
    private errordomain InternalError {
        DOCKS_NOT_SUITABLE
    }
    
    private class NodeViewLayoutManager : Gtk.LayoutManager {
        protected override Gtk.SizeRequestMode get_request_mode (Gtk.Widget widget) {
            return Gtk.SizeRequestMode.CONSTANT_SIZE;
        }
        
        protected override void measure(Gtk.Widget w, Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            int lower_bound = 0;
            int upper_bound = 0;
            var c = w.get_first_child();
            while (c != null) {
                var lc = (NodeViewLayoutChild) get_layout_child(c);
                switch (o) {
                    case Gtk.Orientation.HORIZONTAL:
                        if (lc.x < 0) {
                            lower_bound = int.min(lc.x, lower_bound);
                        } else {
                            upper_bound = int.max(lc.x + c.get_width(), upper_bound);
                        }
                        break;
                    case Gtk.Orientation.VERTICAL:
                        if (lc.y < 0) {
                            lower_bound = int.min(lc.y, lower_bound);
                        } else {
                            upper_bound = int.max(lc.y + c.get_height(), upper_bound);
                        }
                        break;
                }
                
                c = c.get_next_sibling();
            }
            min = upper_bound - lower_bound;
            pref = upper_bound - lower_bound;
            min_base = -1;
            pref_base = -1;
        }
        
        protected override void allocate(Gtk.Widget w, int height, int width, int baseline) {
            var c = w.get_first_child();
            while (c != null) {
                int cwidth, cheight, _;
                c.measure(Gtk.Orientation.HORIZONTAL, -1, out cwidth, out _, out _, out _);
                c.measure(Gtk.Orientation.VERTICAL, -1, out cheight, out _, out _, out _);
                var lc = (NodeViewLayoutChild) get_layout_child(c);
                c.queue_allocate();
                c.allocate_size({lc.x,lc.y, cwidth, cheight}, -1);
                c = c.get_next_sibling();
            }
        }
        public override Gtk.LayoutChild create_layout_child (Gtk.Widget widget, Gtk.Widget for_child)  {
            return new NodeViewLayoutChild(for_child, this);
        }
    }
    
    private class NodeViewLayoutChild : Gtk.LayoutChild {
        public int x = 0;
        public int y = 0;
        
        public NodeViewLayoutChild(Gtk.Widget w, Gtk.LayoutManager lm) {
            Object(child_widget: w, layout_manager: lm);
        }
    }
    
    /**
     * A widget that displays flowgraphs expressed through {@link GFlow} objects
     *
     * This allows you to add {@link GFlow.Node}s to it in order to display
     * A graph of these nodes and their connections.
     */
    public class NodeView : Gtk.Widget {
        construct {
            set_css_name("gtkflow_nodeview");
        }
        
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
        private Gtk.EventControllerMotion ctr_motion;
        private Gtk.GestureClick ctr_click;
        
        private Gtk.Popover menu;
        /**
         * The current extents of the temporary connector
         * if null, there is no temporary connector drawn at the moment
         */
        private Gdk.Rectangle? temp_connector = null;
        
        /**
         * The dock that the temporary connector will be attched to
         */
        private Dock? temp_connected_dock = null;
        /**
         * The dock that was clicked to invoke the temporary connector
         */
        private Dock? clicked_dock = null;
        /**
         * The node that is being moved right now via mouse drag.
         * The node that receives the button press event registers
         * itself with this property
         */
        internal NodeRenderer? move_node {get; set; default=null;}
        internal NodeRenderer? resize_node {get; set; default=null;}
        
        /**
         * A rectangle detailing the extents of a rubber marking
         */
        private Gdk.Rectangle? mark_rubberband = null;
        
        /**
         * Instantiate a new NodeView
         */
        public NodeView() {
            set_layout_manager(new NodeViewLayoutManager());
            set_size_request(100,100);
            
            ctr_motion = new Gtk.EventControllerMotion();
            add_controller(ctr_motion);
            ctr_motion.motion.connect((x,y)=> { process_motion(x,y); });
            
            ctr_click = new Gtk.GestureClick();
            add_controller(ctr_click);
            ctr_click.set_button(0);
            ctr_click.pressed.connect(start_marking);
            ctr_click.released.connect(end_temp_connector);
            menu = new Gtk.Popover();
            menu.set_parent(this);
            menu.set_has_arrow(false);
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
            
            var action_button = new Gtk.Button.with_label("Action");
            action_button.clicked.connect(() => {
                print("Action callback\n");
            });
            action_button.set_has_frame(false);
            box.append(action_button);
            
            menu.set_child(box);
        }
        
        /**
         * {@inheritDoc}
         */
        public override void dispose() {
            var nodewidget = get_first_child();
            while (nodewidget != null) {
                var delnode = nodewidget;
                nodewidget = nodewidget.get_next_sibling();
                delnode.unparent();
            }
            base.dispose();
        }
        
        private List<unowned NodeRenderer> get_marked_nodes() {
            var result = new List<unowned NodeRenderer>();
            var nodewidget = get_first_child();
            while (nodewidget != null) {
                if (nodewidget is Gtk.Popover) {
                    nodewidget = nodewidget.get_next_sibling();
                    continue;
                }
                
                var node = (NodeRenderer)nodewidget;
                if (node.marked) {
                    result.append(node);
                }
                nodewidget = nodewidget.get_next_sibling();
            }
            return result;
        }
        
        public void move(NodeRenderer node, int x, int y) {
            var lc = (NodeViewLayoutChild) layout_manager.get_layout_child(node);
            lc.x = x;
            lc.y = y;
        }
        
        private void process_motion(double x, double y) {
            if (move_node != null) {
                var lc = (NodeViewLayoutChild) layout_manager.get_layout_child(move_node);
                int old_x = lc.x;
                int old_y = lc.y;
                lc.x = (int) (x - move_node.click_offset_x);
                lc.y = (int) (y - move_node.click_offset_y);
                if (move_node.marked) {
                    foreach (NodeRenderer n in get_marked_nodes()) {
                        if (n == move_node) continue;
                        var mlc = (NodeViewLayoutChild) layout_manager.get_layout_child(n);
                        mlc.x -= old_x - lc.x;
                        mlc.y -= old_y - lc.y;
                    }
                }
            }
            
            if (resize_node != null) {
                int d_x, d_y;
                Gtk.Allocation node_alloc;
                resize_node.get_allocation(out node_alloc);
                d_x = (int)(x-resize_node.click_offset_x-node_alloc.x);
                d_y = (int)(y-resize_node.click_offset_y-node_alloc.y);
                int new_width = (int)resize_node.resize_start_width+d_x;
                int new_height = (int)resize_node.resize_start_height+d_y;
                resize_node.set_size_request(new_width, new_height);
            }
            
            if (temp_connector != null) {
                var n = (NodeRenderer)retrieve_node(temp_connected_dock.d.node);
                temp_connector.width = (int)(x - temp_connector.x-n.get_margin());
                temp_connector.height = (int)(y - temp_connector.y-n.get_margin());
            }
            
            if (mark_rubberband != null) {
                mark_rubberband.width = (int)(x - mark_rubberband.x);
                mark_rubberband.height = (int)(y - mark_rubberband.y);
                var nodewidget = get_first_child();
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
                Gdk.Rectangle result;
                while (nodewidget != null) {
                    if (nodewidget is Gtk.Popover) {
                        nodewidget = nodewidget.get_next_sibling();
                        continue;
                    }
                    
                    var node = (NodeRenderer) nodewidget;
                    
                    node.get_allocation(out node_alloc);
                    node_alloc.intersect(absolute_marked, out result);
                    node.marked = result == node_alloc;
                    nodewidget = node.get_next_sibling();
                }
            }
            
            queue_allocate();
        }
        
        
        private void start_marking(int n_clicks, double x, double y) {
            if (ctr_click.get_current_button() == Gdk.BUTTON_PRIMARY) {
                if (pick(x, y, Gtk.PickFlags.DEFAULT) == this)
                    mark_rubberband = {(int)x,(int)y,0,0};
            } else if (ctr_click.get_current_button() == Gdk.BUTTON_SECONDARY) {
                menu.set_pointing_to({ (int) x, (int) y, 1, 1 });
                menu.popup();
            }
        }
        
        internal void start_temp_connector(Dock d) {
            clicked_dock = d;
            if (d.d is GFlow.Sink && d.d.is_linked()) {
                var sink = (GFlow.Sink)d.d;
                temp_connected_dock = retrieve_dock(sink.sources.last().nth_data(0));
            } else {
                temp_connected_dock = d;
            }
            var node = retrieve_node(temp_connected_dock.d.node);
            
            Gtk.Allocation node_alloc, dock_alloc;
            node.get_allocation(out node_alloc);
            temp_connected_dock.get_allocation(out dock_alloc);
            var x = node_alloc.x + dock_alloc.x + 8;
            var y = node_alloc.y + dock_alloc.y + 8;
            temp_connector = {x, y, 0, 0};
        }
        
        internal void end_temp_connector(int n_clicks, double x, double y) {
            if (ctr_click.get_current_button() != Gdk.BUTTON_PRIMARY) return;
            
            if (temp_connector != null) {
                var w = pick(x,y,Gtk.PickFlags.DEFAULT);
                if (w is Dock) {
                    var pd = (Dock)w;
                    if (pd.d is GFlow.Source && temp_connected_dock.d is GFlow.Sink
                     || pd.d is GFlow.Sink && temp_connected_dock.d is GFlow.Source) {
                        try {
                            if (!is_suitable_target(pd.d, temp_connected_dock.d)) {
                                throw new InternalError.DOCKS_NOT_SUITABLE("Can't link because is no good");
                            }
                            pd.d.link(temp_connected_dock.d);
                        } catch (Error e) {
                            warning("Could not link: "+e.message);
                        }
                    }
                    else if (pd.d is GFlow.Sink && clicked_dock != null
                      && clicked_dock.d is GFlow.Sink
                      && temp_connected_dock is GFlow.Source) {
                        try {
                            if (!is_suitable_target(pd.d, temp_connected_dock.d)) {
                                throw new InternalError.DOCKS_NOT_SUITABLE("Can't link because is no good");
                            }
                            clicked_dock.d.unlink(temp_connected_dock.d);
                            pd.d.link(temp_connected_dock.d);
                        } catch (Error e) {
                            warning("Could not edit links: "+e.message);
                        }
                    }
                    pd.queue_draw();
                } else {
                    if (
                        temp_connected_dock.d is GFlow.Source
                        && clicked_dock != null
                        && clicked_dock.d is GFlow.Sink
                    ) {
                        try {
                            clicked_dock.d.unlink(temp_connected_dock.d);
                        } catch (Error e) {
                            warning("Could not unlink: "+e.message);
                        }
                     }
                }
                
                queue_draw();
                temp_connected_dock.queue_draw();
                if (clicked_dock != null) {
                    clicked_dock.queue_draw();
                }
                clicked_dock = null;
                temp_connected_dock = null;
                temp_connector = null;
            }
            
            update_extents();
            queue_resize();
            mark_rubberband = null;
            queue_allocate();
        }
        
        private void update_extents() {
            int min_x=0, min_y = 0;
            NodeViewLayoutChild lc;
            var child = get_first_child();
            while (child != null) {
                lc = (NodeViewLayoutChild) layout_manager.get_layout_child(child);
                min_x = int.min(min_x, lc.x);
                min_y = int.min(min_y, lc.y);
                child = child.get_next_sibling();
            }
            if (min_x >= 0 && min_y >= 0)
                return;
            
            child = get_first_child();
            while (child != null) {
                lc = (NodeViewLayoutChild) layout_manager.get_layout_child(child);
                if (min_x < 0)
                lc.x += -min_x;
                if (min_y < 0)
                lc.y += -min_y;
                child = child.get_next_sibling();
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
        public void add(NodeRenderer n) {
            n.set_parent (this);
        }
        
        /**
         * Remove a node from this nodeview
         */
        public void remove(NodeRenderer n) {
            n.n.unlink_all();
            var child = get_first_child ();
            while (child != null) {
                if (child == n) {
                    child.unparent();
                    return;
                }
                child = child.get_next_sibling();
            }
            warning("Tried to remove a node that is not a child of nodeview");
        }
        
        /**
         * Retrieve a Node-Widget from this node.
         *
         * Gives you the {@link GtkFlow.Node}-object that corresponds to the given
         * {@link GFlow.Node}. Returns null if the searched Node is not associated
         * with any of the Node-Widgets in this nodeview.
         */
        public NodeRenderer? retrieve_node(GFlow.Node node) {
            var child = get_first_child();
            while (child != null) {
                if (!(child is NodeRenderer)) {
                    child = child.get_next_sibling();
                    continue;
                }
                
                var node_widget = child as NodeRenderer;
                if (node_widget.n == node)
                    return node_widget;
                
                child = child.get_next_sibling();
            }
            return null;
        }
        
        /**
         * Retrieve a Dock-Widget from this nodeview.
         *
         * Gives you a {@link Dock}-object that corresponds to the given
         * {@link GFlow.Dock}. Returns null if the given Dock is not 
         * associated with any of the Dock-Widgets in this nodeview.
         */
        public Dock? retrieve_dock(GFlow.Dock dock) {
            var child = get_first_child();
            Dock? found = null;
            while (child != null) {
                if (!(child is NodeRenderer)) {
                    child = child.get_next_sibling();
                    continue;
                }
                
                var node_widget = child as NodeRenderer;
                found = node_widget.retrieve_dock(dock);
                if (found != null) return found;
                
                child = child.get_next_sibling();
            }
            return null;
        }
        
        /**
         * Determines wheter one dock can be dropped on another
         */
        private bool is_suitable_target(GFlow.Dock from, GFlow.Dock to) {
            // Check whether the docks have the same type
            if (!from.has_same_type(to))
                return false;
            // Check if the target would lead to a recursion
            // If yes, return the value of allow_recursion. If this
            // value is set to true, it's completely fine to have
            // a recursive graph
            if (to is GFlow.Source && from is GFlow.Sink) {
                if (!allow_recursion)
                    if (
                        from.node.is_recursive_forward(to.node) ||
                        to.node.is_recursive_backward(from.node)
                    ) return false;
            }
            if (to is GFlow.Sink && from is GFlow.Source) {
                if (!allow_recursion)
                    if (
                        to.node.is_recursive_forward(from.node) ||
                        from.node.is_recursive_backward(to.node)
                    ) return false;
            }
            if (to is GFlow.Sink && from is GFlow.Sink) {
                GFlow.Source? s = ((GFlow.Sink) from).sources.last().nth_data(0);
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
                from is GFlow.Sink
                && ((to is GFlow.Sink
                && to != from)
                || (to is GFlow.Source
                && (!to.node.has_dock(from) || allow_recursion)))
            ) return true;
            
            // Check if the from-target is a source. if yes, make sure the
            // to-target is a sink and it does not belong to the own node
            else if (
                from is GFlow.Source
                && to is GFlow.Sink
                && (!to.node.has_dock(from) || allow_recursion)
            ) return true;
            
            return false;
        }
        
        internal signal void draw_minimap();
        
        protected override void snapshot(Gtk.Snapshot sn) {
            base.snapshot(sn);
            var rect = Graphene.Rect().init(0, 0, (float) get_width(), (float) get_height());
            var cr = sn.append_cairo(rect);
            
            Gdk.RGBA color = { 0, 0, 0, 1 };
            
            var c = get_first_child();
            while (c != null) {
                if (c is Gtk.Popover) {
                    c = c.get_next_sibling();
                    continue;
                }
                
                var nr = (NodeRenderer) c;
                
                int tgt_x, tgt_y, src_x, src_y, w, h;
                foreach (GFlow.Sink snk in nr.n.get_sinks()) {
                    var target_widget = retrieve_dock(snk);
                    Gtk.Allocation tgt_alloc, tgt_node_alloc;
                    target_widget.get_allocation(out tgt_alloc);
                    nr.get_allocation(out tgt_node_alloc);
                    foreach (GFlow.Source src in snk.sources) {
                        if (
                            temp_connected_dock != null && src == temp_connected_dock.d
                            && clicked_dock != null && snk == clicked_dock.d
                        ) continue;
                        var source_widget = retrieve_dock(src);
                        var source_node = retrieve_node(src.node);
                        Gtk.Allocation src_alloc, src_node_alloc;
                        source_widget.get_allocation(out src_alloc);
                        source_node.get_allocation(out src_node_alloc);
                        
                        src_x = src_alloc.x+src_node_alloc.x + 8 + nr.get_margin();
                        src_y = src_alloc.y+src_node_alloc.y + 8 + nr.get_margin();
                        tgt_x = tgt_alloc.x+tgt_node_alloc.x + 8 + nr.get_margin();
                        tgt_y = tgt_alloc.y+tgt_node_alloc.y + 8 + nr.get_margin();
                        w = tgt_x - src_x;
                        h = tgt_y - src_y;
                        
                        var sourcedock = retrieve_dock(src);
                        if (sourcedock != null)
                            color = sourcedock.resolve_color(sourcedock, sourcedock.last_value);
                        
                        cr.save();
                        cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
                        cr.move_to(src_x, src_y);
                        if (w > 0)
                            cr.rel_curve_to(w / 3, 0, 2 * w / 3, h, w, h);
                        else
                            cr.rel_curve_to(-w / 3, 0, 1.3 * w, h, w, h);
                        
                        cr.stroke();
                        cr.restore();
                    }
                }
                c = c.get_next_sibling();
            }
            draw_minimap();
            if (temp_connector != null) {
                color = temp_connected_dock.resolve_color(
                    temp_connected_dock, temp_connected_dock.last_value
                );
                var nr = retrieve_node(temp_connected_dock.d.node);
                cr.save();
                cr.set_source_rgba(color.red, color.green, color.blue, color.alpha);
                cr.move_to(temp_connector.x + nr.get_margin(), temp_connector.y + nr.get_margin());
                cr.rel_curve_to(
                    temp_connector.width / 3,
                    0,
                    2 * temp_connector.width / 3,
                    temp_connector.height,
                    temp_connector.width,
                    temp_connector.height
                );
                cr.stroke();
                cr.restore();
            }
            if (mark_rubberband != null) {
                cr.save();
                cr.set_source_rgba(0.0, 0.2, 0.9, 0.4);
                cr.rectangle(
                    mark_rubberband.x, mark_rubberband.y,
                    mark_rubberband.width, mark_rubberband.height
                );
                cr.fill();
                cr.set_source_rgba(0.0, 0.2, 1.0, 1.0);
                cr.stroke();
            }
        }
    }
}
