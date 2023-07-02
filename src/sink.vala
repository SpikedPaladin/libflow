namespace Flow {
    
    public class Sink : Socket {
        private List<Source> _sources = new List<Source>();
        /**
         * The {@link Source}s that this Sink is currently connected to
         */
        public List<Source> sources { get { return _sources; } }
        /**
         * Defines how many sources can be connected to this sink
         *
         * Setting this variable to a lower value than the current
         * amount of connected sources will have no further effects
         * than not allowing more connections.
         */
        public uint max_sources { get; set; default = 1; }
        
        construct {
            add_css_class("sink");
        }
        
        /**
         * Creates a new Sink with type of given value {@link GLib.Value}
         */
        public Sink(Value @value) {
            value_type = @value.type();
        }
        
        /**
         * Creates a new Sink with given type {@link GLib.Type}
         */
        public Sink.with_type(Type type) {
            value_type = type;
        }
        
        protected void add_source(Source source) {
            if (value_type == source.value_type) {
                _sources.append(source);
                
                changed();
                source.changed.connect(do_source_changed);
            }
        }
        
        protected void remove_source(Source source) {
            if (_sources.index(source) != -1)
                _sources.remove(source);
            
            if (source.is_linked_to(this)) {
                source.unlink(this);
                
                unlinked(source, _sources.length() == 0);
            }
        }
        
        /**
         * Returns true if this Source is connected to one or more Sinks
         */
        public override bool is_linked() {
            return _sources.length() > 0;
        }
        
        /**
         * Returns true if this Source is connected to the given Sink
         */
        public override bool is_linked_to(Socket socket) {
            if (!(socket is Source))
                return false;
            
            return _sources.index((Source) socket) != -1;
        }
        
        /**
         * Connect to the given {@link Socket}
         */
        public override void link(Socket socket) {
            if (is_linked_to(socket))
                return;
            
            if (!before_linking(this, socket))
                return;
            
            // Switching
            if (_sources.length() + 1 > max_sources && sources.length() > 0)
                unlink(sources.nth_data(sources.length() - 1));
            
            if (socket is Source) {
                add_source((Source) socket);
                changed();
                socket.link(this);
                
                linked(socket);
            }
        }
        
        /**
         * Disconnect from the given {@link Socket}
         */
        public override void unlink(Socket socket) {
            if (!is_linked_to(socket))
                return;
            
            if (socket is Source) {
                remove_source((Source) socket);
                do_source_changed();
                socket.unlinked(this, sources.length() == 0);
                socket.changed.disconnect(do_source_changed);
                changed();
            }
        }
        
        /**
         * Disconnects the Sink from all {@link Source}s that supply
         * it with data.
         */
        public override void unlink_all() {
            // Copy is required to avoid crash
            foreach (var source in _sources.copy())
                if (source != null)
                    unlink(source);
        }
        
        private void do_source_changed(Value? source_value = null, string? flow_id = null) {
            changed(source_value, flow_id);
        }
    }
}
