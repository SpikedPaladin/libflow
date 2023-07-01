namespace Flow {
    
    public abstract class Socket : Gtk.Widget {
        private Gtk.GestureClick click;
        
        public SocketRenderer renderer { get; set; }
        public Gtk.Widget label { get; private set; }
        /**
         * The name that will be rendered for this socket
         */
        public string? description { get; set; }
        /**
         * Color of this socket
         *
         * Be aware that only {@link Source}s dictate the colors of the
         * connections in default {@link ConnectionRenderer}. If this Socket holds a {@link Sink} it
         * will have no visible effect.
         */
        public Gdk.RGBA color { get; set; default = { 0, 0, 0, 1 }; }
        /**
         * Line width of this socket
         * Be aware that only {@link Source}s dictate the line width of the
         * connections in default {@link ConnectionRenderer}. If this Socket holds a {@link Sink} it
         * will have no visible effect.
         */
        public double line_width { get; set; default = 2; }
        /**
         * Determines whether this socket is highlighted
         * this is usually triggered when the mouse hovers over it
         */
        public bool highlight { get; set; }

        /**
         * Determines whether this socket is active
         */
        public bool active { get; set; }
        /**
         * A reference to the node this Socket resides in
         */
        public weak NodeRenderer? node { get; set; }

        /**
         * The type that has been set to this socket
         */
        public GLib.Type value_type { get; construct set; }
        
        static construct {
            set_css_name("socket");
        }
        
        construct {
            renderer = new SocketRenderer();
            
            linked.connect(queue_draw);
            unlinked.connect(queue_draw);
            
            label = new Gtk.Label(name);
            
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;
            
            click = new Gtk.GestureClick();
            add_controller(click);
            click.pressed.connect(press_button);
            changed.connect(cb_changed);
            
            notify["name"].connect(() => {
                if (label is Gtk.Label)
                    ((Gtk.Label) label).set_text(name);
            });
        }
        
        /**
         * This signal is being triggered, when there is a connection being established
         * from or to this Socket.
         */
        public signal void linked(Socket socket);
        
        /**
         * This signal is being triggered, before a connection is made
         * between two sockets. If the implementor returns false, the
         * connection is not being made.
         * IMPORTANT: Connect to this signal with connect_after
         * otherwise this default handler will be called after the
         * signal you implemented, thus always returning true,
         * rendering your code ineffective.
         */
        public virtual signal bool before_linking(Socket self, Socket other) {
            return true;
        }
        
        /**
         * This signal is being triggered, when there is a connection being removed
         * from or to this Socket. If this the last connection of the socket, the
         * boolean parameter last will be set to true.
         */
        public signal void unlinked(Socket socket, bool last);
        
        /**
         * Triggers when the value of this socket changes
         */
        public signal void changed(Value? value = null, string? flow_id = null);
        
        /**
         * Implementations should return true if this socket has at least one
         * connection to another socket
         */
        public abstract bool is_linked();
        
        /**
         * Implementations should return true if this socket is connected
         * to the supplied socket
         */
        public abstract bool is_linked_to(Socket socket);
        
        /**
         * Connect this {@link Socket} to other {@link Socket}
         */
        public abstract void link(Socket socket);
        /**
         * Disconnect this {@link Socket} from other {@link Socket}
         */
        public abstract void unlink(Socket socket);
        /**
         * Disconnect this {@link Socket} from all {@link Socket}s it is connected to
         */
        public abstract void unlink_all();
        
        /**
         * Tries to resolve this Socket's value-type to a displayable string
         */
        public virtual string determine_typestring() {
            return value_type.name();
        }
        
        /**
         * Returs true if this and the supplied socket have
         * same type
         */
        public virtual bool has_same_type(Socket other) {
            return value_type == other.value_type;
        }
        
        private NodeView? get_nodeview() {
            var parent = get_parent();
            
            while (true) {
                if (parent == null)
                    return null;
                
                else if (parent is NodeView)
                    return (NodeView) parent;
                
                else
                    parent = parent.get_parent();
            }
        }
        
        private void cb_changed(Value? value = null, string? flow_id = null) {
            var node_view = get_nodeview();
            
            if (node_view == null)
                return;
            
            node_view.queue_draw();
            queue_draw();
        }
        
        protected override void snapshot(Gtk.Snapshot snapshot) {
            base.snapshot(snapshot);
            
            renderer.snapshot_socket(snapshot, this);
        }
        
        private void press_button(int n_clicked, double x, double y) {
            var node_view = get_nodeview();
            
            if (node_view == null) {
                warning("Socket could not process button press: no nodeview");
                return;
            }
            
            node_view.start_temp_connector(this);
            node_view.queue_allocate();
        }
        
        protected override void measure(Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            min = 16;
            pref = 16;
            min_base = -1;
            pref_base = -1;
        }
    }
}
