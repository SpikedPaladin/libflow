namespace GFlow {
    /**
     * The Source is a special Type of Dock that provides data.
     * A Source may be used by multitude of Sinks as a source of data.
     */
    public interface Source : Object, Dock {
        /**
         * Returns the sinks that this source is connected to
         */
        public abstract List<Sink> sinks { get; }
        /**
         * Returns the last value passed throguh this source
         */
        public abstract GLib.Value? get_last_value();
    }
}
