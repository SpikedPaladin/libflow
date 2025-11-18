namespace Flow {

    public abstract class Socket : Gtk.Widget {
        private List<weak Connection> _connections = new List<weak Connection>();

        public List<weak Connection> connections { get { return _connections; } }
        public Gdk.RGBA color { get; set; default = { 0, 0, 0, 1 }; }
        public float line_width { get; set; default = 2; }
        public string value_type { get; construct set; }
        public Node? node { get; set; }

        static construct {
            set_css_name("socket");
        }

        construct {
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;
        }

        public virtual void add_connection(Connection connection) {
            _connections.append(connection);
            queue_draw();
        }

        public virtual void remove_connection(Connection connection) {
            _connections.remove(connection);

            if (_connections.length() < 1)
                queue_draw();
        }

        public signal void changed(Value? @value);

        protected override void measure(Gtk.Orientation o, int for_size, out int min, out int pref, out int min_base, out int pref_base) {
            min = 16;
            pref = 16;
            min_base = -1;
            pref_base = -1;
        }

        public override void snapshot(Gtk.Snapshot snapshot) {
            base.snapshot(snapshot);
            snapshot_socket(snapshot);
        }

        public virtual void snapshot_socket(Gtk.Snapshot snapshot) {
            var cairo = snapshot.append_cairo(Graphene.Rect().init(0, 0, 16, 16));

            cairo.save();

            cairo.set_source_rgba(0.5f, 0.5f, 0.5f, 0.5f);
            cairo.arc(8, 8, 8, 0, 2 * Math.PI);
            cairo.fill();

            cairo.restore();

            if (_connections.length() > 0) {
                cairo.save();

                cairo.set_source_rgba(
                    color.red,
                    color.green,
                    color.blue,
                    color.alpha
                    );
                cairo.arc(8, 8, 4, 0.0, 2 * Math.PI);
                cairo.fill();

                cairo.restore();
            }
        }
    }
}
