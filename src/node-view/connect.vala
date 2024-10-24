namespace Flow {
    
    public class Connection : Object {
        public float line_width {
            get { return source.line_width; }
        }
        
        public weak Source source;
        public weak Sink sink;
        
        public Connection(Source source, Sink sink) {
            this.source = source;
            this.sink = sink;
            
            source.add_connection(this);
            sink.add_connection(this);
        }
        
        ~Connection() {
            source.remove_connection(this);
            sink.remove_connection(this);
        }
    }
    
    public partial class NodeView {
        public List<Connection> connections = new List<Connection>();
        
        private void connect_sockets(Socket socket1, Socket socket2) {
            if (socket1.node == socket2.node)
                return;
            
            if (socket1 is Source && socket2 is Sink) {
                check_and_connect((Source) socket1, (Sink) socket2);
            } else if (socket1 is Sink && socket2 is Source) {
                check_and_connect((Source) socket2, (Sink) socket1);
            }
        }
        
        private void check_and_connect(Source source, Sink sink) {
            if (source.value_type != sink.value_type)
                return;
            
            var connection = get_connection(source, sink);
            
            if (connection != null) {
                connections.remove(connection);
            } else {
                connection = new Connection(source, sink);
                
                connections.append(connection);
            }
        }
        
        public void unlink_all(Node node) {
            foreach (var source in node.sources)
                foreach (var connection in get_socket_connections(source))
                    connections.remove(connection);
            
            foreach (var sink in node.sinks)
                foreach (var connection in get_socket_connections(sink))
                    connections.remove(connection);
        }
        
        public Connection? get_connection(Source source, Sink sink) {
            foreach (var connection in connections) {
                if (connection.source == source && connection.sink == sink) {
                    return connection;
                }
            }
            
            return null;
        }
        
        public Connection[] get_socket_connections(Socket socket) {
            Connection[] conns = {};
            foreach (var connection in connections) {
                if (connection.source == socket || connection.sink == socket) {
                    conns += connection;
                }
            }
            
            return conns;
        }
    }
}