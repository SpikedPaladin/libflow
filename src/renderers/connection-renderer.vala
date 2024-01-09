namespace Flow {
    
    public class ConnectionRenderer : Object {
        
        public virtual void snapshot_temp_connector(Gtk.Snapshot snapshot, Socket socket, Gdk.Rectangle rect) {
            var snapshot_rect = Graphene.Rect()
                .init(rect.x, rect.y, rect.width, rect.height)
                .inset((float) (socket.line_width * -2), (float) (socket.line_width * -2));
            
            if (rect.width < 0)
                snapshot_rect.inset(rect.width * 0.05F, 0);
            
            var cairo = snapshot.append_cairo(snapshot_rect);
            
            render_temp_connection(
                cairo,
                
                socket,
                rect
            );
        }
        
        public virtual void render_temp_connection(Cairo.Context cairo, Socket socket, Gdk.Rectangle rect) {
            cairo.set_source_rgba(socket.color.red, socket.color.green, socket.color.blue, socket.color.alpha);
            cairo.set_line_width(socket.line_width);
            
            render_curve(cairo, rect);
        }
        
        public virtual void snapshot_connection(Gtk.Snapshot snapshot, Socket start, Socket end, Gdk.Rectangle rect) {
            var snapshot_rect = Graphene.Rect()
                .init(rect.x, rect.y, rect.width, rect.height)
                .inset((float) (start.line_width * -2), (float) (start.line_width * -2));
            
            if (rect.width < 0)
                snapshot_rect.inset(rect.width * 0.05F, 0);
            
            var cairo = snapshot.append_cairo(snapshot_rect);
            
            render_connection(
                cairo,
                
                start, end,
                {
                    (int) rect.x, (int) rect.y,
                    (int) rect.width, (int) rect.height
                }
            );
        }
        
        public virtual void render_connection(Cairo.Context cairo, Socket start, Socket end, Gdk.Rectangle rect) {
            var pattern = new Cairo.Pattern.linear(
                rect.x, rect.y,
                rect.width + rect.x,
                rect.height + rect.y
            );
            
            pattern.add_color_stop_rgba(
                0,
                start.color.red, start.color.green, start.color.blue, start.color.alpha
            );
            
            pattern.add_color_stop_rgba(
                1,
                end.color.red, end.color.green, end.color.blue, end.color.alpha
            );
            
            cairo.set_line_width(start.line_width);
            cairo.set_source(pattern);
            
            render_curve(cairo, rect);
        }
        
        public virtual void render_curve(Cairo.Context cairo, Gdk.Rectangle rect) {
            cairo.move_to(rect.x, rect.y);
            
            if (rect.width > 0)
                cairo.rel_curve_to(rect.width / 3, 0, 2 * rect.width / 3, rect.height, rect.width, rect.height);
            else
                cairo.rel_curve_to(-rect.width / 3, 0, 1.3 * rect.width, rect.height, rect.width, rect.height);
            
            cairo.stroke();
        }
    }
}
