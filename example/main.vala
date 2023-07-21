public class NumberGeneratorNode : Flow.Node {
    
    public NumberGeneratorNode() {
        set_label_name("NumberGenerator");
        highlight_color = { 0.6f, 1, 0, 0.3f };
        
        var number_source = new Flow.Source.with_type(Type.DOUBLE) {
            color = { 1, 1, 0, 1 },
            name = "output"
        };
        number_source.set_value(0d);
        add_source(number_source);
        
        var spin_button = new Gtk.SpinButton(new Gtk.Adjustment(0, 0, 100, 1, 10, 0), 0, 0);
        spin_button.set_size_request(50,20);
        spin_button.value_changed.connect(() => {
            number_source.set_value(spin_button.get_value());
        });
        
        content = spin_button;
    }
}

public class OperationNode : Flow.Node {
    private double operand_a_value = 0;
    private double operand_b_value = 0;
    private string operation = "+";
    
    private Flow.Source result;
    
    public OperationNode() {
        set_label_name("Operation");
        highlight_color = { 0.6f, 0, 1, 0.3f };
        
        result = new Flow.Source.with_type(Type.DOUBLE) {
            color = { 1, 0, 1, 1 },
            name = "result"
        };
        
        var summand_a = new Flow.Sink.with_type(Type.DOUBLE) {
            color = { 0, 1, 1, 1 },
            name = "operand A"
        };
        summand_a.changed.connect(@value => {
            if (@value == null) {
                return;
            }
            operand_a_value = @value.get_double();
            publish_result();
        });
        
        var summand_b = new Flow.Sink.with_type(Type.DOUBLE) {
            color = { 0, 1, 0, 1 },
            name = "operand B"
        };
        summand_b.changed.connect(@value => {
            if (@value == null)
                return;
            
            operand_b_value = @value.get_double();
            publish_result();
        });
        
        add_source(result);
        add_sink(summand_a);
        add_sink(summand_b);
        
        string[] operations = { "+", "-", "*", "/" };
        var drop_down = new Gtk.DropDown.from_strings(operations);
        drop_down.notify["selected-item"].connect(() => {
            operation = operations[drop_down.get_selected()];
            publish_result();
        });
        
        content = drop_down;
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
        result.set_value(operation_result);
    }
}

public class PrintNode : Flow.Node {
    public Gtk.Label label;
    
    public PrintNode() {
        set_label_name("Output");
        highlight_color = { 0.6f , 1, 1, 0.3f };
        
        var number = new Flow.Sink.with_type(Type.DOUBLE) {
            color = { 0, 0, 1, 1 },
            name = "input"
        };
        number.changed.connect(display_value);
        
        add_sink(number);
        
        content = label = new Gtk.Label("");
    }
    
    private void display_value(Value? @value) {
        if (@value == null) {
            return;
        }
        
        var text = @value.strdup_contents();
        var dot_index = text.index_of_char('.', 0);
        
        if (text.get_char(dot_index + 1) == '0')
            text = text.substring(0, dot_index);
        else
            text = text.substring(0, dot_index + 2);
        
        label.set_text(text);
    }
}

public class AdvancedCalculatorWindow : Gtk.ApplicationWindow {
    private Flow.NodeView node_view;
    private Gtk.Box menu_content;
    
    public AdvancedCalculatorWindow(Gtk.Application app) {
        application = app;
        
        set_default_size(600, 550);
        init_header_bar();
        init_window_layout();
        init_actions();
    }
    
    private void init_header_bar() {
        set_titlebar(new Gtk.HeaderBar() {
            title_widget = new Gtk.Label("<b>libflow Example</b>") {
                use_markup = true
            }
        });
    }
    
    private void init_window_layout() {
        Gtk.Overlay overlay;
        
        set_child(overlay = new Gtk.Overlay() {
            child = new Gtk.ScrolledWindow() {
                child = this.node_view = new Flow.NodeView()
            }
        });
        
        overlay.add_overlay(new Flow.Minimap() {
            halign = Gtk.Align.END,
            valign = Gtk.Align.END,
            nodeview = node_view,
            can_target = false
        });
    }
    
    private void init_actions() {
        menu_content = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
        node_view.menu_content = menu_content;
        
        add_number_node_action();
        add_operation_node_action();
        add_print_node_action();
    }
    
    private void add_number_node_action() {
        var button = new Gtk.Button.with_label("NumberGenerator");
        button.clicked.connect(() => {
            var node = new NumberGeneratorNode();
            
            node_view.add(node);
            node_view.move(node, 20, 20);
        });
        button.set_has_frame(false);
        menu_content.append(button);
    }
    
    private void add_operation_node_action() {
        var button = new Gtk.Button.with_label("Operation");
        button.clicked.connect(() => {
            var node = new OperationNode();
            
            node_view.add(node);
            node_view.move(node, 200, 20);
        });
        button.set_has_frame(false);
        menu_content.append(button);
    }
    
    private void add_print_node_action() {
        var button = new Gtk.Button.with_label("Print");
        button.clicked.connect(() => {
            var node = new PrintNode();
            
            node_view.add(node);
            node_view.move(node, 400, 20);
        });
        button.set_has_frame(false);
        menu_content.append(button);
    }
}

int main(string[] argv) {
    var app = new Gtk.Application(
        "com.example.GtkApplication",
        ApplicationFlags.FLAGS_NONE
    );
    
    app.activate.connect(() => new AdvancedCalculatorWindow(app).present());
    
    return app.run(argv);
}
