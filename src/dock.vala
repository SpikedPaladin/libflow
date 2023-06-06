namespace GtkFlow {
    /**
     * A widget that displays a {@link GFlow.Dock}
     *
     * Users may draw connections from and to this widget.
     * These widgets are only to be used inside implementations
     * of {@link GtkFlow.Node}
     */
    public class Dock : Gtk.Widget {
        construct {
            set_css_name("gtkflow_dock");
        }
        
        public GFlow.Dock d { get; protected set; }
        public Gtk.Widget label { get; private set; }
        private Gtk.GestureClick ctr_click;
        
        internal Value? last_value = null;
        
        /**
         * Creates a new Dock
         *
         * Requires the programmer to pass a {@link GFlow.Dock} to
         * the d-parameter.
         */
        public Dock(GFlow.Dock d) {
            this.d = d;
            d.unlinked.connect(() => { queue_draw(); });
            d.linked.connect(() => { queue_draw(); });
            var l = new Gtk.Label(d.name);
            l.justify = Gtk.Justification.LEFT;
            label = l;
            label.hexpand = true;
            label.halign = Gtk.Align.FILL;
            
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;
            margin_start = 8;
            margin_end = 8;
            margin_top = 4;
            margin_bottom = 4;
            
            ctr_click = new Gtk.GestureClick();
            add_controller(ctr_click);
            ctr_click.pressed.connect((n, x, y) => { press_button(n, x, y); });
            d.changed.connect(cb_changed);
        }
        
        /**
         * Change the widget that is used as this dock's label
         *
         * The given widget will be rendered instead of the usual label containing
         * the dock's name. You can use this e.g. to express weights applied to the
         * inputs or to provide default values if no connection is present.
         */
        public void set_docklabel(Gtk.Widget w) {
            label.unparent();
            label = w;
            label.hexpand = true;
            label.halign = Gtk.Align.FILL;
        }
        
        private GtkFlow.NodeView? get_nodeview() {
            var parent = get_parent();
            while (true) {
                if (parent == null) {
                    return null;
                } else if (parent is NodeView) {
                    return (NodeView) parent;
                } else {
                    parent = parent.get_parent();
                }
            }
        }
        
        private void cb_changed(Value? value = null, string? flow_id = null) {
            var nv = get_nodeview();
            if (nv == null) {
                warning("Could not react to dock change: no nodeview");
                return;
            }
            if (value != null) {
                last_value = value;
            } else {
                last_value = null;
            }
            nv.queue_draw();
            queue_draw();
        }
        
        /**
         * Request for the color of this dock
         *
         * Use {@link GLib.Signal.connect_after} to override this
         * method and let your application decide what color to use
         * for connections that are going off this node.
         * Be aware that only {@link GFlow.Source}s dictate the colors of the
         * connections. If this Dock holds a {@link GFlow.Sink} it
         * will have no visible effect.
         */
        public signal Gdk.RGBA resolve_color(Dock d, Value? v) {
            return { 0, 0, 0, 1 };
        }
        
        protected override void snapshot(Gtk.Snapshot sn) {
            var nv = get_nodeview();
            if (nv == null) {
                warning("Dock could not snapshot: no nodeview");
                return;
            }
            var rect = Graphene.Rect().init(0, 0, 16, 16);
            var rrect = Gsk.RoundedRect().init_from_rect(rect, 8f);
            Gdk.RGBA color = { 0.5f, 0.5f, 0.5f, 1.0f };
            Gdk.RGBA[] border_color = { color, color, color, color };
            float[] thicc = {1f,1f,1f,1f};
            sn.append_border(rrect, thicc, border_color);
            base.snapshot(sn);
            var cr = sn.append_cairo(rect);
            cr.save();
            cr.set_source_rgba(0.0,0.0,0.0,0.0);
            cr.set_operator(Cairo.Operator.SOURCE);
            cr.paint();
            cr.restore();
            if (d.is_linked()) {
                Gdk.RGBA dot_color = { 0.0f, 0.0f, 0.0f, 1.0f };
                if (d is GFlow.Source) {
                    dot_color = resolve_color(this, last_value);
                } else if (d is GFlow.Sink && d.is_linked()) {
                    var sink = (GFlow.Sink) d;
                    var sourcedock = nv.retrieve_dock(sink.sources.nth_data(0));
                    if (sourcedock != null) {
                        dot_color = sourcedock.resolve_color(this, last_value);
                    }
                }
                thicc = { 8f, 8f, 8f, 8f };
                cr.save();
                cr.set_source_rgba(
                    dot_color.red,
                    dot_color.green,
                    dot_color.blue,
                    dot_color.alpha
                );
                cr.arc(8d, 8d, 4d, 0.0, 2 * Math.PI);
                cr.fill();
                cr.restore();
            }
        }
        
        private void press_button(int n_clicked, double x, double y) {
            var nv = get_nodeview();
            if (nv == null) {
                warning("Dock could not process button press: no nodeview");
                return;
            }
            nv.start_temp_connector(this);
            nv.queue_allocate();
        }
        
        protected override void measure(Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            min = 16;
            pref = 16;
            min_base = -1;
            pref_base = -1;
        }
    }
}

