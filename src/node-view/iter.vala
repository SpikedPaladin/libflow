namespace Flow {
    
    public partial class NodeView {
        
        public void foreach_childs(ForeachChildFunc func) {
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                if (!(child is NodeViewChild))
                    continue;
                
                func(child as NodeViewChild);
            }
        }
        
        public void foreach_nodes(ForeachNodeFunc func) {
            for (var child = get_first_child(); child != null; child = child.get_next_sibling()) {
                if (!(child is Node))
                    continue;
                
                func(child as Node);
            }
        }
        
        public delegate void ForeachChildFunc(NodeViewChild child);
        public delegate void ForeachNodeFunc(Node node);
    }
}