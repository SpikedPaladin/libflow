namespace Flow {
    
    public class Source : Socket {
        private List<Sink> _sinks = new List<Sink>();
        private Value? last_value;
        /**
         * The {@link Sink}s that this Source is connected to
         */
        public List<Sink> sinks { get { return _sinks; } }
        
        construct {
            add_css_class("source");
        }
        
        /**
         * Creates a new Source. Supply an arbitrary {@link GLib.Value}.
         * This initial value's type will determine this Source's type.
         */
        public Source(Value @value) {
            value_type = @value.get_gtype();
        }
        
        public Source.with_type(Type type) {
            value_type = type;
        }
        
        protected void add_sink(Sink sink) {
            if (value_type == sink.value_type) {
                _sinks.append(sink);
                
                changed();
            }
        }
        
        protected void remove_sink(Sink sink) {
            if (_sinks.index(sink) != -1)
                _sinks.remove(sink);
            
            if (sink.is_linked_to(this)) {
                sink.unlink(this);
                
                unlinked(sink, _sinks.length() == 0);
            }
        }
        
        /**
         * Returns true if this Source is connected to one or more Sinks
         */
        public override bool is_linked() {
            return _sinks.length() > 0;
        }
        
        /**
         * Returns true if this Source is connected to the given Sink
         */
        public override bool is_linked_to(Socket socket) {
            if (!(socket is Sink))
                return false;
            
            return _sinks.index((Sink) socket) != -1;
        }
        
        /**
         * Connect to the given {@link Socket}
         */
        public override void link(Socket socket) {
            if (!before_linking(this, socket))
                return;
            
            if (socket is Sink) {
                if (is_linked_to(socket))
                    return;
                
                add_sink((Sink) socket);
                socket.link(this);
                changed(last_value);
                
                linked(socket);
            }
        }
        
        /**
         * Disconnect from the given {@link Socket}
         */
        public override void unlink(Socket socket) {
            if (!is_linked_to(socket))
                return;
            
            if (socket is Sink)
                remove_sink((Sink) socket);
        }
        
        /**
         * Disconnect from any {@link Socket} that this Source is connected to
         */
        public override void unlink_all() {
            foreach (var sink in _sinks.copy())
                if (sink != null)
                    unlink(sink);
        }
        
        /**
         * Set the value of this Source
         */
        public void set_value(Value? @value, string? flow_id = null) {
            if (@value != null && value_type == @value.type()) {
                last_value = @value;
                
                changed(@value, flow_id);
            }
        }
        
        /**
         * Returns the last value passed throguh this source
         */
        public new Value? get_last_value() {
            return last_value;
        }
    }
}
