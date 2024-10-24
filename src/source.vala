namespace Flow {
    
    public class Source : Socket {
        private Value? last_value;
        
        construct {
            add_css_class("source");
        }
        
        public Source(string type) {
            value_type = type;
        }
        
        public Source.with_type(Type type) {
            value_type = type.name();
        }
        
        public Source.with_value(Value val) {
            value_type = val.get_gtype().name();
        }
        
        public override void add_connection(Connection connection) {
            base.add_connection(connection);
            
            connection.sink.changed(last_value);
        }
        
        public void set_value(Value? @value) {
            if (@value != null && @value.type().name() == value_type) {
                last_value = @value;
                
                // Broadcast new value to all connected sinks
                foreach (var connection in connections)
                    connection.sink.changed(@value);
            }
        }
    }
}