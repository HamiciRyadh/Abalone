public enum Mouvement {
  MV_UP_LEFT(Orientation.VERTICAL_LR, -1, -1), MV_LEFT(Orientation.HORIZONTAL, -2, 0), MV_DOWN_LEFT(Orientation.VERTICAL_RL, -1, 1),
  MV_DOWN_RIGHT(Orientation.VERTICAL_LR, 1, 1), MV_RIGHT(Orientation.HORIZONTAL, 2, 0), MV_UP_RIGHT(Orientation.VERTICAL_RL, 1, -1);
  
  Orientation orientation;
  int newX, newY;
  private Mouvement(Orientation orientation, int newX, int newY) {
    this.orientation = orientation;
    this.newX = newX;
    this.newY = newY;
  }
  
  public Orientation getOrientation() {
    return this.orientation;
  }
  
  public int getNewX() {
    return this.newX;
  }
  
  public int getNewY() {
    return this.newY;
  }
}
