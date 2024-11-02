int main(string[] args) {
    Gtk.init();
    Test.init(ref args);
    
    Test.add_func("/libflow/node-view/add", test_add);
    
    return Test.run();
}

public void test_add() {
    var node_view = new Flow.NodeView();
    
    var node = new Flow.Node();
    
    node_view.add(node);
    
    assert(node.node_view == node_view);
    assert(node_view.get_nodes().length() == 1);
    
    node.delete();
    
    assert(node.node_view == null);
    assert(node_view.get_nodes().length() == 0);
}
