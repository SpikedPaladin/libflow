int main(string[] args) {
    Gtk.init();
    Test.init(ref args);
    
    Test.add_func("/libflow/node-view/add", () => {
		var node_view = new Flow.NodeView();
		var node = new Flow.Node();
		
		node_view.add(node);
		
		var nodes = node_view.get_nodes();
		
		assert(nodes.length() == 1);
		assert(nodes.nth_data(0) == node);
	});
    
    return Test.run();
}
