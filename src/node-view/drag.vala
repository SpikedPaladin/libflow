namespace Flow {
    
    public partial class NodeView {
        [GtkChild]
        private unowned Gtk.GestureDrag gesture_drag;
        
        [GtkCallback]
        private void on_drag_begin(double x, double y) {
            var widget = pick(x, y, Gtk.PickFlags.DEFAULT);
            
            var canvas_mouse = get_canvas_point({ (float) x, (float) y });
            
            // Selecting
            if (widget is NodeView) {
                state = new State.Selecting(this, canvas_mouse.x, canvas_mouse.y);
                return;
            }
            
            // Connecting sockets
            if (widget is Socket) {
                state = new State.Connecting(widget);
                return;
            }
            
            if (!(widget is NodeView)) {
                NodeViewChild? target = null;
                for (var parent = widget.parent; !(parent is NodeView); parent = parent.parent) {
                    if (parent is NodeViewChild) {
                        target = (NodeViewChild) parent;
                        break;
                    }
                }
                
                if (target == null)
                    return;
                
                state = new State.Dragging() {
                    target = target,
                    offset = {
                        canvas_mouse.x - target.x,
                        canvas_mouse.y - target.y
                    }
                };
            }
        }
        
        [GtkCallback]
        private void on_drag_update(double offset_x, double offset_y) {
            var mouse = get_mouse(offset_x, offset_y);
            var canvas_mouse = get_canvas_point(mouse);
            
            if (state is State.Selecting) {
                var state = (State.Selecting) state;
                var initial_canvas_mouse = get_canvas_point(get_start_mouse());
                state.process_motion(canvas_mouse.x - initial_canvas_mouse.x, canvas_mouse.y - initial_canvas_mouse.y);
                
                return;
            }
            
            // Snapshot happens on screen space
            if (state is State.Connecting) {
                var state = (State.Connecting) state;
                Graphene.Point point;
                state.socket.compute_point(this, { 8, 8 }, out point);
                state.end = { mouse.x - point.x, mouse.y - point.y };
                
                queue_draw();
                return;
            }
            
            if (state is State.Dragging) {
                var state = (State.Dragging) state;
                
                state.target.x = (canvas_mouse.x - state.offset.x).clamp(0, canvas_width - state.target.get_width());
                state.target.y = (canvas_mouse.y - state.offset.y).clamp(0, canvas_height - state.target.get_height());
                queue_allocate();
            }
        }
        
        [GtkCallback]
        private void on_drag_end(double offset_x, double offset_y) {
            if (state is State.Connecting) {
                var state = (State.Connecting) state;
                var mouse = get_mouse(offset_x, offset_y);
                var socket = pick(mouse.x, mouse.y, Gtk.PickFlags.DEFAULT) as Socket;
                
                if (socket != null) {
                    connect_sockets(socket, state.socket);
                }
                
                queue_draw();
            }
            
            state = new State.Idle();
        }
        
        private Graphene.Point get_mouse(double offset_x, double offset_y) {
            double start_x, start_y;
            gesture_drag.get_start_point(out start_x, out start_y);
            
            return { (float) (start_x + offset_x), (float) (start_y + offset_y) };
        }
        
        private Graphene.Point get_start_mouse() {
            double start_x, start_y;
            gesture_drag.get_start_point(out start_x, out start_y);
            
            return { (float) start_x, (float) start_y };
        }
        
        private Graphene.Point get_canvas_point(Graphene.Point screen_point) {
            if (zoom_factor == 1)
                return screen_point;
            
            return canvas_transform().transform_point(screen_point);
        }
    }
}