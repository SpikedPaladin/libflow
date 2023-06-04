/**
 * Flowgraphs for Gtk
 */
namespace GFlow {
    public errordomain NodeError {
        /**
         * Throw when the user tries to connect a source to a sink that
         * Delivers a different type
         */
        INCOMPATIBLE_SINKTYPE,
        /**
         * Throw when a user tries to assign a value with a wrong type
         * to a sink
         */
        INCOMPATIBLE_VALUE,
        /**
         * Throw when the user tries to add a dock to a node
         * That already contains a dock
         */
        ALREADY_HAS_DOCK,
        /**
         * Throw when the dock that the user tries to add already
         * belongs to another node
         */
        DOCK_ALREADY_BOUND_TO_NODE,
        /**
         * Throw when the user tries to remove a dock from a node
         * that hasn't yet been added to the node
         */
        NO_SUCH_DOCK,
        /**
         * Throw when the value of a sink is invalid
         */
        INVALID
    }
    /**
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it.
     */
    public interface Node : GLib.Object {
        /**
         * This signal is being triggered when a {@link Sink} is added to this Node
         */
        public signal void sink_added (Sink s);
        /**
         * This signal is being triggered when a {@link Source} is added to this Node
         */
        public signal void source_added (Source s);
        /**
         * This signal is being triggered when a {@link Sink} is removed from this Node
         */
        public signal void sink_removed (Sink s);
        /**
         * This signal is being triggered when a {@link Source} is removed from this Node
         */
        public signal void source_removed (Source s);

        /**
         * This node's name
         */
        public abstract string name { get; set; }
        /**
         * Determines wheter the user be allowed to remove the node. Otherwise
         * the node can only be removed programmatically
         */
        public abstract bool deletable { get; set; default=true;}
        /**
         * Determines wheter the user be allowed to remove the node. Otherwise
         * the node can only be removed programmatically
         */
        public abstract bool resizable { get; set; default=true;}
        /**
         * Implementations should destroy all connections of this Node's {@link Sink}s
         * and {@link Source}s when this method is executed
         */
        public abstract void unlink_all ();
        /**
         * Determines whether the given from-{@link Node} can be found if we
         * recursively follow all nodes that are connected to this node's {@link Source}s
         */
        public abstract bool is_recursive_forward (Node from, bool initial=false);
        /**
         * Determines whether the given from-{@link Node} can be found if we
         * recursively follow all nodes that are connected to this node's {@link Sink}s
         */
        public abstract bool is_recursive_backward (Node from, bool initial=false);
        /**
         * Implementations should return the {@link Dock} with the given name if they contain
         * any. If not, return null.
         */
        public abstract Dock? get_dock (string name);
        /**
         * Implementations should return true if the given {@link Dock} has been
         * assigned to this node
         */
        public abstract bool has_dock(Dock d);
        /**
         * Return a {@link GLib.List} of this Node's {@link Source}s
         */
        public abstract unowned List<Source> get_sources ();
        /**
         * Return a {@link GLib.List} of this Node's {@link Sink}s
         */
        public abstract unowned List<Sink> get_sinks ();
        /**
         * Returns the Nodes that this Node is connected to
         */
        public abstract List<Node> get_neighbors();
        /**
         * Returns true if the given node is directly connected to this node
         */
        public abstract bool is_neighbor(Node n);
        /**
         * Assign a {@link Source} to this Node
         */
        public abstract void add_source (Source source) throws NodeError;
        /**
         * Remove a {@link Source} from this Node
         */
        public abstract void remove_source (Source source) throws NodeError;
        /**
         * Return true if the supplied {@link Source} is assigned to this Node
         */
        public abstract bool has_source (Source s);
        /**
         * Assign a {@link Sink} to this Node
         */
        public abstract void add_sink (Sink sink) throws NodeError;
        /**
         * Return true if the supplied {@link Sink} is assigned to this Node
         */
        public abstract bool has_sink (Sink s);
        /**
         * Remove a {@link Sink} from this Node
         */
        public abstract void remove_sink (Sink sink) throws NodeError;
    }
}
