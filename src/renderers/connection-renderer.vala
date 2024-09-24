namespace Flow {
    
    public class ConnectionRenderer : Object {
        
        public virtual void snapshot_temp_connector(Gtk.Snapshot snapshot, Socket socket, Gdk.Rectangle rect) {
            snapshot.append_stroke(
                build_curve(rect),
                new Gsk.Stroke(socket.line_width),
                socket.color
            );
        }
        
        public virtual void snapshot_connection(Gtk.Snapshot snapshot, Socket start, Socket end, Gdk.Rectangle rect) {
            var path = build_curve(rect);
            var stroke = new Gsk.Stroke(start.line_width);
            Graphene.Rect bounds;
            path.get_stroke_bounds(stroke, out bounds);
            
            snapshot.push_stroke(path, stroke);
            snapshot.append_linear_gradient(bounds, { rect.x, rect.y }, {rect.width + rect.x, rect.height + rect.y}, {{0, start.color}, {1, end.color}});
            snapshot.pop();
        }
        
        public virtual Gsk.Path build_curve(Gdk.Rectangle rect) {
            var builder = new Gsk.PathBuilder();
            
            builder.move_to(rect.x, rect.y);
            if (rect.width > 0)
                builder.rel_cubic_to(rect.width / 3, 0, 2 * rect.width / 3, rect.height, rect.width, rect.height);
            else
                builder.rel_cubic_to(-rect.width / 3, 0, 1.3F * rect.width, rect.height, rect.width, rect.height);
            
            return builder.to_path();
        }
    }
}
