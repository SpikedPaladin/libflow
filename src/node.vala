namespace GtkFlow {
    /**
     * Defines an object that can be added to a Nodeview
     *
     * Implement this if you want custom nodes that have their own
     * drawing routines and special behaviour
     */
    public interface NodeRenderer : Gtk.Widget {
        /**
         * The {@link GFlow.Node} that this Node represents
         */
        public abstract GFlow.Node n { get; protected set; }
        /**
         * Expresses wheter this node is marked via rubberband selection
         */
        public abstract bool marked { get; internal set; }
        /**
         * Returns a {@link Dock} if the given {@link GFlow.Dock} resides
         * in this node.
         */
        public abstract Dock? retrieve_dock(GFlow.Dock d);
        /**
         * Returns the value of this node's margin
         */
        public abstract int get_margin();
        /**
         * Click offset: x coordinate
         *
         * Holds the offset-position relative to the origin of the
         * node at which this node has been clicked the last time.
         */
        public abstract double click_offset_x { get; protected set; default = 0; }
        /**
         * Click offset: y coordinate
         *
         * Holds the offset-position relative to the origin of the
         * node at which this node has been clicked the last time.
         */
        public abstract double click_offset_y { get; protected set; default = 0; }
        
        /**
         * Resize start width
         *
         * Hold the original width of the node when the last resize process
         * had been started
         */
        public abstract double resize_start_width { get; protected set; default = 0; }
        /**
         * Resize start height
         *
         * Hold the original height of the node when the last resize process
         * had been started
         */
        public abstract double resize_start_height { get; protected set; default = 0; }
    }
    
    
    /**
     * A Simple node representation
     *
     * The default {@link NodeRenderer} that comes with libgtkflow. Use this
     * To wrap your {@link GFlow.Node}s in order to add them to a {@link NodeView}
     */
    public class Node : Gtk.Widget, NodeRenderer  {
    
        construct {
            set_css_name("gtkflow_node");
        }
        
        public const int MARGIN = 10;
        
        private Gtk.Grid grid;
        private Gtk.Popover menu;
        private Gtk.GestureClick ctr_click;
        public GFlow.Node n { get; protected set; }
        
        /**
         * {@inheritDoc}
         */
        public bool marked { get; internal set; }
        /**
         * User-controlled node resizability
         *
         * Set to true if this should be resizable
         */
        public bool resizable { get; set; default = true; }
        
        public Gdk.RGBA? highlight_color { get; set; default = null; }
        
        /**
         * A widget to use for the node title instead of the name-label
         *
         * TODO: implement
         */
        public Gtk.Widget title_widget { get; set; }
        private Gtk.Label title_label;
        
        /**
         * {@inheritDoc}
         */
        public double click_offset_x { get; protected set; default = 0; }
        /**
         * {@inheritDoc}
         */
        public double click_offset_y { get; protected set; default = 0; }
        /**
         * {@inheritDoc}
         */
        public double resize_start_width { get; protected set; default = 0; }
        /**
         * {@inheritDoc}
         */
        public double resize_start_height { get; protected set; default = 0; }
        
        private int n_docks = 0;
        
        /**
         * Instantiate a new node
         *
         * You are required to pass a {@link GFlow.Node} to this constructor.
         */
        public Node(GFlow.Node n) {
            this.n = n;
            add_css_class("card");
            
            grid = new Gtk.Grid();
            grid.column_homogeneous = false;
            grid.column_spacing = 5;
            grid.row_homogeneous = false;
            grid.row_spacing = 5;
            grid.hexpand = true;
            grid.vexpand = true;
            grid.halign = Gtk.Align.FILL;
            grid.valign = Gtk.Align.FILL;
            
            grid.margin_top = Node.MARGIN;
            grid.margin_bottom = Node.MARGIN;
            grid.margin_start = Node.MARGIN;
            grid.margin_end = Node.MARGIN;
            grid.set_parent(this);
            
            set_layout_manager(new Gtk.BinLayout());
            
            ctr_click = new Gtk.GestureClick();
            add_controller(ctr_click);
            ctr_click.set_button(0);
            ctr_click.pressed.connect(press_button);
            ctr_click.end.connect(release_button);
            
            menu = new Gtk.Popover();
            menu.set_parent(this);
            menu.set_has_arrow(false);
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
            
            var delete_button = new Gtk.Button.with_label("Delete");
            delete_button.clicked.connect(cb_delete);
            delete_button.set_has_frame(false);
            box.append(delete_button);
            
            menu.set_child(box);
            
            title_label = new Gtk.Label("");
            title_label.set_markup("<b>%s</b>".printf(n.name));
            grid.attach(title_label, 0, 0, 2, 1);
            n.notify["name"].connect(() => {
                title_label.set_markup("<b>%s</b>".printf(n.name));
            });
            
            foreach (GFlow.Source s in n.get_sources()) {
                source_added(s);
            }
            foreach (GFlow.Sink s in n.get_sinks()) {
                sink_added(s);
            }
        }
        
        /**
         * Retrieve a Dock-Widget from this node.
         *
         * Gives you the GtkFlow.Dock-object that corresponds to the given
         * GFlow.Dock. Returns null if the searched Dock is not associated
         * with any of the Dock-Widgets in this node.
         */
        public Dock? retrieve_dock(GFlow.Dock d) {
            var c = grid.get_first_child();
            while (c != null) {
                if (!(c is Dock)) {
                    c = c.get_next_sibling();
                    continue;
                }
                var dw = (Dock) c;
                if (dw.d == d) return dw;
                c = c.get_next_sibling();
            }
            return null;
        }
        
        /**
         * {@inheritDoc}
         */
        public int get_margin() {
            return Node.MARGIN;
        }
        
        private void cb_delete() {
            var nv = get_parent() as NodeView;
            nv.remove(this);
        }
        
        /**
         * Adds a child widget to this node
         */
        public void add_child(Gtk.Widget child) {
            grid.attach(child, 0, 2 + n_docks, 3, 1);
        }
        
        /**
         * Removes a child widget from this node
         */
        public void remove_child(Gtk.Widget child) {
            child.unparent();
        }
        
        /**
         * {@inheritDoc}
         */
        public override void dispose() {
            grid.unparent();
            base.dispose();
        }
        
        private void sink_added(GFlow.Sink s) {
            var dock = new Dock(s);
            dock.notify["label"].connect(() => {
                var lc = (Gtk.GridLayoutChild) grid.get_layout_manager().get_layout_child(dock);
                grid.attach(dock.label, 1, lc.row, 1, 1);
            });
            grid.attach(dock, 0, 1 + ++n_docks, 1, 1);
            grid.attach(dock.label, 1, 1 + n_docks, 1, 1);
        }
        
        private void source_added(GFlow.Source s) {
            var dock = new Dock(s);
            dock.notify["label"].connect(() => {
                var lc = (Gtk.GridLayoutChild) grid.get_layout_manager().get_layout_child(dock);
                grid.attach(dock.label, 1, lc.row, 1, 1);
            });
            grid.attach(dock, 2, 1 + ++n_docks, 1, 1);
            grid.attach(dock.label, 1, 1 + n_docks, 1, 1);
        }
        
        private void press_button(int n_click, double x, double y) {
            if (ctr_click.get_current_button() == Gdk.BUTTON_PRIMARY) {
                var picked_widget = pick(x,y, Gtk.PickFlags.NON_TARGETABLE);
                
                bool do_processing = false;
                if (picked_widget == this || picked_widget == grid) {
                    do_processing = true;
                } else if (picked_widget.get_parent() == grid) {
                    if (picked_widget is Gtk.Label || picked_widget is Gtk.Image) {
                        do_processing = true;
                    }
                }
                if (!do_processing) return;
                
                Gdk.Rectangle resize_area = { get_width() - 8, get_height() - 8, 8, 8 };
                var nv = get_parent() as NodeView;
                if (resize_area.contains_point((int) x, (int) y)) {
                    nv.resize_node = this;
                    resize_start_width = get_width();
                    resize_start_height = get_height();
                } else {
                    nv.move_node = this;
                }
                click_offset_x = x;
                click_offset_y = y;
            } else if (ctr_click.get_current_button() == Gdk.BUTTON_SECONDARY) {
                menu.set_pointing_to({ (int) x, (int) y, 1, 1 });
                menu.popup();
            }
        }
        
        private void release_button() {
            if (ctr_click.get_current_button() != Gdk.BUTTON_PRIMARY) return;
            var nv = get_parent() as NodeView;
            nv.move_node = null;
            nv.resize_node = null;
            nv.queue_allocate();
        }
        
        /**
         * {@inheritDoc}
         */
        public new void set_parent(Gtk.Widget parent) {
            if (!(parent is NodeView)) {
                warning("Trying to add a GtkFlow.Node to something that is not a GtkFlow.NodeView!");
                return;
            }
            base.set_parent(parent);
        }
    }
}
