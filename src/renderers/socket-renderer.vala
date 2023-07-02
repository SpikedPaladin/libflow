namespace Flow {
    
    public class SocketRenderer : Object {
        
        public virtual void snapshot_socket(Gtk.Snapshot snapshot, Socket socket) {
            
            var cairo = snapshot.append_cairo(Graphene.Rect().init(0, 0, 16, 16));
            
            cairo.save();
            
            render_background(cairo, socket);
            
            cairo.restore();
            
            if (socket.is_linked()) {
                cairo.save();
                
                render_linked(cairo, socket, socket.color);
                
                cairo.restore();
            }
        }
        
        public virtual void render_background(Cairo.Context cairo, Socket socket) {
            cairo.set_source_rgba(0.5f, 0.5f, 0.5f, 0.5f);
            cairo.arc(8, 8, 8, 0, 2 * Math.PI);
            cairo.fill();
        }
        
        public virtual void render_linked(Cairo.Context cairo, Socket socket, Gdk.RGBA color) {
            cairo.set_source_rgba(
                color.red,
                color.green,
                color.blue,
                color.alpha
            );
            cairo.arc(8, 8, 4, 0.0, 2 * Math.PI);
            cairo.fill();
        }
    }
}
