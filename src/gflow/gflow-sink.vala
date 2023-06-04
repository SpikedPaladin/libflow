namespace GFlow {
    /**
     * A Sink is a special Type of Dock that receives data from
     * a source in order to let it either 
     */
    public interface Sink : Object, Dock {
        /**
         * Returns the sinks that this source is connected to
         */
        public abstract List<Source> sources { get; }

        /**
         * Disconnects the Sink from all {@link Source}s that supply
         * it with data.
         */
        public virtual void unlink_all() throws GLib.Error {
            foreach (Source s in sources) {
                if (s != null) {
                    
                    unlink(s);}}
        }
    }
}
