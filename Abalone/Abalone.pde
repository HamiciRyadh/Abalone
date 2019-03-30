import g4p_controls.*;
import processing.video.*;

import java.util.Collections;
import java.util.Arrays;


Capture cam;
ArrayList<Blob> blobsFound = new ArrayList<Blob>();
ArrayList<IVector> positionsFound = new ArrayList<IVector>();
ArrayList<Node> possibleNodes = new ArrayList<Node>();

final float[] COLOR1 = {255,0,100};
final int COLOR_THRESHOLD = 160;
final int SHAPE_THRESHOLD = 25;
final int SIZE_THRESHOLD_MIN = 400;
final int SIZE_THRESHOLD_MAX = 900;
final int SQUARE_THRESHOLD = 10;



final int CELL_WH = 80;
final int PAWNS_FOR_DEFEAT = 8;
color BLACK = color(0, 0 ,0);
color WHITE = color(255, 255, 255);
final color RED = color(200, 20, 20);
final color GRAY_C = color(150, 150, 150, 100);
final color SELECTED = color(0, 255, 0);
final color MOUVEMENT = color(200, 200, 0);
final IVector CENTER_POS = new IVector(8,4);

int i, j, w, h, loadPix = 0, turns = 1, nbreImgs = 0;
int tree_depth = 1;
float r,g,b;

boolean playing = false;
boolean endGame = false;

color winner;
//To calculate how much time each player spends for his turn.
int start;

Player player, ennemy;

ArrayList<IVector> whitePawns;
ArrayList<IVector> blackPawns;
ArrayList<IVector> selectedPawns;
ArrayList<IVector> playerPawns;
ArrayList<IVector> ennemyPawns;
ArrayList<Action> actionCells;

ArrayList<ArrayList<IVector>> previousWhitePositions;
ArrayList<ArrayList<IVector>> previousBlackPositions;

int[][] matrice = {
  {0, 0, 0, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 0, 0, 0},//17 columns 9 rows
  {0, 0, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 0, 0},
  {0, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 0},
  {0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0},
  {4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4},
  {0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0},
  {0, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 0},
  {0, 0, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 0, 0},
  {0, 0, 0, 0, 4, 0, 4, 0, 4, 0, 4, 0, 4, 0, 0, 0, 0}
};

void setup() {
  //To test negamax function during the presentation
  //testNegamax();
  w=CELL_WH*17;
  h=CELL_WH*9;
  size(400, 500);
  surface.setResizable(true);
  loadPixels();
  frameRate(15);
  createGUI();
  help_wnd.setVisible(false);
  hideSecondaryButtons();
}


void init() {
  hideMainButtons();
  surface.setSize(1360, 720);
  surface.setResizable(false);
  Player.WHITE.timeLeft = 900000;
  Player.BLACK.timeLeft = 900000;
  turns = 1;
  initPawns();
  selectedPawns = new ArrayList<IVector>();
  actionCells = new ArrayList<Action>();
  previousBlackPositions = new ArrayList<ArrayList<IVector>>();
  previousWhitePositions = new ArrayList<ArrayList<IVector>>();
  previousWhitePositions.add(cloneIVectorList(this.whitePawns));
  previousBlackPositions.add(cloneIVectorList(this.blackPawns));
  player = Player.BLACK;
  ennemy = Player.WHITE;
  playerPawns = this.blackPawns;
  ennemyPawns = this.whitePawns;
  endGame = false;
  playing = true;
  BLACK = color(0, 0, 0);
  WHITE = color(255, 255, 255);
}

void initPawns() {
  whitePawns = new ArrayList<IVector>();
  for (int i = 0; i < 2; i++) {
    for (int j = 0; j < 17; j++) {
      if (matrice[i][j] == 4) {
        whitePawns.add(new IVector(j,i));
      }
    }
  }
  whitePawns.add(new IVector(6,2));
  whitePawns.add(new IVector(8,2));
  whitePawns.add(new IVector(10,2));
  
  blackPawns = new ArrayList<IVector>();
  for (int i = 7; i < 9; i++) {
    for (int j = 0; j < 17; j++) {
      if (matrice[i][j] == 4) {
        blackPawns.add(new IVector(j,i));
      }
    }
  }
  blackPawns.add(new IVector(6,6));
  blackPawns.add(new IVector(8,6));
  blackPawns.add(new IVector(10,6));
}

void draw() {
  if (playing && !endGame) {
    if (loadPix == 0) {
      loadPixels();
      loadPix = 1;
      drawBoard();
    }
    this.player.reduceTimeLeft(millis(), start);
    start = millis();
    if (this.player.timeLeft <= 0) {
      //End of the game
      handleNoTimeLeft();
    } else if (PlayerType.HUMAN.equals(this.player.getPlayerType())) {
      handleClick();
      this.actionCells.clear();
      this.actionCells = possibleMouvements(this.playerPawns, this.ennemyPawns, this.selectedPawns);
    } else if (PlayerType.MACHINE.equals(this.player.getPlayerType())) {
      AI();
      changePlayer();
      handleDefeat(this.playerPawns.size(), this.player);
    } else if (PlayerType.OTHER_MACHINE.equals(this.player.getPlayerType())) {
      handleWebcam();
    }
    
    updatePixels();
    
    drawPawns(this.whitePawns, WHITE);
    drawPawns(this.blackPawns, BLACK);
    drawSelectedPawns(this.selectedPawns, SELECTED);
    drawPossibleMouvements(this.actionCells, MOUVEMENT);
    drawPlayersInformations();
  } else if (endGame) {
    drawEndOfGame(winner);
  }
}

/*********************Drawing**************************/

void drawBoard() {
  int val, loc, stepx, stepy;
  stepx = w/17;
  stepy = h/9;
    
  for (int x = 0; x < w; x++ ) {
    for (int y = 0; y < h; y++ ) {
      loc = x + y*w;
      
      if (x % stepx == 0 || y % stepy ==0) val = 1;
      else {
        i= y/stepy; j=x/stepx;
        val=matrice[i][j];
      }
      
      switch (val) {
        case 0: r = 201; g = 159; b = 58; break; //Décors
        case 1: r = 0; g = 0; b = 0; break; //Murs
        case 4: r = 96; g = 51; b = 00; break; //Case Utilisable
        case 5: r = 200; g = 200; b = 0; break; //Case Prévision
      } 
      color c = color(r, g, b);
      pixels[loc]=c;      
    }
  }
}

void drawPawns(final ArrayList<IVector> pawns, final color c) {
  IVector temps;
  for (int i = 0; i < pawns.size(); i++) {
    temps = pawns.get(i);
    if (!selectedPawns.contains(temps)) {
      fill(c);
      strokeWeight(1);
      stroke(0,100);
      ellipse(findPixelXY(temps.x), findPixelXY(temps.y), 0.8*CELL_WH, 0.8*CELL_WH);
    }
  }
}

void drawSelectedPawns(final ArrayList<IVector> pawns, final color c) {
  IVector temps;
  for (int i = 0; i < pawns.size(); i++) {
    temps = pawns.get(i);
    fill(c);
    strokeWeight(1);
    stroke(0,100);
    ellipse(findPixelXY(temps.x), findPixelXY(temps.y), 0.8*CELL_WH, 0.8*CELL_WH);
  }
}

void drawPossibleMouvements(final ArrayList<Action> actions, final color c) {
  IVector temps;
  Mouvement mouvement;
  int x0, y0, x1, y1;
  for (int i = 0; i < actions.size(); i++) {
     temps = actions.get(i).position;
     mouvement = actions.get(i).mouvement;
     strokeWeight(3);
     stroke(c);
     x0 = findPixelXY(temps.x - mouvement.getNewX());
     y0 = findPixelXY(temps.y - mouvement.getNewY());
     x1 = findPixelXY(temps.x);
     y1 = findPixelXY(temps.y);
     drawArrow(x0 + (x1 - x0)/2, y0 + (y1 - y0)/2, x1, y1, 0, 10, false);
  }
}

void drawPlayersInformations() {
  textAlign(LEFT);
  textFont(createFont("Arial Bold", 16));
  
  int selectedWhiteP, selectedBlackP;
  if (Player.WHITE.equals(this.player)) {
    selectedWhiteP = this.selectedPawns.size();
    selectedBlackP = 0;
  } else {
    selectedWhiteP = 0;
    selectedBlackP = this.selectedPawns.size();
  }
  fill(WHITE);
  text("Time left : " + Player.WHITE.getStringTimeLeft(), w-170, 100);
  text("Turn : " + this.turns, w-170, 120);
  text("Lost Pawns : " + (14 - this.whitePawns.size()-selectedWhiteP), w-170, 140); 
  
  fill(BLACK);
  text("Time left : " + Player.BLACK.getStringTimeLeft(), w-170, h-105);
  text("Turn : " + this.turns, w-170, h-85); 
  text("Lost Pawns : " + (14 - this.blackPawns.size()-selectedBlackP), w-170, h-65); 
}

void drawEndOfGame(final color winner) {
  fill(RED);
  textAlign(CENTER, CENTER);
  textFont(createFont("Arial Bold", 90));
  if (WHITE == winner) {
    text("WHITE WINS !", w/2, h/2-10); 
  } else if (BLACK == winner) {
    text("BLACK WINS !", w/2, h/2-10); 
  } else {
    text("DRAW !", w/2, h/2-10); 
  }
  textFont(createFont("Arial Bold", 30));
  text("Turns : " + this.turns, w/2, h/2+70); 
}

/**
 * Original method is from the following website : 
 * http://gaelbn.com/processing/2014/01/10/a_simple_way_to_draw_arrows_in_Processing.html
*/
void drawArrow(float x0, float y0, float x1, float y1, float beginHeadSize, float endHeadSize, boolean filled) {

  PVector d = new PVector(x1 - x0, y1 - y0);
  d.normalize();
  
  float coeff = 1.5;
  
  strokeCap(SQUARE);
  
  line(x0+d.x*beginHeadSize*coeff/(filled?1.0f:1.75f), 
       y0+d.y*beginHeadSize*coeff/(filled?1.0f:1.75f), 
       x1-d.x*endHeadSize*coeff/(filled?1.0f:1.75f), 
       y1-d.y*endHeadSize*coeff/(filled?1.0f:1.75f));
  
  float angle = atan2(d.y, d.x);
  
  if (filled) {
    // begin head
    pushMatrix();
    translate(x0, y0);
    rotate(angle+PI);
    triangle(-beginHeadSize*coeff, -beginHeadSize, 
             -beginHeadSize*coeff, beginHeadSize, 
             0, 0);
    popMatrix();
    // end head
    pushMatrix();
    translate(x1, y1);
    rotate(angle);
    triangle(-endHeadSize*coeff, -endHeadSize, 
             -endHeadSize*coeff, endHeadSize, 
             0, 0);
    popMatrix();
  } 
  else {
    // begin head
    pushMatrix();
    translate(x0, y0);
    rotate(angle+PI);
    strokeCap(ROUND);
    line(-beginHeadSize*coeff, -beginHeadSize, 0, 0);
    line(-beginHeadSize*coeff, beginHeadSize, 0, 0);
    popMatrix();
    // end head
    pushMatrix();
    translate(x1, y1);
    rotate(angle);
    strokeCap(ROUND);
    line(-endHeadSize*coeff, -endHeadSize, 0, 0);
    line(-endHeadSize*coeff, endHeadSize, 0, 0);
    popMatrix();
  }
}

/*****************************GUI**********************/

void showMainButtons() {
  exit_btn.setVisible(true);
  hh_btn.setVisible(true);
  hm_btn.setVisible(true);
  mm_btn.setVisible(true);
  help_btn.setVisible(true);
  om_btn.setVisible(true);
}

void showSecondaryButtons() {
  cancel_btn.setVisible(true);
  as_black_btn.setVisible(true);
  as_white_btn.setVisible(true);
}

void hideMainButtons() {
  exit_btn.setVisible(false);
  hh_btn.setVisible(false);
  hm_btn.setVisible(false);
  mm_btn.setVisible(false);
  help_btn.setVisible(false);
  om_btn.setVisible(false);
}

void hideSecondaryButtons() {
  cancel_btn.setVisible(false);
  as_black_btn.setVisible(false);
  as_white_btn.setVisible(false);
}

/******************************Utility****************/

float squareDistance(float x1, float y1, float x2, float y2) {
  return (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2);
}

float squareDistance(float x1, float y1, float z1, float x2, float y2, float z2) {
  return (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) + (z1-z2)*(z1-z2);
}

int findPixelXY(int x) {
  return (x+1)*CELL_WH-(CELL_WH/2);
}

IVector findVectorForPixel(int mousex, int mousey) {
  IVector result = new IVector(0, 0);
  result.x = (mousex/CELL_WH);
  result.y = (mousey/CELL_WH);
  return result;
}

void handleClick() {
  if (mousePressed) {
    IVector mousePos = findVectorForPixel(mouseX, mouseY);
    
    if (mouseButton == LEFT) {
        IVector pawn;
        for (int i = 0; i < this.playerPawns.size(); i++) {
          pawn = this.playerPawns.get(i);
          if (pawn.iEquals(mousePos) && this.selectedPawns.size() < 3 && !this.selectedPawns.contains(pawn) && permitSelection(this.selectedPawns, pawn)) {
            this.selectedPawns.add(pawn);
            this.playerPawns.remove(pawn);
            Collections.sort(this.selectedPawns);
            return;
          }
        }
        
        Action action;
        //Check if click occurend in a mouvement direction
        for (int i = 0; i < this.actionCells.size(); i++) {
          action = this.actionCells.get(i);
          if (mousePos.iEquals(action.position)) {
            this.ennemy.lostPawns += realiseAction(this.selectedPawns, action, this.playerPawns, this.ennemyPawns);
            this.selectedPawns.clear();
            changePlayer();
            handleDefeat(this.playerPawns.size()+this.selectedPawns.size(), this.player);
            break;
          }
        }
    } else if (mouseButton == RIGHT) {
      for (int i = 0; i < this.selectedPawns.size(); i++) {
        if (this.selectedPawns.get(i).iEquals(mousePos) && permitUnselection(mousePos)) {
          this.playerPawns.add(selectedPawns.get(i));
          this.selectedPawns.remove(i);
          break;
        }
      }
    }
  }
}

void handleWebcam() {
  blobsFound.clear();
  positionsFound.clear();
  if(cam.available()) {
    cam.read();
  }
  PImage img = cam.copy();
  img.loadPixels();
  
  int loc;
  color c;
  float r,g,b;
  boolean found;
  
  for (int i = img.width/4; i < 3*img.width/4; i++) {
    for (int j = img.height/2; j < img.height; j++) {
      loc = i + j*img.width;
      c = img.pixels[loc];
      r = red(c);
      g = green(c);
      b = blue(c);
      
      if (squareDistance(r,g,b,COLOR1[0],COLOR1[1],COLOR1[2]) < COLOR_THRESHOLD*COLOR_THRESHOLD) {
        found = false;
        for (Blob blob : blobsFound) {
          if (blob.isNear(i, j, SHAPE_THRESHOLD*SHAPE_THRESHOLD)) {
            blob.add(i, j);
            found = true;
            break;
          }
        }
        
        if (!found) {
          blobsFound.add(new Blob(i, j));
        }
      } 
    }
  }
  
  int offsetX = img.width/4, offsetY = img.height/2;
  int newCellWH = (offsetX*2)/17;
  
  for (Blob blob : blobsFound) {
    if (blob.size() > SIZE_THRESHOLD_MIN && blob.size() < SIZE_THRESHOLD_MAX && blob.isAlmostSquared()) {
      positionsFound.add(findIVectorForBlob(blob, offsetX, offsetY, newCellWH));
    }
  }
  
  if (positionsFound.size() == 14) {this.playerPawns.clear();
    this.playerPawns.addAll(positionsFound);
  }
    
  found = false;
  for (int i = 0; i < possibleNodes.size(); i++) {
    if (areIdentical(possibleNodes.get(i).newEnnemyPawns, positionsFound)) {
      found = true;
      break;
    }
  }
    
  if (found) {
    this.playerPawns.clear();
    this.playerPawns.addAll(cloneIVectorList(positionsFound));
    this.ennemyPawns.clear();
    this.ennemyPawns.addAll(cloneIVectorList(possibleNodes.get(0).newPlayerPawns));
    changePlayer();
    AI();
    changePlayer();
    handleDefeat(this.playerPawns.size(), this.player);
  }
  
}
Node previsionNode;

IVector findIVectorForBlob(final Blob b, final int offsetX, final int offsetY, final int newCellWH) {
  final IVector pos = new IVector(0, 0);
  pos.x = (b.getCenterX()-offsetX)/newCellWH;
  pos.y = (b.getCenterY()-offsetY)/newCellWH;
  return pos;
}


void keyReleased() {
  switch (key) {
    case 's' : 
    case 'S' : {
      //Save image of the current board
      saveFrame("Screenshots/"+nbreImgs+".png");
      nbreImgs++;
      loadPix = 0;
      break;
    }
    case ' ' : {
      //Pausing the game
      println("Pausing/Resuming the game.");
      if (width < 1360) break;
      playing = !playing;
      if (!playing && !endGame) {
        fill(WHITE, 180);
        textAlign(CENTER, CENTER);
        textFont(createFont("Arial Bold", 90));
        text("PAUSE !", w/2, h/2-10); 
        this.player.reduceTimeLeft(millis(), start);
      } else {
        start = millis();
      }
      break;
    }
    case 'q' :
    case 'Q' : {
      //Quits the game
      println("Quitting Game.");
      playing = false;
      endGame = false;
      surface.setSize(400, 500);
      surface.setResizable(true);
      showMainButtons(); 
      loadPix = 0;
      break;
    }
    default : {
      if (keyCode == LEFT) {
        //Cancels last move
        if (PlayerType.MACHINE.equals(this.ennemy.type)) {
          if (Player.BLACK.equals(this.player)) {
            if (this.previousBlackPositions.size() > 1) {
              this.previousBlackPositions.remove(0);
              this.previousWhitePositions.remove(0);
              this.whitePawns = cloneIVectorList(this.previousWhitePositions.get(0));
              this.blackPawns = cloneIVectorList(this.previousBlackPositions.get(0));
              this.playerPawns = this.blackPawns;
              this.ennemyPawns = this.whitePawns;
              this.selectedPawns.clear();
              turns--;
              println("Canceling last move");
            }
          } else {
            if (this.previousBlackPositions.size() > 2) {
              this.previousBlackPositions.remove(0);
              this.previousWhitePositions.remove(0);
              this.whitePawns = cloneIVectorList(this.previousWhitePositions.get(0));
              this.blackPawns = cloneIVectorList(this.previousBlackPositions.get(0));
              this.playerPawns = this.whitePawns;
              this.ennemyPawns = this.blackPawns;
              this.selectedPawns.clear();
              turns--;
              println("Canceling last move");
            }
          }
        }   
      } else if (keyCode == UP) {
        if (tree_depth < 10) {
          tree_depth++;
          println("Tree depth = " + tree_depth);
        }
      } else if (keyCode == DOWN) {
        if (tree_depth > 1) {
          tree_depth--;
          println("Tree depth = " + tree_depth);
        }
      }
    }
  }
}

boolean permitSelection(final ArrayList<IVector> selectedPawns, final IVector newPos) {    
  switch (selectedPawns.size()) {
    case 0 : return true;
    case 1 : return areHorizontal(selectedPawns.get(0), newPos) || areVertical(selectedPawns.get(0), newPos);
    case 2 : {
      IVector selected0 = selectedPawns.get(0), selected1 = selectedPawns.get(1);
      if (areHorizontal(selected0, selected1)) {
        return (areHorizontal(selected0, newPos) || areHorizontal(selected1, newPos)) &&
                (!areVertical(selected0, newPos) && !areVertical(selected1, newPos)) &&
                  (!forbidden(selected0, newPos) && !forbidden(selected1, newPos));
      } else {
        return (areVertical(selected0, newPos) || areVertical(selected1, newPos)) &&
                (!areHorizontal(selected0, newPos) && !areHorizontal(selected1, newPos)) &&
                  (!forbidden(selected0, newPos) && !forbidden(selected1, newPos));
      }
    }
    default : return false;
  }
}

boolean areVertical(final IVector pawn1, final IVector pawn2) {
  return (pawn1.y+1 == pawn2.y && (pawn1.x+1 == pawn2.x || pawn1.x-1 == pawn2.x)) || (pawn1.y-1 == pawn2.y && (pawn1.x+1 == pawn2.x || pawn1.x-1 == pawn2.x));
}

boolean areHorizontal(final IVector pawn1, final IVector pawn2) {
  return (pawn1.y == pawn2.y) && ((pawn1.x+2 == pawn2.x) || (pawn1.x-2 == pawn2.x));
}

boolean forbidden(final IVector pawn1, final IVector pawn2) {
  return (pawn1.x == pawn2.x && (pawn1.y == pawn2.y+2 || pawn1.y == pawn2.y-2)) || (pawn1.x == pawn2.x && pawn1.y == pawn2.y);
}

boolean permitUnselection(final IVector newPos) {
  if (selectedPawns.size() <= 2) return true;
  
  IVector pawn = this.selectedPawns.get(1);
  if (newPos.x == pawn.x && newPos.y == pawn.y) return false;
  
  return true;
}

void changePlayer() {
  this.player.reduceTimeLeft(millis(), start);
  if (Player.WHITE.equals(player)) {
    this.player = Player.BLACK;
    this.ennemy = Player.WHITE;
    playerPawns = this.blackPawns;
    ennemyPawns = this.whitePawns;
    turns++;
  } else {
    this.player = Player.WHITE;
    this.ennemy = Player.BLACK;
    playerPawns = this.whitePawns;
    ennemyPawns = this.blackPawns;
  }
  start = millis();
}

void handleDefeat(final int playerPawnsLeft, final Player player) {
  if (isDefeated(playerPawnsLeft)) {
    playing = false;
    endGame = true;
    if (Player.WHITE.equals(player)) winner = BLACK;
    else winner = WHITE;
  }
}

void handleNoTimeLeft() {
  playing = false;
  endGame = true;
  if (this.whitePawns.size() > this.blackPawns.size()) {
    //White Wins
    winner = WHITE;
  } else if (this.whitePawns.size() < this.blackPawns.size()) {
    //Black Wins
    winner = BLACK;
  } else {
    //Draw
    winner = RED;
  }
}

boolean isDefeated(final int playerPawnsLeft) {
  return playerPawnsLeft == PAWNS_FOR_DEFEAT;
}

ArrayList<IVector> cloneIVectorList(final ArrayList<IVector> source) {
  if (source == null) return null;
  final ArrayList<IVector> clone = new ArrayList<IVector>();
  
  for (int i = 0; i < source.size(); i++) {
    clone.add(source.get(i).clone());
  }
  
  return clone;
}

ArrayList<Node> cloneNodesList(final ArrayList<Node> source) {
  if (source == null) return null;
  final ArrayList<Node> clone = new ArrayList<Node>();
  
  for (int i = 0; i < source.size(); i++) {
    clone.add(source.get(i).clone());
  }
  
  return clone;
}
/***************************Mouvement*******************/

ArrayList<Action> possibleMouvements(final ArrayList<IVector> playerPawns, final ArrayList<IVector> ennemyPawns, 
                                        final ArrayList<IVector> selectedPawns) {
  final ArrayList<Action> actionCells = new ArrayList<Action>();
  Orientation orientation = null;
  if (selectedPawns.size() == 0) return actionCells;
  if (selectedPawns.size() >= 2) {
    //Find the orientation
    orientation = findOrientation(selectedPawns.get(0), selectedPawns.get(1));
  }
  
  Mouvement[] values = Mouvement.values();
  IVector pawn, pos;
  boolean[][] availability = new boolean[selectedPawns.size()][values.length];
  
  for (int p = 0; p < selectedPawns.size(); p++) {
    pawn = selectedPawns.get(p);
    for (int i = 0; i < values.length; i++) {
      pos = new IVector(pawn.x + values[i].getNewX(), pawn.y + values[i].getNewY());
      if (isAvailable(pos, playerPawns, ennemyPawns)) {
        //Available
        availability[p][i] = true;
      } else {
        //Not Available, check orientation of Pawns to see if an action is possible
        availability[p][i] = false;
      }
    }
  }
  
  boolean available;
  int index;
  Action action;
  for (int i = 0; i < values.length; i++) {
    available = true;
    for (int p = 0; p < selectedPawns.size(); p++) {
      available = available && availability[p][i];
    }
    
    index = findIndexForMouvingPawns(selectedPawns, values[i], orientation);
    pawn = new IVector(selectedPawns.get(index).x + values[i].getNewX(), selectedPawns.get(index).y + values[i].getNewY());
    if (available) {
      //All the selected Pawns can move in this direction.
      actionCells.add(new Action(pawn, values[i]));
    } else {
      if (isWithinBorders(pawn) && orientation != null && orientation.equals(values[i].getOrientation())) {
        //Good orientation, we test for adverse Pawns for a possible action.
        action = checkForPossibleAction(playerPawns, ennemyPawns, selectedPawns, values[i], index);
        if (action != null) actionCells.add(action);     
      }
    }
  }
  
  return actionCells;
}

boolean isAvailable(final IVector pos, final ArrayList<IVector> playerPawns, final ArrayList<IVector> ennemyPawns) {
  if (!isWithinBorders(pos)) return false;
  
  for (IVector pawn : playerPawns) {
    if (pawn.iEquals(pos)) return false;
  }
  
  for (IVector pawn : ennemyPawns) {
    if (pawn.iEquals(pos)) return false;
  }
  
  return true;
}

boolean isWithinBorders(final IVector pos) {
  //Out of bonds
  if (pos.x < 0 || pos.x >= 17 || pos.y < 0 || pos.y >= 9) return false;
  
  //Test if it is not a valid cell
  if (matrice[pos.y][pos.x] == 0) return false;
  
  return true;
}

Orientation findOrientation(final IVector pawn1, final IVector pawn2) {
  if (pawn1.y == pawn2.y) return Orientation.HORIZONTAL;
  if (pawn1.x > pawn2.x) return Orientation.VERTICAL_RL;
  return Orientation.VERTICAL_LR;
}

int findIndexForMouvingPawns(final ArrayList<IVector> selectedPawns, final Mouvement mouvement, final Orientation orientation) {
  if (orientation == null) {
    return 0;
  } else if (Orientation.HORIZONTAL.equals(orientation)) {
    if (mouvement.getNewX() == -2 || mouvement.getNewX() == -1) {
      //Mouvement LEFT|UP_LEFT|DOWN_LEFT
      return 0;
    } else {
       //Mouvement RIGHT|UP_RIGHT|DOWN_RIGHT
       return selectedPawns.size()-1;
    }
  } else {
    //Vertical Orientation
    if (mouvement.getNewY() == -1) {
      //Movement UP (LEFT|RIGHT)
      return 0;
    } else if (mouvement.getNewY() == 1) {
      //Movement DOWN (LEFT|RIGHT)
      return selectedPawns.size()-1;
    } else {
      //Mouvement LEFT|RIGHT
      return selectedPawns.size()-1;
    }
  }
}

Action checkForPossibleAction(final ArrayList<IVector> playerPawns, final ArrayList<IVector> ennemyPawns, 
                              final ArrayList<IVector> selectedPawns, final Mouvement mouvement, final int index) {
  Action action = null;
  int n = selectedPawns.size();
  int[] neighbors = new int[n];
  int[] positions = new int[n];
  IVector pawn, temps;
  boolean found;

  pawn = selectedPawns.get(index);
  
  for (int i = 1; i <= n; i++) {
    found = false;
    for (int j = 0; j < playerPawns.size(); j++) {
      temps = playerPawns.get(j);
      if (temps.x == pawn.x + i*mouvement.getNewX() && temps.y == pawn.y + i*mouvement.getNewY()) {
        neighbors[i-1] = 1;//Ally
        positions[i-1] = j;
        found = true;
        break;
      }
    }
    
    if (found) continue;
    for (int j = 0; j < ennemyPawns.size(); j++) {
      temps = ennemyPawns.get(j);
      if (temps.x == pawn.x + i*mouvement.getNewX() && temps.y == pawn.y + i*mouvement.getNewY()) {
        neighbors[i-1] = -1;//Ennemy
        positions[i-1] = j;
        found = true;
        break;
      }
    }
    
    if (!found) {
      neighbors[i-1] = 0;//Empty
      positions[i-1] = -1;
    }
  }
  
  if (neighbors[0] == 1) {
    //If an ally is blocking the way
    return null;
  } else {
    //It is an ennemy Paws (because the 1st neighbor can't be free)
    if ((selectedPawns.size() == 2 && neighbors[1] == 0) || (selectedPawns.size() == 3 && (neighbors[1] == 0 || (neighbors[1] == -1 && neighbors[2] == 0)))) {
      action = new Action(new IVector(pawn.x + mouvement.getNewX(), pawn.y + mouvement.getNewY()), mouvement);
      action.pawnsPositions = positions;
      action.pawns = new ArrayList<IVector>();
      
      for (int i = 0; i < n; i++) {
        if (neighbors[i] != -1) break;
        action.pawns.add(ennemyPawns.get(positions[i]));
      }
    }
  }
  
  return action;
}

/*******************************Action***********************/
byte realiseAction(final ArrayList<IVector> selectedPawns, final Action action,
                    final ArrayList<IVector> playerPawns, final ArrayList<IVector> ennemyPawns) {
  IVector pawn;
  for (int index = 0; index < selectedPawns.size(); index++) {
    pawn = selectedPawns.get(index);
    pawn.x = pawn.x + action.mouvement.getNewX();
    pawn.y = pawn.y + action.mouvement.getNewY();
  }
  
  for (int j = 0; j < selectedPawns.size(); j++) {
    playerPawns.add(selectedPawns.get(j));
  }
   
  if (action.pawns != null) {
    IVector temps;
    int toRemove = -1;
    for (int j = 0; j < action.pawns.size(); j++) {
      pawn = action.pawns.get(j);
      temps = ennemyPawns.get(action.pawnsPositions[j]);
      temps.x = temps.x + action.mouvement.getNewX();
      temps.y = temps.y + action.mouvement.getNewY();
                
      if (!isWithinBorders(temps)) toRemove = action.pawnsPositions[j];
    }
              
    if (toRemove != -1) {
      ennemyPawns.remove(toRemove);
      return 1;
    }
  }
  return 0;
}

boolean areIdentical(final ArrayList<IVector> pawns1, final ArrayList<IVector> pawns2) {
  boolean found;
  int i, j;
  
  for (i = 0; i < pawns1.size(); i++) {
    found = false;
    for (j = 0; j < pawns2.size(); j++) {
      if (pawns1.get(i).equals(pawns2.get(j))) {
        found = true;
        break;
      }
    }
    if (!found) return false;
  }
  
  return true;
}

boolean isRepeating(final ArrayList<IVector> playerP, final ArrayList<IVector> ennemyP, 
                    final ArrayList<ArrayList<IVector>> playerPwns, final ArrayList<ArrayList<IVector>> ennemyPwns) {
  for (int i = 0; i < playerPwns.size(); i++) {
    if (areIdentical(ennemyP, playerPwns.get(i)) && areIdentical(playerP, ennemyPwns.get(i))) return true;
  }
  
  return false;
}

/*******************************AI***********************/
int[] buildTreeNegamax(final Node father, int alpha, int beta, int coef, int level,
                        final ArrayList<ArrayList<IVector>> playerPwns, final ArrayList<ArrayList<IVector>> ennemyPwns) {
  int[] result = {0, 0, 0, 0};//0 ==> mp, 1 ==> Elagage Beta, 2 ==> Elagage Alpha, 3 ==> Position of selected Element
  if (level == 0) {
    heuristic(father);
    //Feuille
    result[0] = coef*father.gain;
    if (result[0] >= beta) {
      //Elagage Beta
      result[1] = 1;
    } else if (result[0] <= alpha) {
      //Elagage Alpha pour le père
      result[2] = 1;
    }
    result[0] = result[0]*-1;
    return result;
  } else {
    //Noeud Intermédiaire
    ArrayList<ArrayList<IVector>> selectablePawns = findPossibleSelectablePawns(father.newPlayerPawns);
    ArrayList<Action> actions;
    ArrayList<IVector> temps;
    int i, j, k, l, m;
    int[] toRemove;
    boolean found;
    
    Node node;
    
    for (i = 0; i < selectablePawns.size(); i++) {
      
      Collections.sort(selectablePawns.get(i));
      actions = possibleMouvements(father.newPlayerPawns, father.newEnnemyPawns, selectablePawns.get(i));
      if (actions.size() != 0) {
        for (j = 0; j < actions.size(); j++) {
          node = new Node(cloneIVectorList(selectablePawns.get(i)), actions.get(j));
          node.newEnnemyPawns = cloneIVectorList(father.newEnnemyPawns);
          node.newPlayerPawns = cloneIVectorList(father.newPlayerPawns);
          
          //Remove the Pawns chosen as "Selected" From the player's Pawns
          toRemove = new int[node.selectedPawns.size()];
          temps = node.selectedPawns;
          for (k = 0; k < toRemove.length; k++) {
            found = false;
            for (l = 0; l < node.newPlayerPawns.size(); l++) {
              if (temps.get(k).iEquals(node.newPlayerPawns.get(l))) {
                toRemove[k] = l;
                found = true;
                break;
              }
              if (found) break;
            }
          }
          
          Arrays.sort(toRemove);
          for (k = 0; k < toRemove.length; k++) {
            node.newPlayerPawns.remove(toRemove[k]-k);
          }
          //end here
          
          realiseAction(node.selectedPawns, node.actionUsed, node.newPlayerPawns, node.newEnnemyPawns);
          
          temps = node.newEnnemyPawns;
          node.newEnnemyPawns = node.newPlayerPawns;
          node.newPlayerPawns = temps;
          
          if (level == tree_depth && isRepeating(node.newPlayerPawns, node.newEnnemyPawns, playerPwns, ennemyPwns)) continue;
          father.addNode(node);
        }
      }
    }
    
    
    int[] tmp;
    tmp = buildTreeNegamax(father.nodes.get(0), -beta, -alpha, -1*coef, level-1, ennemyPwns, playerPwns);
    if (tmp[2] == 1) {
      //Elagage Alpha
      result[1] = 1;
      return result;
    }
    if (tmp[0] >= beta) {
      //Elagage Beta
      result[1] = 1;
      return result;
    }
    if (tmp[0] <= alpha) {
      //Elagage Alpha
      result[2] = 1;
      return result;
    }
    result[0] = tmp[0];
    result[3] = 0;
    for (m = 1; m < father.nodes.size(); m++) {
      tmp = buildTreeNegamax(father.nodes.get(m), -beta, -result[0], -1*coef, level-1, ennemyPwns, playerPwns);
      if (tmp[2] == 1) {
        //Elagage Alpha
        result[1] = 1;
        return result;
      }
      if (tmp[1] == 1) {
        //Elagage Beta au niveau du fils précédent, on l'ignore
        continue;
      }
      if (tmp[0] >= beta) {
        //Elagage Beta
        result[1] = 1;
        return result;
      }
      if (tmp[0] <= alpha) {
        //Elagage Alpha
        result[2] = 1;
        return result;
      }
      result[0] = tmp[0];
      result[3] = m;
    }
    result[0] = result[0]*-1;
    return result;
  }
}


void AI() {
   ArrayList<ArrayList<IVector>> playerPwns, ennemyPwns;
   if (Player.WHITE.equals(this.player)) {
     playerPwns = this.previousWhitePositions;
     ennemyPwns = this.previousBlackPositions;
   } else {
     playerPwns = this.previousBlackPositions;
     ennemyPwns = this.previousWhitePositions;
   }
   
   Node root = new Node(null, null), chosenNode;
   root.newPlayerPawns = cloneIVectorList(this.playerPawns);
   root.newEnnemyPawns = cloneIVectorList(this.ennemyPawns);
   root.nodes = new ArrayList<Node>();
   int[] result;
   /*
   buildTree(tree_depth, root);
   do {
     max = -1;
     result = negamax(root, -32767, 32767, 1);
     chosenNode = root.nodes.get(result[3]);
     root.nodes.remove(result[3]);
   }
   while (isRepeating(chosenNode.newPlayerPawns, chosenNode.newEnnemyPawns, playerPwns, ennemyPwns));
   */
   result = buildTreeNegamax(root, -32767, 32767, 1, tree_depth, playerPwns, ennemyPwns);
   chosenNode = root.nodes.get(result[3]);
   possibleNodes.clear();
   possibleNodes = cloneNodesList(root.nodes);
   
   playerPwns.add(0, cloneIVectorList(chosenNode.newEnnemyPawns));
   ennemyPwns.add(0, cloneIVectorList(chosenNode.newPlayerPawns));
   
   this.playerPawns.clear();
   this.playerPawns.addAll(chosenNode.newEnnemyPawns);
   this.ennemyPawns.clear();
   this.ennemyPawns.addAll(chosenNode.newPlayerPawns);
}


int manhatan(final ArrayList<IVector> pawns1, final ArrayList<IVector> pawns2) {
  int i, j, size1, size2, value;
  IVector pawn;
  
  value = 0;
  size1 = pawns1.size();
  size2 = pawns2.size();
  for (i = 0; i < size1; i++) {
    pawn = pawns1.get(i);
    for (j = 0; j < size2; j++) {
      value = value + abs(pawns2.get(j).x - pawn.x) + abs(pawns2.get(j).y - pawn.y);
    }
  }
  return 3000-value;
}

void heuristic(final Node node) {
  if (Heuristic.WITH_MANHATAN.equals(this.player.heuristic)) {
    heuristicWithManhatan(node);
  } else if (Heuristic.WITHOUT_MANHATAN.equals(this.player.heuristic)) {
    heuristicWithoutManhatan(node);
  }
}

//Without Manhatan Distance
void heuristicWithoutManhatan(final Node node) {
  node.gain =
  ((tree_depth % 2 == 0) 
    ? (this.ennemyPawns.size()-node.newEnnemyPawns.size())*10000 + (this.playerPawns.size()-node.newPlayerPawns.size())*-5000 
    : (this.ennemyPawns.size()-node.newPlayerPawns.size())*10000 + (this.playerPawns.size()-node.newEnnemyPawns.size())*-5000)
  +((node.actionUsed != null) ? ((node.actionUsed.pawns == null) ? 0 : node.actionUsed.pawns.size()*100) : 0)
  +((isDefeated(node.newPlayerPawns.size())) ? 20000 : 0);
}

//With Manhatan Distance
int max = -1;
void heuristicWithManhatan(final Node node) {
  node.gain =
  ((tree_depth % 2 == 0) 
    ? (this.ennemyPawns.size()-node.newEnnemyPawns.size())*10000 + (this.playerPawns.size()-node.newPlayerPawns.size())*-5000 
    : (this.ennemyPawns.size()-node.newPlayerPawns.size())*10000 + (this.playerPawns.size()-node.newEnnemyPawns.size())*-5000)
  +manhatan(node.newPlayerPawns, node.newEnnemyPawns)
  +((node.actionUsed != null) ? ((node.actionUsed.pawns == null) ? 0 : node.actionUsed.pawns.size()*100) : 0)
  +((isDefeated(node.newPlayerPawns.size())) ? 20000 : 0);
  if (node.gain > max) max = node.gain;
}


//Old code, non optimised, to keep to show the reasoning behind negamax's implementation during the presentation.
void buildTree(int level, Node father) {
  if (level <= 0) return;
  ArrayList<ArrayList<IVector>> selectablePawns = findPossibleSelectablePawns(father.newPlayerPawns);
  ArrayList<Action> actions;
  ArrayList<IVector> temps;
  int i, j, k, l;
  int[] toRemove;
  boolean found;
  
  Node node;
  
  for (i = 0; i < selectablePawns.size(); i++) {
    Collections.sort(selectablePawns.get(i));
    actions = possibleMouvements(father.newPlayerPawns, father.newEnnemyPawns, selectablePawns.get(i));
    if (actions.size() != 0) {
      for (j = 0; j < actions.size(); j++) {
        node = new Node(cloneIVectorList(selectablePawns.get(i)), actions.get(j));
        node.newEnnemyPawns = cloneIVectorList(father.newEnnemyPawns);
        node.newPlayerPawns = cloneIVectorList(father.newPlayerPawns);
        father.addNode(node);
        
        //Remove the Pawns chosen as "Selected" From the player's Pawns
        toRemove = new int[node.selectedPawns.size()];
        temps = node.selectedPawns;
        for (k = 0; k < toRemove.length; k++) {
          found = false;
          for (l = 0; l < node.newPlayerPawns.size(); l++) {
            if (temps.get(k).iEquals(node.newPlayerPawns.get(l))) {
              toRemove[k] = l;
              found = true;
              break;
            }
            if (found) break;
          }
        }
        
        Arrays.sort(toRemove);
        for (k = 0; k < toRemove.length; k++) {
          node.newPlayerPawns.remove(toRemove[k]-k);
        }
        //end here
        
        realiseAction(node.selectedPawns, node.actionUsed, node.newPlayerPawns, node.newEnnemyPawns);
        
        temps = node.newEnnemyPawns;
        node.newEnnemyPawns = node.newPlayerPawns;
        node.newPlayerPawns = temps;
                
        if (level-1 == 0) heuristic(father);
        else buildTree(level-1, node);
      }
    }
  }
  
  return;
}

int[] negamax(final Node node, int alpha, int beta, int coef) {
  int[] result = {0, 0, 0, 0};//0 ==> mp, 1 ==> Elagage Beta, 2 ==> Elagage Alpha, 3 ==> Position of selected Element
  if (node.nodes == null) {
    //Feuille
    result[0] = coef*node.gain;
    if (result[0] >= beta) {
      //Elagage Beta
      result[1] = 1;
    } else if (result[0] <= alpha) {
      //Elagage Alpha pour le père
      result[2] = 1;
    }
    result[0] = result[0]*-1;
    return result;
  } else {
    //Noeud Intermédiaire
    int i;
    int[] temps;
    temps = negamax(node.nodes.get(0), -beta, -alpha, -1*coef);
    if (temps[2] == 1) {
      //Elagage Alpha
      result[1] = 1;
      return result;
    }
    if (temps[0] >= beta) {
      //Elagage Beta
      result[1] = 1;
      return result;
    }
    if (temps[0] <= alpha) {
      //Elagage Alpha
      result[2] = 1;
      return result;
    }
    result[0] = temps[0];
    result[3] = 0;
    for (i = 1; i < node.nodes.size(); i++) {
      temps = negamax(node.nodes.get(i), -beta, -result[0], -1*coef);
      if (temps[2] == 1) {
        //Elagage Alpha
        result[1] = 1;
        return result;
      }
      if (temps[1] == 1) {
        //Elagage Beta au niveau du fils précédent, on l'ignore
        continue;
      }
      if (temps[0] >= beta) {
        //Elagage Beta
        result[1] = 1;
        return result;
      }
      if (temps[0] <= alpha) {
        //Elagage Alpha
        result[2] = 1;
        return result;
      }
      result[0] = temps[0];
      result[3] = i;
    }
    result[0] = result[0]*-1;
    return result;
  }
}

void testNegamax() {
  Node root = new Node(null,null), temps;
  root.addNode(new Node(null,null));
  root.addNode(new Node(null,null));
  
  temps = new Node(null,null);
  root.nodes.get(0).addNode(temps);
  temps = new Node(null,null);
  root.nodes.get(0).addNode(temps);
  
  temps = new Node(null,null);
  temps.gain = 6;
  root.nodes.get(0).nodes.get(0).addNode(temps);
  temps = new Node(null,null);
  temps.gain = 2;
  root.nodes.get(0).nodes.get(0).addNode(temps);
  
  temps = new Node(null,null);
  temps.gain = 5;
  root.nodes.get(0).nodes.get(1).addNode(temps);
  temps = new Node(null,null);
  temps.gain = 4;
  root.nodes.get(0).nodes.get(1).addNode(temps);
  
  temps = new Node(null,null);
  root.nodes.get(1).addNode(temps);
  temps = new Node(null,null);
  root.nodes.get(1).addNode(temps);
  
  temps = new Node(null,null);
  temps.gain = 4;
  root.nodes.get(1).nodes.get(0).addNode(temps);
  temps = new Node(null,null);
  temps.gain = 4;
  root.nodes.get(1).nodes.get(0).addNode(temps);
  
  temps = new Node(null,null);
  temps.gain = 7;
  root.nodes.get(1).nodes.get(1).addNode(temps);
  temps = new Node(null,null);
  temps.gain = 8;
  root.nodes.get(1).nodes.get(1).addNode(temps);
  
  println(negamax(root, -32767, 32767, 1));
}


ArrayList<ArrayList<IVector>> findPossibleSelectablePawns(final ArrayList<IVector> playerPawns) {
  ArrayList<ArrayList<IVector>> result = new ArrayList<ArrayList<IVector>>();
  ArrayList<ArrayList<IVector>> layer1 = new ArrayList<ArrayList<IVector>>();
  ArrayList<ArrayList<IVector>> layer2 = new ArrayList<ArrayList<IVector>>();
  ArrayList<IVector> list;
  IVector pawn;
  
  //Single Pawns
  int size = playerPawns.size(), i, j;
  for (i = 0; i < size; i++) {
    list = new ArrayList<IVector>();
    list.add(playerPawns.get(i));
    layer1.add(list);
  }
  
  //Dual Pawns
  int newSize = layer1.size();
  for (i = 0; i < newSize; i++) {
    for (j = 0; j < size; j++) {
      pawn = playerPawns.get(j);
      if (!layer1.get(i).contains(pawn) && permitSelection(layer1.get(i), pawn)) {
        list = new ArrayList<IVector>();
        list.addAll(layer1.get(i));
        list.add(pawn);
        layer2.add(list);
      }
    }
  }
  
  //Ternary Pawns
  newSize = layer2.size();
  for (i = 0; i < newSize; i++) {
    for (j = 0; j < size; j++) {
      pawn = playerPawns.get(j);
      if (!layer2.get(i).contains(pawn) && permitSelection(layer2.get(i), pawn)) {
        list = new ArrayList<IVector>();
        list.addAll(layer2.get(i));
        list.add(pawn);
        result.add(list);
      }
    }
  }
  
  result.addAll(layer1);
  result.addAll(layer2);
  
  return result;
}
