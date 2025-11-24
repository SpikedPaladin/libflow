namespace Flow {

    [GtkTemplate (ui = "/me/paladin/libflow/ui/node-view.ui")]
    public partial class NodeView : Gtk.Widget {

        public void add(Node node) {
            node.set_parent(this);
        }

        public override void dispose() {
            var child = get_first_child();

            while (child != null) {
                var delchild = child;
                child = child.get_next_sibling();
                delchild.unparent();
            }

            base.dispose();
        }
    }
}
