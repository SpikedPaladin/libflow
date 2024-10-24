namespace Flow {
    
    [GtkTemplate (ui = "/me/paladin/libflow/ui/node.ui")]
    public class Node : NodeViewChild {
        [GtkChild]
        private unowned Gtk.PopoverMenu menu;
        [GtkChild]
        private unowned Gtk.Box main_box;
        [GtkChild]
        private unowned Gtk.Box title_box;
        [GtkChild]
        private unowned Gtk.Box sink_box;
        [GtkChild]
        private unowned Gtk.Box source_box;
        [GtkChild]
        private unowned Gtk.Box content_box;
        
        public NodeView? node_view { get; set; }
        
        public List<Source> sources = new List<Source>();
        public List<Sink> sinks = new List<Sink>();
        
        private TitleStyle _title_style = TitleStyle.FLAT;
        private Gtk.Widget _content;
        private bool _selected;
        public bool selected {
            get { return _selected; }
            set {
                if (value)
                    set_state_flags(Gtk.StateFlags.SELECTED, false);
                else
                    unset_state_flags(Gtk.StateFlags.SELECTED);
                
                _selected = value;
            }
        }
        public string title {
            get; set;
        }
        public TitleStyle title_style {
            get { return _title_style; }
            set {
                _title_style = value;
                title_box.css_classes = value.get_css_styles();
            }
        }
        public Gtk.Widget content {
            get { return _content; }
            set {
                if (_content == value)
                    return;
                
                content_box.visible = false;
                _content?.unparent();
                _content = value;
                
                if (_content != null) {
                    content_box.visible = true;
                    content_box.append(_content);
                }
            }
        }
        
        static construct {
            set_css_name("node");
        }
        
        construct {
            set_layout_manager(new Gtk.BinLayout());
            
            var action_group = new SimpleActionGroup();
            var delete_action = new SimpleAction("delete", null);
            delete_action.activate.connect(() => {
                @delete();
            });
            action_group.add_action(delete_action);
            
            var unlink_action = new SimpleAction("unlink-all", null);
            unlink_action.activate.connect(() => {
                node_view?.unlink_all(this);
            });
            action_group.add_action(unlink_action);
            var test_action = new SimpleAction("test", null);
            
            insert_action_group("node", action_group);
        }
        
        public void add_sink(Sink sink) {
            if (sink.node != null)
                return;
            
            sinks.append(sink);
            sink.node = this;
            
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
            
            box.append(sink);
            box.append(new Gtk.Label(sink.name));
            
            sink_box.append(box);
        }
        
        public void add_source(Source source) {
            if (source.node != null)
                return;
            
            sources.append(source);
            source.node = this;
            
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
            
            box.append(new Gtk.Label(source.name));
            box.append(source);
            
            source_box.append(box);
        }
        
        [GtkCallback]
        private void open_menu(int n_clicks, double x, double y) {
            menu.set_pointing_to({ (int) x, (int) y, 1, 1 });
            menu.popup();
        }
        
        public void @delete() {
            node_view?.unlink_all(this);
            unparent();
        }
        
        public new void set_parent(Gtk.Widget parent) {
            if (parent is NodeView)
                node_view = (NodeView) parent;
            
            base.set_parent(parent);
        }
        
        /**
         * {@inheritDoc}
         */
        public override void dispose() {
            main_box.unparent();
            menu.unparent();
            base.dispose();
        }
    }
}