namespace Flow {
    
    public partial class NodeView {
        
        public void foreach_childs(ChildFunc func) {
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                if (!(child is NodeViewChild))
                    continue;
                
                func(child as NodeViewChild);
            }
        }
        
        public void foreach_nodes(NodeFunc func) {
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                if (!(child is Node))
                    continue;
                
                func(child as Node);
            }
        }
        
        public delegate void ChildFunc(NodeViewChild child);
        public delegate void NodeFunc(Node node);
    }
}