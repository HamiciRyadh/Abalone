public class Blob {
  float minx, maxx, miny, maxy;
  
  public Blob(float minx, float miny) {
    this.minx = minx;
    this.maxx = minx;
    this.miny = miny;
    this.maxy = miny;
  }
  
  void add(float x, float y) {
    minx = min(minx, x);
    miny = min(miny, y);
    maxx = max(maxx, x);
    maxy = max(maxy, y);
  }
  
  boolean isNear(float x, float y, int threshold) {
    float centerX = (minx + maxx)/2;
    float centerY = (miny + maxy)/2;
    
    if (squareDistance(centerX, centerY, x, y) < threshold) return true;
    return false;
  }
  
  float size() {
    return (maxx-minx)*(maxy-miny);
  }
  
  boolean isAlmostSquared() {
    if (maxx-minx-SQUARE_THRESHOLD <= maxy-miny && maxx-minx+SQUARE_THRESHOLD >= maxy-miny) return true;
    return false;
  }
  
  int getCenterX() {
    return int((maxx+minx)/2);
  }
  
  int getCenterY() {
    return int((maxy+miny)/2);
  }
  
  void show() {
    stroke(0);
    fill(255);
    strokeWeight(2);
    rectMode(CORNERS);
    rect(minx, miny, maxx, maxy);
  }
}
