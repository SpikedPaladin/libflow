namespace GFlow {
    /**
     * Represents an element that can generate, process or receive data
     * This is done by adding Sources and Sinks to it. The inner logic of
     * The node can be represented towards the user as arbitrary Gtk widget.
     */
    public class SimpleNode : Object, Node {
        private List<Source> sources;
        private List<Sink> sinks;

        /**
         * This SimpleNode's name
         */
        public string name { get; set; default = "SimpleNode"; }

        /**
         * Determines wheter the node can be deleted by the user
         */
        public bool deletable { get; set; default = true; }

        /**
         * Determines wheter the node can resized by the user
         */
        public bool resizable { get; set; default = true; }

        public SimpleNode() {
            base();
            sources = new List<Source>();
            sinks = new List<Sink>();
        }

        /**
         * Add the given {@link Source} to this SimpleNode
         */
        public void add_source(Source s) throws NodeError {
            if (s.node != null)
                throw new NodeError.DOCK_ALREADY_BOUND_TO_NODE("This Source is already bound");
            if (sources.index(s) != -1)
                throw new NodeError.ALREADY_HAS_DOCK("This node already has this source");
            sources.append(s);
            s.node = this;
            source_added(s);
        }
        /**
         * Add the given {@link Sink} to this SimpleNode
         */
        public void add_sink(Sink s) throws NodeError {
            if (s.node != null)
                throw new NodeError.DOCK_ALREADY_BOUND_TO_NODE("This Sink is already bound" );
            if (sinks.index(s) != -1)
                throw new NodeError.ALREADY_HAS_DOCK("This node already has this sink");
            sinks.append(s);
            s.node = this;
            sink_added(s);
        }

        /**
         * Remove the given {@link Source} from this SimpleNode
         */
        public void remove_source(Source s) throws NodeError {
            if (sources.index(s) == -1)
                throw new NodeError.NO_SUCH_DOCK("This node doesn't have this source");
            sources.remove(s);
            s.node = null;
            source_removed(s);
        }

        /**
         * Remove the given {@link Sink} from this SimpleNode
         */
        public void remove_sink(Sink s) throws NodeError {
            if (sinks.index(s) == -1)
                throw new NodeError.NO_SUCH_DOCK("This node doesn't have this sink");
            sinks.remove(s);
            s.node = null;
            sink_removed(s);
        }

        /**
         * Returns true if the given {@link Sink} is one of this SimpleNode's Sinks.
         */
        public bool has_sink(Sink s) {
            return sinks.index(s) != -1;
        }

        /**
         * Returns true if the given {@link Source} is one of this SimpleNode's Sources.
         */
        public bool has_source(Source s) {
            return sources.index(s) != -1;
        }

        /**
         * Returns true if the given {@link Dock} is one of this SimpleNode's Docks.
         */
        public bool has_dock(Dock d) {
            if (d is Source)
                return has_source(d as Source);
            else
                return has_sink(d as Sink);
        }

        /**
         * Searches this SimpleNode's {@link Dock}s for a Dock with the given name.
         * If there is any, it will be returned. Else, null will be returned
         */
        public Dock? get_dock(string name) {
            foreach (Sink s in sinks)
                if (s.name == name)
                    return s;
            foreach (Source s in sources)
                if (s.name == name)
                    return s;
            return null;
        }

        /**
         * Returns the sources of this node
         */
        public unowned List<Source> get_sources() {
            return sources;
        }

        /**
         * Returns the sinks of this node
         */
        public unowned List<Sink> get_sinks() {
            return sinks;
        }

        /**
         * This method checks whether a connection from the given from-Node
         * to this Node would lead to a recursion in the direction source -> sink
         */
        public bool is_recursive_forward(Node from, bool initial = true) {
            if (!initial && this == from)
                return true;
            foreach (Source source in get_sources()) {
                foreach (Sink sink in source.sinks) {
                    if (sink.node.is_recursive_forward(from, false))
                        return true;
                }
            }
            return false;
        }

        /**
         * This method checks whether a connection from the given from-Node
         * to this Node would lead to a recursion in the direction sink -> source
         */
        public bool is_recursive_backward(Node from, bool initial = true) {
            if (!initial && this == from)
                return true;
            foreach (Sink sink in sinks) {
                foreach (Source source in sink.sources) {
                    if (source.node.is_recursive_backward(from, false))
                        return true;
                }
            }
            return false;
        }

        /**
         * Gets all neighbor nodes that this node is connected to
         */
        public List<Node> get_neighbors() {
            var result = new List<Node>();
            foreach (Source source in get_sources()) {
                foreach (Sink sink in source.sinks) {
                    if (sink.node != null && result.index(sink.node) == -1)
                        result.append(sink.node);
                }
            }
            foreach (Sink sink in get_sinks()) {
                foreach (Source source in sink.sources) {
                    if (source.node != null && result.index(source.node) == -1)
                        result.append(source.node);
                }
            }
            return result;
        }

        /**
         * Returns true if the given node is directly connected
         * to this node
         */
        public bool is_neighbor(Node n) {
            return get_neighbors().index(n) != -1;
        }

        /**
         * Disconnect all connections from and to this node
         */
        public void unlink_all() {
            foreach (Source s in sources) {
                try {
                    s.unlink_all();
                } catch (GLib.Error e) {
                    warning("Could not unlink source %s from node %s", s.name, name);
                }
            }
            foreach (Sink s in sinks) {
                try {
                    s.unlink_all();
                } catch (GLib.Error e) {
                    warning("Could not unlink sink %s from node %s", s.name, name);
                }
            }
        }
  }
}
