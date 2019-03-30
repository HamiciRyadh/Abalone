public class Node {
  ArrayList<IVector> selectedPawns;
  Action actionUsed;
  
  ArrayList<IVector> newPlayerPawns;
  ArrayList<IVector> newEnnemyPawns;
  
  ArrayList<Node> nodes;
  
  int gain;
  
  public Node(ArrayList<IVector> selectedPawns, Action actionUsed) {
    this.selectedPawns = selectedPawns;
    this.actionUsed = actionUsed;
    this.newPlayerPawns = new ArrayList<IVector>();
    this.newEnnemyPawns = new ArrayList<IVector>();
  }
  
  void addNode(Node node) {
    if (this.nodes == null) this.nodes = new ArrayList<Node>();
    nodes.add(node);
  }
  
  public Node clone() {
    final Node val =  new Node(null, null);
    val.newEnnemyPawns = cloneIVectorList(this.newEnnemyPawns);
    val.newPlayerPawns = cloneIVectorList(this.newPlayerPawns);
    return val;
  }
}
