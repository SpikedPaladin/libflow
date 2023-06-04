namespace GFlow {
    /**
     * A simple implementation of {@link GFlow.Sink}.
     */
    public class SimpleSink : Object, Dock, Sink {
        // Dock interface
        protected GLib.Type _type = GLib.Type.NONE;

        private string? _name = null;
        /**
         * This SimpleSink's displayname
         */
        public string? name { 
            get { return this._name; }
            set { this._name = value; }
        }
        public string? _typename = null;
        /**
         * This SimpleSink's typestring
         */
        public string? typename {
            get { return this._typename; }
            set { this._typename = value; }
        }

        /**
         * Defines how many sources can be connected to this sink
         *
         * Setting this variable to a lower value than the current
         * amount of connected sources will have no further effects
         * than not allowing more connections.
         */
        public uint max_sources {get; set; default=1;}

        /**
         * Indicates whether this Sink should be rendered highlighted
         */
        public bool highlight { get; set; default = false; }
        /**
         * Indicates whether this Sink should be rendered active
         */
        public bool active {get; set; default=false;}
        /**
         * A reference to the {@link Node} that this SimpleSink resides in
         */
        public weak Node? node { get; set; }
        /**
         * The type that this SimpleSink was initialized with
         */
        public GLib.Type value_type { get { return _type; } }

        // Sink Interface
        private List<Source> _sources = new List<Source> ();
        /**
         * The {@link Source}s that this SimpleSink is currently connected to
         */
        public List<Source> sources { get { return _sources; } }

        /**
         * Connects this SimpleSink to the given {@link Source}. This will
         * only succeed if both {@link Dock}s are of the same type. If this
         * is not the case, an exception will be thrown
         */
        protected void add_source(Source s) throws Error
        {
            if (this.value_type != s.value_type) {
                throw new NodeError.INCOMPATIBLE_SINKTYPE(
                    "Can't connect. Source has type %s while Sink has type %s".printf(
                        s.value_type.name(), this.value_type.name()
                    )
                );
            }
            this._sources.append(s);
            s.changed.connect(this.do_source_changed);
        }

        /**
         * Destroys the connection between this SimpleSink and the given {@link Source}
         */
        protected void remove_source (Source s) throws GLib.Error
        {
            if (this._sources.index(s) != -1)
                this._sources.remove(s);
            if (s.is_linked_to(this)) {
                s.unlink (this);
                this.unlinked(s, this._sources.length () == 0);
            }
        }
        
        /**
         * Creates a new SimpleSink with type of given value {@link GLib.Value}
         */
        public SimpleSink(GLib.Value value) {
            _type = value.type();
        }

        /**
         * Creates a new SimpleSink with given type {@link GLib.Type}
         */
        public SimpleSink.with_type(GLib.Type type) {
            _type = type;
        }

        /**
         * Returns true if this sink is connected to at least one source
         */
        public bool is_linked() {
            return this.sources.length() > 0;
        }

        /**
         * Returns true if this SimpleSink is connected to the given {@link Dock}
         */
        public bool is_linked_to (Dock dock) { // FIXME Use more logic to know Source type, value or name
            if (!(dock is Source)) return false;
            return this._sources.index((Source) dock) != -1;
        }

        /**
         * Disconnect from the given {@link Dock}
         */
        public new void unlink (Dock dock) throws GLib.Error {
            if (!this.is_linked_to (dock)) return;
            if (dock is Source) {
                this.remove_source((Source) dock);
                this.do_source_changed();
                dock.unlinked(this, this.sources.length() == 0);
                dock.changed.disconnect(this.do_source_changed);
                changed();
            }
        }

        private void do_source_changed(Value? source_value = null, string? flow_id = null) {
            changed(source_value, flow_id);
        }

        /**
         * Connect to the given {@link Dock}
         */
        public new void link (Dock dock) throws GLib.Error {
            if (this.is_linked_to (dock)) return;
            if (!this.before_linking(this, dock)) return;
            if (this._sources.length()+1 > this.max_sources && this.sources.length() > 0) {
                this.unlink(this.sources.nth_data(this.sources.length()-1));
            }
            if (dock is Source) {
                add_source((Source) dock);
                changed();
                dock.link (this);
                linked (dock);
            }
        }

        /**
         * Disconnect from any {@link Dock} that this SimpleSink is connected to
         */
        public new void unlink_all() throws GLib.Error {
            foreach (Source s in this._sources)
                if (s != null)
                    this.unlink(s);
        }
    }
}
