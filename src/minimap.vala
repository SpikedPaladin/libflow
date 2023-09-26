namespace Flow {
    
    /**
     * A Widget that draws a minmap of a {@link Flow.NodeView}
     *
     * Please set the nodeview property after integrating the referenced
     * {@link Flow.NodeView} into its respective container
     */
    public class Minimap : Gtk.DrawingArea {
        private NodeView? _nodeview = null;
        private Gtk.ScrolledWindow? _scrolledwindow = null;
        private Gtk.EventControllerMotion ctr_motion;
        private Gtk.GestureClick ctr_click;
        
        private ulong draw_signal = 0;
        private ulong hadjustment_signal = 0;
        private ulong vadjustment_signal = 0;
        
        private int offset_x = 0;
        private int offset_y = 0;
        private double ratio = 0.0;
        private int rubber_width = 0;
        private int rubber_height = 0;
        private bool move_rubber = false;
        /**
         * The nodeview that this Minimap should depict
         *
         * You may either add a {@link Flow.NodeView} directly or a
         * {@link Gtk.ScrolledWindow} that contains a {@link Flow.NodeView}
         * as its child.
         */
        public NodeView nodeview {
            get {
                return _nodeview;
            }
            set {
                if (_nodeview != null)
                    SignalHandler.disconnect(_nodeview, draw_signal);
                
                if (_scrolledwindow != null) {
                    SignalHandler.disconnect(_nodeview, hadjustment_signal);
                    SignalHandler.disconnect(_nodeview, vadjustment_signal);
                }
                if (value == null) {
                    _nodeview = null;
                    _scrolledwindow = null;
                } else {
                    _nodeview = value;
                    _scrolledwindow = null;
                    if (value.get_parent() is Gtk.ScrolledWindow) {
                        _scrolledwindow = value.get_parent() as Gtk.ScrolledWindow;
                    } else {
                        if (value.get_parent() is Gtk.Viewport) {
                            if (value.get_parent().get_parent() is Gtk.ScrolledWindow) {
                                _scrolledwindow = value.get_parent().get_parent() as Gtk.ScrolledWindow;
                                hadjustment_signal = _scrolledwindow.hadjustment.notify["value"].connect(queue_draw);
                                vadjustment_signal = _scrolledwindow.vadjustment.notify["value"].connect(queue_draw);
                            }
                        }
                    }
                    draw_signal = _nodeview.draw_minimap.connect(queue_draw);
                }
                queue_draw();
            }
        }
        
        static construct {
            set_css_name("minimap");
        }
        
        /**
         * Create a new Minimap
         */
        public Minimap() {
            set_size_request(50, 50);
            
            ctr_motion = new Gtk.EventControllerMotion();
            add_controller(ctr_motion);
            ctr_click = new Gtk.GestureClick();
            add_controller(ctr_click);
            
            ctr_click.pressed.connect((n, x, y) => do_button_press_event(x, y));
            ctr_click.end.connect(do_button_release_event);
            ctr_motion.motion.connect(do_motion_notify_event);
        }
        
        private void do_button_press_event(double x, double y) {
            move_rubber = true;
            double halloc = double.max(0, x - offset_x - rubber_width / 2) * ratio;
            double valloc = double.max(0, y - offset_y - rubber_height / 2) * ratio;
            _scrolledwindow.hadjustment.value = halloc;
            _scrolledwindow.vadjustment.value = valloc;
        }
        
        private void do_motion_notify_event(double x, double y) {
            if (!move_rubber || _scrolledwindow == null) {
                return;
            }
            double halloc = double.max(0, x - offset_x - rubber_width / 2) * ratio;
            double valloc = double.max(0, y - offset_y - rubber_height / 2) * ratio;
            _scrolledwindow.hadjustment.value = halloc;
            _scrolledwindow.vadjustment.value = valloc;
        }
        
        private void do_button_release_event() {
            move_rubber = false;
        }
        
        /**
         * Draws the minimap. This method is called internally
         */
        public override void snapshot(Gtk.Snapshot snapshot) {
            Graphene.Rect rect;
            
            if (_nodeview != null) {
                offset_x = 0;
                offset_y = 0;
                int height = 0;
                int width = 0;
                if (get_width() > get_height()) {
                    width = (int) ((double) _nodeview.get_width() / _nodeview.get_height() * get_height());
                    height = get_height();
                    offset_x = (get_width() - width) / 2;
                } else {
                    height = (int) ((double) _nodeview.get_height() / _nodeview.get_width() * get_width());
                    width = get_width();
                    offset_y = (get_height() - height) / 2;
                }
                ratio = (double) _nodeview.get_width() / width;
                
                for (var child = _nodeview.get_first_child(); child != null; child = child.get_next_sibling()) {
                    if (!(child is NodeRenderer))
                        continue;
                    
                    var node = (Node) child;
                    
                    Gdk.RGBA color;
                    Graphene.Rect bounds;
                    node.compute_bounds(_nodeview, out bounds);
                    
                    if (node.highlight_color != null) {
                        color = node.highlight_color;
                    } else {
                        color = { 0.4f, 0.4f, 0.4f, 0.5f };
                    }
                    
                    rect = Graphene.Rect().init(
                        (int) (offset_x + bounds.origin.x / ratio),
                        (int) (offset_y + bounds.origin.y / ratio),
                        (int) (bounds.size.width / ratio),
                        (int) (bounds.size.height / ratio)
                    );
                    
                    snapshot.append_color(color, rect);
                }
                if (_scrolledwindow != null) {
                    if (_scrolledwindow.get_width() < _nodeview.get_width() || _scrolledwindow.get_height() < _nodeview.get_height()) {
                        rect = Graphene.Rect().init(
                            (int) (offset_x + _scrolledwindow.hadjustment.value / ratio),
                            (int) (offset_y + _scrolledwindow.vadjustment.value / ratio),
                            (int) (_scrolledwindow.get_width() / ratio),
                            (int) (_scrolledwindow.get_height() / ratio)
                        );
                        
                        snapshot.append_color({ 0.0f, 0.2f, 0.6f, 0.5f }, rect);
                    }
                }
            }
        }
    }
}

