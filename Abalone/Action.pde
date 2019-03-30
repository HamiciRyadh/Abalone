public class Action {
  IVector position;
  Mouvement mouvement;
  ArrayList<IVector> pawns = null;
  int[] pawnsPositions;
  
  public Action(IVector position, Mouvement mouvement) {
    this.position = position;
    this.mouvement = mouvement;
  }
}
