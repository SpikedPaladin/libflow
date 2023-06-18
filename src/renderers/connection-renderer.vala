namespace Flow {
    
    public class ConnectionRenderer : Object {
        
        public virtual void render_connection(Cairo.Context cairo, Socket start, Socket? end, Gdk.Rectangle rect) {
            cairo.set_source_rgba(start.color.red, start.color.green, start.color.blue, start.color.alpha);
            cairo.move_to(rect.x, rect.y);
            
            if (rect.width > 0)
                cairo.rel_curve_to(rect.width / 3, 0, 2 * rect.width / 3, rect.height, rect.width, rect.height);
            else
                cairo.rel_curve_to(-rect.width / 3, 0, 1.3 * rect.width, rect.height, rect.width, rect.height);
        }
        
        public virtual void render_temp_connection(Cairo.Context cairo, Socket socket, Gdk.Rectangle rect) {
            render_connection(cairo, socket, null, rect);
        }
    }
}
