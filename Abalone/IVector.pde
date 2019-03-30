/**
 * This class is used to sotre the x and y positions of an element.
 */
public class IVector implements Comparable<IVector> {
  int x,y;
  
  public IVector(int x, int y) {
    this.x = x;
    this.y = y;
  }
  
  /**
   * Checks the equality between the current object and the given IVector element, returns true if 
   * they have equal values of x and y, false otherwise.
   */
  public boolean iEquals(IVector vector) {
    if (vector == null) return false;
    return this.x == vector.x && this.y == vector.y;
  }
  
  public boolean equals(IVector vector) {
    if (vector == null) return false;
    return this.x == vector.x && this.y == vector.y;
  }
  
  @Override
  public int compareTo(IVector comp) {
    if (this.y < comp.y) return -1;
    if (this.y > comp.y) return 1;
    
    if (this.x < comp.x) return -1;
    if (this.x > comp.x) return 1;
    
    return 0;
  }
  
  public IVector clone() {
    return new IVector(this.x, this.y);
  }
  
  @Override
  public String toString() {
    return "X : " + this.x + ", Y : " + this.y;
  }
}
