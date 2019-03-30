public enum Player {
  WHITE(PlayerType.HUMAN, Heuristic.WITH_MANHATAN, 900000), BLACK(PlayerType.HUMAN, Heuristic.WITH_MANHATAN, 900000);
  
  byte lostPawns = 0;
  PlayerType type;
  Heuristic heuristic;
  int timeLeft;
  
  private Player(PlayerType type, Heuristic heuristic, int timeLeft) {
    this.type = type;
    this.heuristic = heuristic;
    this.timeLeft = timeLeft;
  }
  
  public int getLostPawns() {
    return this.lostPawns;
  }
  
  public PlayerType getPlayerType() {
    return this.type;
  }
  
  public int getTimeLeft() {
    return this.timeLeft;
  }
  
  public String getStringTimeLeft() {
    int m = this.timeLeft/60000, s = (this.timeLeft%60000)/1000;
    return ((m < 10) ? "0"+m : m) +":"+((s < 10) ? "0"+s : s) + ":" +this.timeLeft%1000;
  }
  
  public void reduceTimeLeft(final int time, final int start) {
    this.timeLeft = this.timeLeft - (time-start);
    if (this.timeLeft < 0) this.timeLeft = 0;
  }
}
