namespace GFlow {
    /**
     * This class represents an endpoint of a node. These endpoints can be
     * connected in order to let them exchange data. The data contained
     * in this endpoint is stored as GLib.Value. Only Docks that contain
     * data with the same VariantType can be interconnected.
     */
    public interface Dock : Object {
        /**
         * The name that will be rendered for this dock
         */
        public abstract string? name { get; set; }

        /**
         * The string rendered as typehint for this dock.
         * If this string is "" and the show_type is set to true
         * libgflow will attempt to determine the type of this
         * dock and display it, but it produces nicer results to set
         * them manually.
         */
        public abstract string? typename { get; set; }

        /**
         * Determines whether this dock is highlighted
         * this is usually triggered when the mouse hovers over it
         */
        public abstract bool highlight { get; set; }

        /**
         * Determines whether this dock is active
         */
        public abstract bool active { get; set; }

        /**
         * A reference to the node this Dock resides in
         */
        public abstract weak Node? node { get; set; }

        /**
         * The type that has been set to this dock
         */
        public abstract GLib.Type value_type { get; }

        /**
         * This signal is being triggered, when there is a connection being established
         * from or to this Dock.
         */
        public signal void linked (Dock d);

        /**
         * This signal is being triggered, before a connection is made
         * between two docks. If the implementor returns false, the
         * connection is not being made.
         * IMPORTANT: Connect to this signal with connect_after
         * otherwise this default handler will be called after the
         * signal you implemented, thus always returning true,
         * rendering your code ineffective.
         */
        public virtual signal bool before_linking (Dock self, Dock other){
            return true;
        }

        /**
         * This signal is being triggered, when there is a connection being removed
         * from or to this Dock. If this the last connection of the dock, the
         * boolean parameter last will be set to true.
         */
        public signal void unlinked (Dock d, bool last);

        /**
         * Triggers when the value of this dock changes
         */
        public signal void changed(Value? value = null, string? flow_id = null);

        /**
         * Implementations should return true if this dock has at least one
         * connection to another dock
         */
        public abstract bool is_linked ();

        /**
         * Implementations should return true if this dock is connected
         * to the supplied dock
         */
        public abstract bool is_linked_to (Dock dock);

        /**
         * Connect this {@link Dock} to other {@link Dock}
         */
        public abstract void link (Dock dock) throws GLib.Error;
        /**
         * Disconnect this {@link Dock} from other {@link Dock}
         */
        public abstract void unlink (Dock dock) throws GLib.Error;
        /**
         * Disconnect this {@link Dock} from all {@link Dock}s it is connected to
         */
        public abstract void unlink_all () throws GLib.Error;

        /**
         * Tries to resolve this Dock's value-type to a displayable string
         */
        public virtual string determine_typestring () {
            return this.value_type.name();
        }

        /**
         * Returs true if this and the supplied dock have
         * same type
         */
        public virtual bool has_same_type (Dock other) {
            return this.value_type == other.value_type;
        }
    }
}
