namespace GFlow {
    /**
     * A simple implementation of {@link GFlow.Source}.
     */
    public class SimpleSource : Object, Dock, Source {
        // Dock interface
        protected GLib.Type _type;
        protected bool _valid = false;
        private GLib.Value? last_value = null;
        
        private string? _name = null;
        /**
         * This SimpleSource's displayname
         */
        public string? name { 
            get { return this._name; }
            set { this._name = value; }
        }
        /**
         * This SimpleSource's typestring
         */
        public string? _typename = null;
        public string? typename {
            get { return this._typename; }
            set { this._typename = value; }
        }
        /**
         * Indicates whether this Source should be rendered highlighted
         */
        public bool highlight { get; set; }
        /**
         * Indicates whether this Source should be rendered active
         */
        public bool active {get; set; default=false;}
        /**
         * A reference to the {@link Node} that this SimpleSource resides in
         */
        public weak Node? node { get; set; }
        /**
         * Creates a new SimpleSource. Supply an arbitrary {@link GLib.Value}. This
         * initial value's type will determine this SimpleSource's type.
         */
        public SimpleSource(GLib.Value value) {
          _type = value.get_gtype();
        }
        
        /**
         * Creates a new SimpleSource with given type {@link GLib.Type}
         */
         public SimpleSource.with_type(GLib.Type type) {
            _type = type;
          }
        
        /**
         * The value that this SimpleSource was initialized with
         */
        public GLib.Type value_type { get { return _type; } }
        
        // Source interface
        private List<Sink> _sinks = new List<Sink> ();
        /**
         * The {@link Sink}s that this SimpleSource is connected to
         */
        public List<Sink> sinks { get { return _sinks; } }
        
        /**
         * Connects this SimpleSource to the given {@link Sink}. This will
         * only succeed if both {@link Dock}s are of the same type. If this
         * is not the case, an exception will be thrown
         */
        protected void add_sink(Sink s) throws Error {
            if (this.value_type != s.value_type) {
                throw new NodeError.INCOMPATIBLE_SINKTYPE(
                    "Can't connect. Sink has type %s while Source has type %s".printf(
                        s.value_type.name(), this.value_type.name()
                    )
                );
            }
            this._sinks.append (s);
            this.changed();
        }
        
        /**
         * Destroys the connection between this SimpleSource and the given {@link Sink}
         */
        protected void remove_sink (Sink s) throws GLib.Error
        {
            if (this._sinks.index(s) != -1)
                this._sinks.remove(s);
            if (s.is_linked_to(this)) {
                s.unlink (this);
                this.unlinked(s, this._sinks.length () == 0);
            }
        }
        
        /**
         * Returns true if this Source is connected to the given Sink
         */
        public bool is_linked_to (Dock dock) {
            if (!(dock is Sink)) return false;
            return this._sinks.index((Sink) dock) != -1;
        }
        
        /**
         * Returns true if this Source is connected to one or more Sinks
         */
        public bool is_linked () {
            return this.sinks.length () > 0;
        }
        
        /**
         * Disconnect from the given {@link Dock}
         */
        public new void unlink (Dock dock) throws GLib.Error
        {
            if (!this.is_linked_to (dock)) return;
            if (dock is Sink) {
                remove_sink ((Sink) dock);
            }
        }
        
        /**
         * Connect to the given {@link Dock}
         */
        public new void link (Dock dock) throws GLib.Error
        {
            if (!this.before_linking(this, dock)) return;
            if (dock is Sink) {
                if (this.is_linked_to (dock)) return;
                add_sink ((Sink) dock);
                dock.link (this);
                linked (dock);
            }
        }
        
        /**
         * Disconnect from any {@link Dock} that this SimplesSource is connected to
         */
        public new void unlink_all () throws GLib.Error {
            foreach (Sink s in this._sinks.copy())
                if (s != null)
                    this.unlink(s);
        }
        
        /**
         * Set the value of this SimpleSource
         */
        public void set_value (GLib.Value? v, string? flow_id = null) throws GLib.Error
        {
            if (v != null && this.value_type != v.type())
                throw new NodeError.INCOMPATIBLE_VALUE(
                    "Cannot set a %s value to this %s Source".printf(
                        v.type().name(), this.value_type.name())
                );
            this.last_value = v;
            changed(v, flow_id);
        }
        
        /**
         * {@inheritDoc}
         */
        public new GLib.Value? get_last_value() {
            return this.last_value;
        }
    }
}
