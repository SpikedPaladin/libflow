namespace Flow {
    
    [GtkTemplate (ui = "/me/paladin/libflow/ui/node.ui")]
    public class Node : NodeRenderer {
        private List<Source> sources = new List<Source>();
        private List<Sink> sinks = new List<Sink>();
        
        private Gtk.Widget _title_widget;
        private TitleStyle _title_style = TitleStyle.FLAT;
        private Gtk.Widget _content;
        private bool _selected;
        
        [GtkChild]
        private unowned Gtk.PopoverMenu menu;
        [GtkChild]
        private unowned Gtk.Box main_box;
        [GtkChild]
        private unowned Gtk.Box title_box;
        [GtkChild]
        private unowned Gtk.Box sink_box;
        [GtkChild]
        private unowned Gtk.Box source_box;
        [GtkChild]
        private unowned Gtk.Box content_box;
        public override bool selected {
            get { return _selected; }
            set {
                if (value)
                    set_state_flags(Gtk.StateFlags.SELECTED, false);
                else
                    unset_state_flags(Gtk.StateFlags.SELECTED);
                
                _selected = value;
            }
        }
        public Gtk.Widget title_widget {
            get { return _title_widget; }
            set {
                if (_title_widget == value)
                    return;
                
                _title_widget?.unparent();
                _title_widget = value;
                
                if (_title_widget != null)
                    title_box.append(_title_widget);
            }
        }
        public TitleStyle title_style {
            get { return _title_style; }
            set {
                _title_style = value;
                title_box.css_classes = value.get_css_styles();
            }
        }
        public Gtk.Widget content {
            get { return _content; }
            set {
                if (_content == value)
                    return;
                
                content_box.visible = false;
                _content?.unparent();
                _content = value;
                
                if (_content != null) {
                    content_box.visible = true;
                    content_box.append(_content);
                }
            }
        }
        
        static construct {
            set_css_name("node");
        }
        
        construct {
            var action_group = new SimpleActionGroup();
            var delete_action = new SimpleAction("delete", null);
            delete_action.activate.connect(() => {
                @delete();
            });
            action_group.add_action(delete_action);
            
            var unlink_action = new SimpleAction("unlink-all", null);
            unlink_action.activate.connect(() => {
                unlink_all();
            });
            action_group.add_action(unlink_action);
            var test_action = new SimpleAction("test", null);
            
            insert_action_group("node", action_group);
            
            set_layout_manager(new Gtk.BinLayout());
            
            notify["x"].connect(update_position);
            notify["y"].connect(update_position);
            notify["parent"].connect(update_position);
        }
        
        public void set_label_name(string name, Gtk.Align halign = Gtk.Align.CENTER, bool bold = true) {
            var label = new Gtk.Label(name) { halign = halign };
            
            if (bold)
                label.set_markup(@"<b>$name</b>");
            
            title_widget = label;
        }
        
        public virtual void @delete() {
            var node_view = parent as NodeView;
            
            node_view.remove(this);
        }
        
        /**
         * {@inheritDoc}
         */
        public override void dispose() {
            main_box.unparent();
            menu.unparent();
            base.dispose();
        }
        
        public new void sink_added(Sink sink) {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.spacing = 5;
            
            box.append(sink);
            box.append(sink.label);
            
            sink_box.append(box);
        }
        
        public new void source_added(Source source) {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.spacing = 5;
            
            box.append(source.label);
            box.append(source);
            
            source_box.append(box);
        }
        
        [GtkCallback]
        private void begin_drag(double x, double y) {
            var picked_widget = pick(x,y, Gtk.PickFlags.NON_TARGETABLE);
            
            if (picked_widget != this && !can_drag(picked_widget))
                return;
            
            Gdk.Rectangle resize_area = { get_width() - 8, get_height() - 8, 8, 8 };
            var node_view = parent as NodeView;
            
            if (resize_area.contains_point((int) x, (int) y)) {
                node_view.resize_node = this;
                resize_start_width = get_width();
                resize_start_height = get_height();
            } else {
                node_view.move_node = this;
            }
            
            click_offset_x = x;
            click_offset_y = y;
        }
        
        [GtkCallback]
        private void open_menu(int n_clicks, double x, double y) {
            menu.set_pointing_to({ (int) x, (int) y, 1, 1 });
            menu.popup();
        }
        
        /**
         * {@inheritDoc}
         */
        public new void set_parent(Gtk.Widget parent) {
            if (!(parent is NodeView)) {
                warning("Trying to add a Flow.Node to something that is not a Flow.NodeView!");
                return;
            }
            base.set_parent(parent);
        }
        
        /**
         * Add the given {@link Source} to this Node
         */
        public override void add_source(Source source) {
            if (source.node != null)
                return; // This Source is already bound
            
            if (sources.index(source) != -1)
                return; // This node already has this source
            
            sources.append(source);
            source.node = this;
            source_added(source);
        }
        
        /**
         * Add the given {@link Sink} to this Node
         */
        public override void add_sink(Sink sink) {
            if (sink.node != null)
                return; // This Sink is already bound
            
            if (sinks.index(sink) != -1)
                return; //This node already has this sink
            
            sinks.append(sink);
            sink.node = this;
            sink_added(sink);
        }

        /**
         * Remove the given {@link Source} from this Node
         */
        public override void remove_source(Source source) {
            if (sources.index(source) == -1)
                return; // This node doesn't have this source
            
            sources.remove(source);
            source.node = null;
            source_removed(source);
        }

        /**
         * Remove the given {@link Sink} from this Node
         */
        public override void remove_sink(Sink sink) {
            if (sinks.index(sink) == -1)
                return; // This node doesn't have this sink
            
            sinks.remove(sink);
            sink.node = null;
            sink_removed(sink);
        }

        /**
         * Returns true if the given {@link Sink} is one of this Node's sinks.
         */
        public override bool has_sink(Sink sink) {
            return sinks.index(sink) != -1;
        }

        /**
         * Returns true if the given {@link Source} is one of this Node's sources.
         */
        public override bool has_source(Source source) {
            return sources.index(source) != -1;
        }

        /**
         * Returns true if the given {@link Socket} is one of this Node's sockets.
         */
        public override bool has_socket(Socket socket) {
            if (socket is Source)
                return has_source(socket as Source);
            else
                return has_sink(socket as Sink);
        }

        /**
         * Searches this Node's {@link Socket}s for a Socket with the given name.
         * If there is any, it will be returned. Else, null will be returned
         */
        public override Socket? get_socket(string name) {
            foreach (Sink s in sinks)
                if (s.name == name)
                    return s;
            foreach (Source s in sources)
                if (s.name == name)
                    return s;
            return null;
        }

        /**
         * Returns the sources of this node
         */
        public override unowned List<Source> get_sources() {
            return sources;
        }

        /**
         * Returns the sinks of this node
         */
        public override unowned List<Sink> get_sinks() {
            return sinks;
        }
        
        /**
         * This method checks whether a connection from the given from-Node
         * to this Node would lead to a recursion in the direction source -> sink
         */
        public override bool is_recursive_forward(NodeRenderer from, bool initial = true) {
            if (!initial && this == from)
                return true;
            
            foreach (Source source in get_sources())
                foreach (Sink sink in source.sinks)
                    if (sink.node.is_recursive_forward(from, false))
                        return true;
            
            return false;
        }
        
        /**
         * This method checks whether a connection from the given from-Node
         * to this Node would lead to a recursion in the direction sink -> source
         */
        public override bool is_recursive_backward(NodeRenderer from, bool initial = true) {
            if (!initial && this == from)
                return true;
            
            foreach (Sink sink in sinks)
                foreach (Source source in sink.sources)
                    if (source.node.is_recursive_backward(from, false))
                        return true;
            
            return false;
        }

        /**
         * Gets all neighbor nodes that this node is connected to
         */
        public override List<NodeRenderer> get_neighbors() {
            var result = new List<NodeRenderer>();
            
            foreach (Source source in get_sources())
                foreach (Sink sink in source.sinks)
                    if (sink.node != null && result.index(sink.node) == -1)
                        result.append(sink.node);
            
            foreach (Sink sink in get_sinks())
                foreach (Source source in sink.sources)
                    if (source.node != null && result.index(source.node) == -1)
                        result.append(source.node);
            
            return result;
        }

        /**
         * Returns true if the given node is directly connected
         * to this node
         */
        public override bool is_neighbor(NodeRenderer node) {
            return get_neighbors().index(node) != -1;
        }

        /**
         * Disconnect all connections from and to this node
         */
        public override void unlink_all() {
            foreach (Source source in sources)
                source.unlink_all();
            
            foreach (Sink sink in sinks)
                sink.unlink_all();
        }
        
        private bool can_drag(Gtk.Widget widget) {
            if (!has_gestures(widget)) {
                for (var parent = widget.parent; parent != this; parent = parent.parent) {
                    if (has_gestures(parent)) {
                        return false;
                    }
                }
                return true;
            }
            return false;
        }
        
        private bool has_gestures(Gtk.Widget widget) {
            var list = widget.observe_controllers();
            for (int i = 0; i < list.get_n_items(); i++)
                if (list.get_item(i) is Gtk.Gesture)
                    return true;
            
            return false;
        }
        
        private void update_position() {
             var node_view = parent as NodeView;
             
             if (node_view == null)
                 return;
             
             var layout = node_view.get_layout(this);
             
             layout.x = x;
             layout.y = y;
        }
    }
    
    public abstract class NodeRenderer : Gtk.Widget {
        /**
         * Expresses wheter this node is marked via rubberband selection
         */
        public virtual bool selected { get; set; }
        /**
         * Determines wheter the user be allowed to remove the node. Otherwise
         * the node can only be removed programmatically
         */
        public bool deletable { get; set; default = true; }
        /**
         * Determines wheter the user be allowed to remove the node. Otherwise
         * the node can only be removed programmatically
         */
        public bool resizable { get; set; default = true; }
        public Gdk.RGBA? highlight_color { get; set; default = null; }
        public int x { get; set; default = 0; }
        public int y { get; set; default = 0; }
        /**
         * Click offset: x coordinate
         *
         * Holds the offset-position relative to the origin of the
         * node at which this node has been clicked the last time.
         */
        public double click_offset_x { get; protected set; default = 0; }
        /**
         * Click offset: y coordinate
         *
         * Holds the offset-position relative to the origin of the
         * node at which this node has been clicked the last time.
         */
        public double click_offset_y { get; protected set; default = 0; }
        
        /**
         * Resize start width
         *
         * Hold the original width of the node when the last resize process
         * had been started
         */
        public double resize_start_width { get; protected set; default = 0; }
        /**
         * Resize start height
         *
         * Hold the original height of the node when the last resize process
         * had been started
         */
        public double resize_start_height { get; protected set; default = 0; }
        /**
         * This signal is being triggered when a {@link Sink} is added to this Node
         */
        public signal void sink_added(Sink sink);
        /**
         * This signal is being triggered when a {@link Source} is added to this Node
         */
        public signal void source_added(Source source);
        /**
         * This signal is being triggered when a {@link Sink} is removed from this Node
         */
        public signal void sink_removed(Sink sink);
        /**
         * This signal is being triggered when a {@link Source} is removed from this Node
         */
        public signal void source_removed(Source sink);
        
        /**
         * Implementations should destroy all connections of this Node's {@link Sink}s
         * and {@link Source}s when this method is executed
         */
        public abstract void unlink_all();
        /**
         * Determines whether the given from-{@link Node} can be found if we
         * recursively follow all nodes that are connected to this node's {@link Source}s
         */
        public abstract bool is_recursive_forward(NodeRenderer from, bool initial = false);
        /**
         * Determines whether the given from-{@link Node} can be found if we
         * recursively follow all nodes that are connected to this node's {@link Sink}s
         */
        public abstract bool is_recursive_backward(NodeRenderer from, bool initial = false);
        /**
         * Implementations should return the {@link Socket} with the given name if they contain
         * any. If not, return null.
         */
        public abstract Socket? get_socket(string name);
        /**
         * Implementations should return true if the given {@link Socket} has been
         * assigned to this node
         */
        public abstract bool has_socket(Socket socket);
        /**
         * Return a {@link GLib.List} of this Node's {@link Source}s
         */
        public abstract unowned List<Source> get_sources();
        /**
         * Return a {@link GLib.List} of this Node's {@link Sink}s
         */
        public abstract unowned List<Sink> get_sinks();
        /**
         * Returns the Nodes that this Node is connected to
         */
        public abstract List<NodeRenderer> get_neighbors();
        /**
         * Returns true if the given node is directly connected to this node
         */
        public abstract bool is_neighbor(NodeRenderer node);
        /**
         * Assign a {@link Source} to this Node
         */
        public abstract void add_source(Source source);
        /**
         * Remove a {@link Source} from this Node
         */
        public abstract void remove_source(Source source);
        /**
         * Return true if the supplied {@link Source} is assigned to this Node
         */
        public abstract bool has_source(Source source);
        /**
         * Assign a {@link Sink} to this Node
         */
        public abstract void add_sink(Sink sink);
        /**
         * Return true if the supplied {@link Sink} is assigned to this Node
         */
        public abstract bool has_sink(Sink sink);
        /**
         * Remove a {@link Sink} from this Node
         */
        public abstract void remove_sink(Sink sink);
    }
}
