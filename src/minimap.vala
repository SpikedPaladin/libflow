namespace Flow {

    public class Minimap : Gtk.Widget {
        private NodeView? _node_view = null;
        private Gtk.ScrolledWindow? _scrolledwindow = null;

        private ulong draw_signal = 0;
        private ulong hadjustment_signal = 0;
        private ulong vadjustment_signal = 0;
        private double ratio = 0.0;
        private int rubber_width = 0;
        private int rubber_height = 0;
        private bool move_rubber = false;

        public NodeView node_view {
            get { return _node_view; }
            set {
                if (_node_view != null)
                    SignalHandler.disconnect(_node_view, draw_signal);

                if (_scrolledwindow != null) {
                    SignalHandler.disconnect(_node_view, hadjustment_signal);
                    SignalHandler.disconnect(_node_view, vadjustment_signal);
                }
                if (value == null) {
                    _node_view = null;
                    _scrolledwindow = null;
                } else {
                    _node_view = value;
                    _scrolledwindow = null;
                    if (value.parent is Gtk.ScrolledWindow) {
                        _scrolledwindow = value.parent as Gtk.ScrolledWindow;
                    } else {
                        if (value.parent is Gtk.Viewport) {
                            if (value.parent.parent is Gtk.ScrolledWindow) {
                                _scrolledwindow = value.parent.parent as Gtk.ScrolledWindow;
                                hadjustment_signal = _scrolledwindow.hadjustment.notify["value"].connect(queue_draw);
                                vadjustment_signal = _scrolledwindow.vadjustment.notify["value"].connect(queue_draw);
                            }
                        }
                    }
                    draw_signal = _node_view.draw_minimap.connect(queue_draw);
                }
                queue_draw();
            }
        }

        static construct {
            set_css_name("minimap");
        }

        construct {
            width_request = height_request = 50;
        }

        public override void snapshot(Gtk.Snapshot snapshot) {
            Graphene.Rect rect;
            if (_node_view != null) {
                int height = 0;
                int width = 0;
                if (get_width() > get_height()) {
                    width = (int) ((double) _node_view.actual_width / _node_view.actual_width * get_height());
                    height = get_height();
                } else {
                    height = (int) ((double) _node_view.actual_height / _node_view.actual_width * get_width());
                    width = get_width();
                }
                ratio = (double) _node_view.actual_width / width;

                for (var child = _node_view.get_first_child(); child != null; child = child.get_next_sibling()) {
                    if (!(child is Node))
                        continue;

                    var node = (Node) child;

                    Gdk.RGBA color;
                    Graphene.Rect bounds;
                    node.compute_bounds(_node_view, out bounds);

                    color = { 0.4f, 0.4f, 0.4f, 0.5f };

                    rect = Graphene.Rect().init(
                        (int) (bounds.origin.x / ratio),
                        (int) (bounds.origin.y / ratio),
                        (int) (bounds.size.width / ratio),
                        (int) (bounds.size.height / ratio)
                    );

                    snapshot.append_color(color, rect);
                }

                if (_scrolledwindow != null) {
                    if (_scrolledwindow.get_width() < _node_view.canvas_width || _scrolledwindow.get_height() < _node_view.canvas_height) {
                        rect = Graphene.Rect().init(
                            (int) (_scrolledwindow.hadjustment.value / ratio),
                            (int) (_scrolledwindow.vadjustment.value / ratio),
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
