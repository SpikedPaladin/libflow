namespace Flow {

    public partial class NodeView {

        protected override void snapshot(Gtk.Snapshot snapshot) {
            foreach_childs((child) => {
                if (child is Rubberband)
                    return;

                snapshot_child(child, snapshot);
            });

            foreach (var connection in connections) {
                Graphene.Point start, end;

                connection.source.compute_point(this, { 8, 8 }, out start);
                connection.sink.compute_point(this, { 8, 8, }, out end);

                end.x = end.x - start.x;
                end.y = end.y - start.y;

                var stroke = new Gsk.Stroke(connection.line_width * zoom_factor);
                var path = build_curve(start, end);

                Graphene.Rect bounds;
                path.get_stroke_bounds(stroke, out bounds);

                snapshot.push_stroke(path, stroke);
                snapshot.append_linear_gradient(bounds, { start.x, start.y }, { end.x + start.x, end.y + start.y}, {{0, connection.source.color}, {1, connection.sink.color}});
                snapshot.pop();
            }

            if (state is State.Connecting) {
                var state = (State.Connecting) state;
                var stroke = new Gsk.Stroke(2 * zoom_factor);

                stroke.set_dash({10 * zoom_factor, 5 * zoom_factor});
                stroke.set_dash_offset(0);

                Graphene.Point point;
                state.socket.compute_point(this, { 8, 8 }, out point);

                snapshot.append_stroke(
                    build_curve(point, state.end),
                    stroke,
                    state.socket.color
                    );
            }

            if (state is State.Selecting) {
                var state = (State.Selecting) state;
                snapshot_child(state.rubberband, snapshot);
            }
        }

        private Gsk.Path build_curve(Graphene.Point start, Graphene.Point end) {
            var builder = new Gsk.PathBuilder();

            builder.move_to(start.x, start.y);
            if (end.x > 0)
                builder.rel_cubic_to(end.x / 3, 0, 2 * end.x / 3, end.y, end.x, end.y);
            else
                builder.rel_cubic_to(-end.x / 3, 0, 1.3F * end.x, end.y, end.x, end.y);

            return builder.to_path();
        }
    }
}
