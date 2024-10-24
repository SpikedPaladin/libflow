namespace Flow {
    
    public class Sink : Socket {
        
        construct {
            add_css_class("sink");
        }
        
        public Sink(string type) {
            value_type = type;
        }
        
        public Sink.with_type(Type type) {
            value_type = type.name();
        }
        
        public Sink.with_value(Value val) {
            value_type = val.get_gtype().name();
        }
    }
}