namespace Flow {

    public partial class NodeView {

        public sealed interface State : Object {
            public class Idle : Object, State {}
            public class Selecting : Object, State {
                public Rubberband rubberband;

                public Selecting(Gtk.Widget parent, double x, double y) {
                    rubberband = new Rubberband(parent, x, y);
                }

                ~Selecting() {
                    rubberband.unparent();
                }

                public void process_motion(double x, double y) {
                    Graphene.Rect selection = {
                        { rubberband.start_x, rubberband.start_y },
                        { (float) x, (float) y }
                    };

                    if (selection.size.width < 0) {
                        selection.size.width *= -1;
                        selection.origin.x -= selection.size.width;
                    }

                    if (selection.size.height < 0) {
                        selection.size.height *= -1;
                        selection.origin.y -= selection.size.height;
                    }

                    rubberband.x = selection.origin.x;
                    rubberband.y = selection.origin.y;
                    rubberband.set_size_request((int) selection.size.width, (int) selection.size.height);
                }
            }

            public class Connecting : Object, State {
                public unowned Socket socket;
                public Graphene.Point end = {};

                public Connecting(Gtk.Widget widget) {
                    this.socket = (Socket) widget;
                }
            }

            public class Dragging : Object, State {
                public Graphene.Point offset;
                public NodeViewChild target;
            }
        }

        public State state { get; set; default = new State.Idle(); }
    }
}
