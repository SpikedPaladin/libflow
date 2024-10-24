namespace Flow {
    
    public partial class NodeView {
        [GtkChild]
        private unowned Gtk.EventControllerScroll gesture_scroll;
        [GtkChild]
        private unowned Gtk.GestureZoom gesture_zoom;
        
        private double initial_zoom = 1;
        private Graphene.Point last_drag_point = { 0, 0 };
        
        [GtkCallback]
        private bool on_scroll(double dx, double dy) {
            var event = gesture_scroll.get_current_event();
            
            // Ctrl + Mouse wheel
            if (event.get_modifier_state() == Gdk.ModifierType.CONTROL_MASK) {
                zoom_factor = (float) (zoom_factor + (0.1 * -dy));
                return true;
            }
            
            return false;
        }
        
        [GtkCallback]
        private void on_pan_begin() {
            set_cursor(new Gdk.Cursor.from_name("grabbing", null));
            last_drag_point = { 0, 0 };
        }
        
        [GtkCallback]
        private void on_pan_update(double x, double y) {
            var old_x = last_drag_point.x;
            var old_y = last_drag_point.y;
            
            last_drag_point = { (float) x, (float) y };
            
            var delta_x = old_x - x;
            var delta_y = old_y - y;
            
            hadjustment.value = hadjustment.value + delta_x;
            vadjustment.value = vadjustment.value + delta_y;
        }
        
        [GtkCallback]
        private void on_pan_end() {
            set_cursor(null);
        }
        
        [GtkCallback]
        private void on_zoom_begin() {
            initial_zoom = zoom_factor;
        }
        
        [GtkCallback]
        private void on_zoom_changed(double delta) {
            double x, y;
            
            gesture_zoom.get_bounding_box_center(out x, out y);
            
            var old_zoom = zoom_factor;
            
            var x_total = (x + hadjustment.value) / old_zoom;
            var y_total = (y + vadjustment.value) / old_zoom;
            
            var new_hadjustment = x_total * zoom_factor - x;
            var new_vadjustment = y_total * zoom_factor - y;
            
            hadjustment.value = new_hadjustment;
            vadjustment.value = new_vadjustment;
            
            zoom_factor = (float) (initial_zoom * delta);
        }
    }
}