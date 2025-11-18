namespace Flow {

    public partial class NodeView : Gtk.Scrollable {
        private float _zoom_factor = 1;
        public float zoom_factor {
            get {
                return _zoom_factor;
            }
            set {
                var new_zoom = value.clamp(0.3F, 4);

                if (new_zoom != _zoom_factor) {
                    _zoom_factor = new_zoom;
                    queue_allocate();
                }
            }
        }

        private Gtk.Adjustment _hadjustment;
        private Gtk.Adjustment _vadjustment;
        public Gtk.Adjustment hadjustment {
            get {
                return _hadjustment;
            }
            set construct {
                _hadjustment = value;
                if (_hadjustment != null)
                    _hadjustment.value_changed.connect(() => queue_allocate());
            }
        }
        public Gtk.Adjustment vadjustment {
            get { return _vadjustment; }
            set construct {
                _vadjustment = value;
                if (_vadjustment != null)
                    _vadjustment.value_changed.connect(() => queue_allocate());
            }
        }

        public Gtk.ScrollablePolicy hscroll_policy { get; set; }
        public Gtk.ScrollablePolicy vscroll_policy { get; set; }
        public int canvas_width { get; set; default = 5000; }
        public int canvas_height { get; set; default = 5000; }

        public bool get_border(out Gtk.Border border) {
            border = {};
            return false;
        }

        public Gsk.Transform screen_transform() {
            return new Gsk.Transform()
                .translate({ (float) (-hadjustment.value), (float) (-vadjustment.value) })
                .scale(zoom_factor, zoom_factor);
        }

        public Gsk.Transform canvas_transform() {
            return screen_transform().invert();
        }

        public override void size_allocate(int width, int height, int baseline) {
            var x = hadjustment.value;
            var y = vadjustment.value;

            foreach_childs((child) => {
                Gtk.Requisition _, natural_size;
                child.get_preferred_size(out _, out natural_size);
                child.allocate(
                    natural_size.width,
                    natural_size.height,
                    baseline,
                    screen_transform()
                    .translate({ child.x, child.y })
                    );
            });

            hadjustment.configure(
                x,
                0,
                double.max(width, canvas_height * zoom_factor),
                0.1 * width,
                0.9 * width,
                width
                );
            vadjustment.configure(
                y,
                0,
                double.max(height, canvas_width * zoom_factor),
                0.1 * height,
                0.9 * height,
                height
                );
        }
    }
}
