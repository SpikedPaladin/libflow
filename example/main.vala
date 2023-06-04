public class NumberGeneratorNode : GFlow.SimpleNode {
    private GFlow.SimpleSource number_source;
    public Gtk.SpinButton spin_button;
    
    public NumberGeneratorNode() {
        try {
            number_source = new GFlow.SimpleSource.with_type(Type.DOUBLE);
            number_source.name = "output";
            
            spin_button = new Gtk.SpinButton(new Gtk.Adjustment(0, 0, 100, 1, 10, 0), 0, 0);
            spin_button.set_size_request(50,20);
            spin_button.value_changed.connect(() => {
                try {
                    number_source.set_value(spin_button.get_value());
                } catch (Error e) {
                    warning("Couldn't set node value %s", e.message);
                }
            });
            
            name = "NumberGenerator";
            add_source(number_source);
        } catch (GFlow.NodeError e) {
            warning("Couldn't build node: %s", e.message);
        }
    }
    
    public void register_colors(GtkFlow.NodeView nv) {
        var number_widget = nv.retrieve_dock(number_source);
        number_widget.resolve_color.connect_after((d,v) => {
            return { 1, 0, 0, 1};
        });
    }
}

public class OperationNode : GFlow.SimpleNode {
    private double operand_a_value = 0;
    private double operand_b_value = 0;
    private string operation = "";
    
    private GFlow.SimpleSink summand_a;
    private GFlow.SimpleSink summand_b;
    
    private GFlow.SimpleSource result;
    public Gtk.DropDown drop_down;
    
    public OperationNode() {
        try {
            name = "Operation";
            
            summand_a = new GFlow.SimpleSink.with_type(Type.DOUBLE);
            summand_a.name = "operand A";
            summand_a.changed.connect(value => {
                if (value == null) {
                    return;
                }
                operand_a_value = value.get_double();
                publish_result();
            });
            add_sink(summand_a);
            
            summand_b = new GFlow.SimpleSink.with_type(Type.DOUBLE);
            summand_b.name = "operand B";
            summand_b.changed.connect(value => {
                if (value == null) {
                    return;
                }
                operand_b_value = value.get_double();
                publish_result();
            });
            add_sink(summand_b);
            
            result = new GFlow.SimpleSource(Type.DOUBLE);
            result.name = "result";
            add_source(result);
            
            string[] operations = {"+", "-", "*", "/"};
            drop_down = new Gtk.DropDown.from_strings(operations);
            drop_down.notify["selected-item"].connect(() => {
                operation = operations[drop_down.get_selected()];
            });
        } catch (GFlow.NodeError e) {
            warning("Couldn't build node: %s", e.message);
        }
    }
    
    private void publish_result() {
        if (operation == "+") {
            set_result(operand_a_value + operand_b_value);
        } else if (operation == "-") {
            set_result(operand_a_value - operand_b_value);
        } else if (operation == "*") {
            set_result(operand_a_value * operand_b_value);
        } else if (operation == "/") {
            set_result(operand_a_value / operand_b_value);
        }
    }
    
    private void set_result(double operation_result) {
        try {
            result.set_value(operation_result);
        } catch (Error e) {
            warning("Couldn't set node value %s", e.message);
        }
    }
    
    public void register_colors(GtkFlow.NodeView nv) {
        var a_widget = nv.retrieve_dock(summand_a);
        var b_widget = nv.retrieve_dock(summand_b);
        var result = nv.retrieve_dock(result);
        a_widget.resolve_color.connect_after((d,v) => {
            return { 1, 0, 0, 1};
        });
        b_widget.resolve_color.connect_after((d,v) => {
            return { 1, 0, 0, 1};
        });
        result.resolve_color.connect_after((d,v) => {
            return { 0, 0, 1, 1};
        });
    }
}

public class PrintNode : GFlow.SimpleNode {
    private GFlow.SimpleSink number;
    public Gtk.Label label;
    
    public PrintNode() {
        try {
            number = new GFlow.SimpleSink.with_type(Type.DOUBLE);
            number.name = "input";
            number.changed.connect(display_value);
            
            label = new Gtk.Label("");
            
            name = "Output";
            add_sink(number);
        } catch (GFlow.NodeError e) {
            warning("Couldn't build node: %s", e.message);
        }
    }
    
    private void display_value(Value? value) {
        if (value == null) {
            return;
        }
        label.set_text(value.strdup_contents());
    }
    
    public void register_colors(GtkFlow.NodeView nv) {
        var number_widget = nv.retrieve_dock(number);
        number_widget.resolve_color.connect_after((d,v) => {
            return { 0, 0, 1, 1};
        });
    }
}

public class AdvancedCalculatorWindow : Gtk.ApplicationWindow {
    
    construct {
        set_default_size(600, 550);
        init_header_bar();
        init_window_layout();
        init_actions();
    }
    
    private Gtk.HeaderBar header_bar;
    private Gtk.Overlay overlay;
    
    private GtkFlow.NodeView node_view;
    private GtkFlow.Minimap minimap;
    
    public AdvancedCalculatorWindow(Gtk.Application app) {
        application = app;
    }
    
    private void init_header_bar() {
        header_bar = new Gtk.HeaderBar() {
            title_widget = new Gtk.Label("GtkFlowGraph")
        };
        set_titlebar(header_bar);
    }
    
    private void init_window_layout() {
        var scrolled_window = new Gtk.ScrolledWindow();
        scrolled_window.vexpand = true;
        
        overlay = new Gtk.Overlay();
        overlay.set_child(scrolled_window);
        
        node_view = new GtkFlow.NodeView();
        var minimap_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.END,
            can_target = false
        };
        
        minimap = new GtkFlow.Minimap() {
            nodeview = node_view,
            can_target = false
        };
        minimap_box.append(minimap);
        overlay.add_overlay(minimap_box);
        
        scrolled_window.set_child(node_view);
        scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        
        set_child(overlay);
    }
    
    private void init_actions() {
        add_number_node_action();
        add_operation_node_action();
        add_print_node_action();
    }
    
    private void add_number_node_action() {
        var button = new Gtk.Button.with_label("NumberGenerator");
        button.clicked.connect(() => {
            var node = new NumberGeneratorNode();
            var gtk_node = new GtkFlow.Node(node);
            
            gtk_node.add_child(node.spin_button);
            gtk_node.highlight_color = { 0.6f, 1.0f, 0.0f, 0.3f };
            node_view.add(gtk_node);
            node_view.move(gtk_node, 20, 20);
            node.register_colors(node_view);
        });
        header_bar.pack_start(button);
    }
    
    private void add_operation_node_action() {
        var button = new Gtk.Button.with_label("Operation");
        button.clicked.connect(() => {
            var node = new OperationNode();
            var gtk_node = new GtkFlow.Node(node);
            
            gtk_node.add_child(node.drop_down);
            gtk_node.highlight_color = { 0.6f, 0, 1, 0.3f};
            node_view.add(gtk_node);
            node_view.move(gtk_node, 220, 20);
            node.register_colors(node_view);
        });
        header_bar.pack_start(button);
    }
    
    private void add_print_node_action() {
        var button = new Gtk.Button.with_label("Print");
        button.clicked.connect(() => {
            var node = new PrintNode();
            var gtk_node = new GtkFlow.Node(node);
            
            gtk_node.add_child(node.label);
            gtk_node.highlight_color = { 0.6f ,1, 1, 0.3f };
            node_view.add(gtk_node);
            node_view.move(gtk_node, 400, 20);
            node.register_colors(node_view);
        });
        header_bar.pack_start(button);
    }
}

int main(string[] argv) {
    var app = new Gtk.Application(
        "com.example.GtkApplication",
        GLib.ApplicationFlags.FLAGS_NONE
    );
    
    app.activate.connect (() => {
        // Create a new window
        var window = new AdvancedCalculatorWindow(app);
        window.present();
    });
    
    return app.run(argv);
}

