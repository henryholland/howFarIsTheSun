import processing.core.*; 
import processing.xml.*; 

import java.awt.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class howFarIsTheSun extends PApplet {


//import java.awt.geom.*;

PFont font;
PShape s;

float[] dashes = { 4.0f, 8.0f, 4.0f, 8.0f };
float[] dots = { 1.0f, 8.0f, 1.0f, 8.0f };
float[] orbit_dash = { 100.0f, 20.0f, 10.0f, 80.0f };

int bg = color(16, 16, 32);

Graphics2D graphics;

BasicStroke pen_dashed, pen_dotted, pen_solid, pen_hairline, pen_orbit;

float axis_rotation, globe_tilt_ratio;

float globeX, globeY, globeR;
float sunX, sunY, sunR;
float venusX, venusY, venusDia;
float curr_venusT, prev_venusT, venusAccelleration, venusAccellerationMax, venusFriction; 
int venusDirection;

boolean venusDragging, venusRolling;
boolean observerADragging;
boolean observerATransiting, observerBTransiting;

float markerAX, markerAY, markerBX, markerBY;
float markerA_angle, markerB_angle;

float chordLengthA, chordLengthB;

PVector start_intersection, end_intersection, rough_transA, rough_transB;
PVector trackA_start, trackB_start, trackA_end, trackB_end;
PVector observerA, observerB;

// storing the transit start and end points on beziers
float first_A_t, last_A_t, first_B_t, last_B_t;

PVector venus_pos;

PVector [] tA_bezier_cps = {
  null, null, null, null
};
PVector [] tB_bezier_cps = {
  null, null, null, null
};

boolean markerA_dragging, markerB_dragging, venus_dragging, orbitLeft;

float[] markerA_pos_adjusted_for_tilt, markerB_pos_adjusted_for_tilt;

boolean init;

public void setup() {
  size(2732, 768);  
  frameRate(60);
  smooth();
  s = loadShape("Proxy_bot.svg");
  font = createFont("Helvetica-Bold", 18);
  textFont(font);
  graphics = ((PGraphicsJava2D) g).g2;

  //pens!
  pen_dotted = new BasicStroke(2.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER, 2.0f, dots, 0.0f);
  pen_dashed = new BasicStroke(2.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER, 4.0f, dashes, 0.0f);
  pen_solid = new BasicStroke(4.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER);
  pen_hairline = new BasicStroke(1.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER);
  pen_orbit = new BasicStroke(9.0f, BasicStroke.CAP_SQUARE, BasicStroke.JOIN_MITER);
  //GUI vars
  textFont(font, 18);
 
  init = false; 
  orbitLeft = true;
  markerA_dragging = markerB_dragging = false;
  venus_dragging = true;

  globe_tilt_ratio =  0.2f;
  axis_rotation = 0;//0.2;

  globeX = 200;
  globeY = 550;//580;
  globeR = 80;

  sunX = 1100;
  sunY = 250;
  sunR = 200;

  venusX = 812;
  venusY = 326;
  venusDia = 80;

  curr_venusT = 0.5f;
  venusAccelleration = 0;
  venusAccellerationMax = 5;
  venusFriction = 0.90f;

  observerA = new PVector(); 
  observerB = new PVector();

  observerATransiting = observerBTransiting = false;
  
  start_intersection = new PVector(); 
  end_intersection = new PVector();

  trackA_start = new PVector(); 
  trackB_start = new PVector();
  trackA_end = new PVector();   
  trackB_end = new PVector();

  rough_transA = new PVector(); 
  rough_transB = new PVector();

  venus_pos = new PVector();
  
  //calculateTransitExtremes();
}

public void drawTransitImage(int x, int y, float srt_angle, float end_angle, float t) {
    
}

public void draw() {
  frame.setLocation(0,0);
  background(bg);
  drawTransitZone();
  drawEarth();
  drawSun();
  drawVenus();
  
  if (!init) {
    calculateTransitExtremes();
    init = true;
  }
  
  drawOther();

  //draw tmp screen guide
  stroke(0, 0, 255);
  graphics.setStroke(pen_hairline);
  line(1368, 0, 1368, 768);
}

public void calculateTransitExtremes() {
  last_B_t = plotTransitExtremesOnBezier(observerB, tB_bezier_cps, false);
  last_A_t = plotTransitExtremesOnBezier(observerA, tA_bezier_cps, false);
  first_B_t = plotTransitExtremesOnBezier(observerB, tB_bezier_cps, true);
  first_A_t = plotTransitExtremesOnBezier(observerA, tA_bezier_cps, true);
}

public void drawOther() {
  rect(1368, 0, 1368, 768);
  shape(s, 10, 10, 80, 80);
}

public void mousePressed() {
  if ( overCircle(PApplet.parseInt(venus_pos.x), PApplet.parseInt(venus_pos.y), PApplet.parseInt(venusDia*2))) {
    venusDragging = true;
  }
  
  if ( overCircle(PApplet.parseInt(markerAX), PApplet.parseInt(markerAY), PApplet.parseInt(venusDia*2))) {
    observerADragging = true;
  }
}

public void mouseReleased() {
  if (venusDragging) {
    venusDragging = false;
  }
  
  if (observerADragging) {
    observerADragging = false;
  }
}

public void drawVenus() {
  int orbitW = 1800;
  int orbitH = 500;

  //left half of the orbit..
  PVector orb_PtA = new PVector(sunX, sunY-(orbitH/2) + 30);
  PVector orb_PtA_ctrl = new PVector(sunX-(orbitW/2) - 200, sunY-(orbitH/2) + 30);
  PVector orb_PtB = new PVector(sunX, sunY+(orbitH/2)- 5);
  PVector orb_PtB_ctrl = new PVector(sunX-(orbitW/2) - 200, sunY+(orbitH/2)-10 );

  //right half of the orbit..
  PVector orb2_PtA = new PVector(sunX, sunY - (orbitH/2) + 30);
  PVector orb2_PtA_ctrl = new PVector(sunX + (orbitW/2) + 200, sunY-(orbitH/2) + 30);
  PVector orb2_PtB = new PVector(sunX, sunY + (orbitH/2) - 5);
  PVector orb2_PtB_ctrl = new PVector(sunX + (orbitW/2) + 200, sunY+(orbitH/2)-10 );

  PVector [] cps_left = { orb_PtA, orb_PtA_ctrl, orb_PtB_ctrl, orb_PtB  };
  PVector [] cps_right = { orb2_PtB, orb2_PtB_ctrl, orb2_PtA_ctrl, orb2_PtA  }; 
  PVector [] cps;

  PVector mouse_pos = new PVector(mouseX, mouseY);

  if (orbitLeft) {
    cps = cps_left;
  } else {
    cps = cps_right;
  }

  text((float)venusAccelleration, 10, 50);

  if (venusDragging) {
    text("dragging", 10, 100);
    venus_pos = closestPointOnBezier(cps, mouse_pos, 800);
    curr_venusT = venus_pos.z;

    //lower slingshot
    if (!orbitLeft && ((curr_venusT > 0.02f) && (curr_venusT <= 0.5f))) {
       venusDragging = false;
       venusAccelleration = 0.1861f;
    }

    //upper slingshot
    if (orbitLeft && ((curr_venusT < 0.05f)) && ( curr_venusT >= 0.01f )){
       venusDragging = false;
       venusAccelleration = -0.12f;
    }    
    
  } else {
    venusRolling = true;    
    if (Math.abs(venusAccelleration) > .001f) {
      venusAccelleration *= venusFriction;
      text("rolling", 10, 75);
    } 
    else {
      venusRolling = false;
      venusAccelleration = 0;
      text("stopped", 10, 75);
    }
  }
  
  if (curr_venusT - prev_venusT < 0) {
    venusDirection = -1;
  } else if (curr_venusT - prev_venusT > 0) {
    venusDirection = 1;
  }
  
  text(venusDirection, 10, 145);
  
  //how switch orbit curves..
  
  //bottom, going right
  if (orbitLeft && curr_venusT >= 1 && venusDirection == 1) {
    curr_venusT = 0;
    orbitLeft = false;
  }
  //bottom, going right
  if (!orbitLeft && curr_venusT <= 0 && venusDirection == -1 ) {
      curr_venusT = 1;
      orbitLeft = true;
  }
  //top, going right
  if (!orbitLeft && curr_venusT >= 1 && venusDirection == 1 ) {
      curr_venusT = 0;
      orbitLeft = true;
  }
  
  //top, going left
  if (orbitLeft && curr_venusT <= 0 && venusDirection == -1) {
      curr_venusT = 1;
      orbitLeft = false;
  } 
 
  // choose which curve data to use...again
  if (orbitLeft) {
    cps = cps_left;
  } else {
    cps = cps_right;
  }
  
  if (orbitLeft) {
    text("left", 10, 125);
  } else {
    text("right", 10, 125); 
  }
    
  curr_venusT = curr_venusT + venusAccelleration; 
  prev_venusT = curr_venusT;
  
  text(curr_venusT, 10, 175);
  
  venus_pos.x = bezierPoint(cps[0].x, cps[1].x, cps[2].x, cps[3].x, curr_venusT);
  venus_pos.y = bezierPoint(cps[0].y, cps[1].y, cps[2].y, cps[3].y, curr_venusT);

  PVector plotA = null;
  PVector plotB = null;
  
  // calcualte points of view from observers (only if venus is in the left hand, lower part of the orbit)
  if (orbitLeft && curr_venusT > 0.5f) {
    plotA = plotTransitOnBezier( observerA, venus_pos, tA_bezier_cps);
    plotB = plotTransitOnBezier( observerB, venus_pos, tB_bezier_cps);
  }
    
  // draw points of View bg
  graphics.setStroke(pen_solid);
  if (plotB != null) {
    stroke(255, 0, 255);
    line(venus_pos.x, venus_pos.y, plotB.x, plotB.y);
  }

  if (plotA != null) {
    stroke(127, 0, 255);
    line(venus_pos.x, venus_pos.y, plotA.x, plotA.y);
  }
  
  if (plotA != null && plotB !=null) {
    stroke(255, 0, 0);
    graphics.setStroke(pen_dashed);
    line(plotB.x, plotB.y, plotA.x, plotA.y);
  }

  //draw orbital path
  noFill();
  stroke(200);
  //strokeWeight(10);
  graphics.setStroke(pen_orbit);
  bezier(orb_PtA.x, orb_PtA.y, orb_PtA_ctrl.x, orb_PtA_ctrl.y, orb_PtB_ctrl.x, orb_PtB_ctrl.y, orb_PtB.x, orb_PtB.y);
  bezier(orb2_PtA.x, orb2_PtA.y, orb2_PtA_ctrl.x, orb2_PtA_ctrl.y, orb2_PtB_ctrl.x, orb2_PtB_ctrl.y, orb2_PtB.x, orb2_PtB.y);
  
  //draw venus 
  fill(33, 209, 255, 255);
  stroke(bg);
  
  float scaled_dia;
  
  if (orbitLeft) {
    scaled_dia = venusDia-30 + (curr_venusT*60);
  } else {
    scaled_dia = venusDia-30 + ((1-curr_venusT)*60);
  }
  
  ellipse(venus_pos.x, venus_pos.y, scaled_dia, scaled_dia);
  // draw points of View fg
  graphics.setStroke(pen_solid);
  if (plotB != null) {
    stroke(255, 0, 255);
    line(observerB.x, observerB.y, venus_pos.x, venus_pos.y);
  }

  if (plotA != null) {
    stroke(127, 0, 255);
    line(observerA.x, observerA.y, venus_pos.x, venus_pos.y);
  }
}

public void drawSun() {
  float tilt = 0.1f;

  float[] sunMarkerA_pos_start = plotPosOnCircle(sunX, sunY, sunR, tilt + (((markerA_angle/3) - axis_rotation) - 0.2f) + PI );
  float[] sunMarkerA_pos_end = plotPosOnCircle(sunX, sunY, sunR, tilt + (-(markerA_angle/3) - axis_rotation) + 0.2f );  

  float[] sunMarkerB_pos_start = plotPosOnCircle(sunX, sunY, sunR, tilt + (((markerB_angle/6) - axis_rotation) + 0.1f) + PI );
  float[] sunMarkerB_pos_end = plotPosOnCircle(sunX, sunY, sunR, tilt + (-(markerB_angle/6) - axis_rotation) - 0.1f );

  trackA_start.x = sunMarkerA_pos_start[0];
  trackA_start.y = sunMarkerA_pos_start[1];

  trackB_start.x = sunMarkerB_pos_start[0];
  trackB_start.y = sunMarkerB_pos_start[1];

  trackA_end.x = sunMarkerA_pos_end[0];
  trackA_end.y = sunMarkerA_pos_end[1];

  trackB_end.x = sunMarkerB_pos_end[0];
  trackB_end.y = sunMarkerB_pos_end[1];

  //draw bg
  graphics.setStroke(pen_solid);
  fill(255);
  noStroke();  
  ellipse(sunX, sunY, sunR * 2, sunR * 2);

  //draw axis markers
  noFill();
  stroke(255);
  graphics.setStroke(pen_solid);
  line(sunX, sunY-sunR + 5, sunX, sunY-sunR-10);
  line(sunX, sunY+sunR+1, sunX, sunY+sunR+8);

  //draw transit lines
  stroke(bg);
  graphics.setStroke(pen_dashed);

  chordLengthA = PVector.dist(trackA_start, trackA_end);
  chordLengthB = PVector.dist(trackB_start, trackB_end);

  //draw transit tracks..
  //A track (lower)
  PVector tA_srt = new PVector(trackA_start.x, trackA_start.y);
  PVector tA_srt_ctrl = new PVector(tA_srt.x, tA_srt.y + (chordLengthA * globe_tilt_ratio));
  PVector tA_end_ctrl = new PVector(trackA_end.x, trackA_end.y + (chordLengthA * globe_tilt_ratio));
  PVector tA_end = new PVector(trackA_end.x, trackA_end.y);

  stroke(bg);
  noFill();
  bezier(tA_srt.x, tA_srt.y, tA_srt_ctrl.x, tA_srt_ctrl.y, tA_end_ctrl.x, tA_end_ctrl.y, tA_end.x, tA_end.y);

  drawMarker(tA_srt.x, tA_srt.y, 4);
  drawMarker(tA_srt_ctrl.x, tA_srt_ctrl.y, 4);
  drawMarker(tA_end_ctrl.x, tA_end_ctrl.y, 4);
  drawMarker(tA_end.x, tA_end.y, 4);

  tA_bezier_cps [0] = tA_srt; 
  tA_bezier_cps [1] = tA_srt_ctrl;
  tA_bezier_cps [2] = tA_end_ctrl;
  tA_bezier_cps [3] = tA_end ;

  //B track (upper)
  PVector tB_srt = new PVector(trackB_start.x, trackB_start.y);
  PVector tB_srt_ctrl = new PVector(trackB_start.x, trackB_start.y + (chordLengthB * globe_tilt_ratio));
  PVector tB_end_ctrl = new PVector(trackB_end.x, trackB_end.y + (chordLengthB * globe_tilt_ratio));
  PVector tB_end = new PVector(trackB_end.x, trackB_end.y);

  stroke(bg);
  noFill();
  bezier(tB_srt.x, tB_srt.y, tB_srt_ctrl.x, tB_srt_ctrl.y, tB_end_ctrl.x, tB_end_ctrl.y, tB_end.x, tB_end.y);

  drawMarker(tB_srt.x, tB_srt.y, 4);
  drawMarker(tB_srt_ctrl.x, tB_srt_ctrl.y, 4);
  drawMarker(tB_end_ctrl.x, tB_end_ctrl.y, 4);
  drawMarker(tB_end.x, tB_end.y, 4);

  tB_bezier_cps [0] = tB_srt; 
  tB_bezier_cps [1] = tB_srt_ctrl;
  tB_bezier_cps [2] = tB_end_ctrl;
  tB_bezier_cps [3] = tB_end ;

  //markers
  /*
  drawMarker(trackA_start.x, trackA_start.y, 5);
  drawMarker(trackB_start.x, trackB_start.y, 5);

  drawMarker(trackA_end.x, trackA_end.y, 4);
  drawMarker(trackB_end.x, trackB_end.y, 4);
  */
  
  float last_BX = bezierPoint(tB_srt.x, tB_srt_ctrl.x, tB_end_ctrl.x, tB_end.x, last_B_t);
  float last_BY = bezierPoint(tB_srt.y, tB_srt_ctrl.y, tB_end_ctrl.y, tB_end.y, last_B_t);
  drawMarker(last_BX, last_BY, 10);
  
  float last_AX = bezierPoint(tA_srt.x, tA_srt_ctrl.x, tA_end_ctrl.x, tA_end.x, last_A_t);
  float last_AY = bezierPoint(tA_srt.y, tA_srt_ctrl.y, tA_end_ctrl.y, tA_end.y, last_A_t);
  drawMarker(last_AX, last_AY, 10);
  
  float first_BX = bezierPoint(tB_srt.x, tB_srt_ctrl.x, tB_end_ctrl.x, tB_end.x, first_B_t);
  float first_BY = bezierPoint(tB_srt.y, tB_srt_ctrl.y, tB_end_ctrl.y, tB_end.y, first_B_t);
  drawMarker(first_BX, first_BY, 10);
  
  float first_AX = bezierPoint(tA_srt.x, tA_srt_ctrl.x, tA_end_ctrl.x, tA_end.x, first_A_t);
  float first_AY = bezierPoint(tA_srt.y, tA_srt_ctrl.y, tA_end_ctrl.y, tA_end.y, first_A_t);
  drawMarker(first_AX, first_AY, 10);
}

public void drawTransitZone() {
}

public void drawEarth() {
  if (observerADragging) {
    markerA_angle = angleFromMouseToCircleCentre(globeX, globeY);
    calculateTransitExtremes();
  }

  markerB_angle = 0.5f;

  //upper limit
  if (markerA_angle < 0-(PI/2) + (0.8f)) {//+ (axis_rotation))) {
    markerA_angle = (0-(PI/2)) + (0.8f );//+ (axis_rotation));
  }
  // lower limit
  if (markerA_angle >= -0.14f) {
    markerA_angle = -0.14f;
  }

  float[] markerA_pos = plotPosOnCircle(globeX, globeY, globeR, markerA_angle);
  markerAX = markerA_pos[0];
  markerAY = markerA_pos[1];

  float[] markerB_pos = plotPosOnCircle(globeX, globeY, globeR, markerB_angle);
  markerBX = markerB_pos[0];
  markerBY = markerB_pos[1];

  markerA_pos_adjusted_for_tilt = plotPosOnCircle(globeX, globeY, globeR, markerA_angle - (axis_rotation));
  markerB_pos_adjusted_for_tilt = plotPosOnCircle(globeX, globeY, globeR, markerB_angle - (axis_rotation));

  observerB.x = markerBX;
  observerB.y = markerBY;

  observerA.x = markerAX;
  observerA.y = markerAY;

  //draw axis markers
  stroke(255); 
  noFill();
  graphics.setStroke(pen_solid);
  line(globeX, globeY-(globeR + 5), globeX, globeY- (globeR-6));
  line(globeX, globeY+(globeR+1), globeX, globeY + (globeR+6));

  //draw planet
  graphics.setStroke(pen_solid);
  ellipseMode(CORNER);
  fill(bg);
  stroke(255);  
  ellipse(globeX - (globeR), globeY - (globeR), globeR * 2, globeR * 2);
  ellipseMode(CENTER);
  //draw equator
  stroke(200);
  graphics.setStroke(pen_dotted);
  arc(globeX, globeY, globeR * 2, (globeR * 2) * globe_tilt_ratio, 0, PI);

  //draw markerA lattitude
  stroke(220);
  noFill();
  graphics.setStroke(pen_dashed);
  float chordLengthA = abs(calcChordLength(globeR, ((PI/2) + axis_rotation) - (markerA_angle)));
  arc(markerA_pos_adjusted_for_tilt[0] - (chordLengthA/2), markerA_pos_adjusted_for_tilt[1], chordLengthA, chordLengthA * globe_tilt_ratio, 0, PI);

  //draw markerB lattitude
  stroke(220);
  noFill();
  graphics.setStroke(pen_dashed);
  float chordLengthB = abs(calcChordLength(globeR, ((PI/2) + axis_rotation) - markerB_angle));
  arc(markerB_pos_adjusted_for_tilt[0] - (chordLengthB/2), markerB_pos_adjusted_for_tilt[1], chordLengthB, chordLengthB * (globe_tilt_ratio - 0.09f), 0+0.2f, PI-0.2f);

  //draw marker
  drawMarker(markerAX, markerAY, 7);
  drawMarker(markerBX, markerBY, 7);
}

/*static public void main(String args[]) {
  Frame frame = new Frame("testing");
  frame.setUndecorated(true);
  // The name "sketch_name" must match the name of your program
  PApplet applet = new howFarIsTheSun();
  frame.add(applet);

  frame.setBounds(0, 0, 2732, 768); 
  frame.setVisible(true);

  applet.init();
}*/

public void init(){
  frame.removeNotify();
  frame.setUndecorated(true);
  frame.addNotify();
  super.init();
}


public float calcChordLength(float circle_r, float intersect_a) {
  return (circle_r * 2) * (sin(intersect_a));
}

public float[] plotPosOnCircle(float circle_x, float circle_y, float circle_r, float marker_a) {
  float[] pos = { 
    circle_x + (cos(marker_a) * circle_r), circle_y + (sin(marker_a) * circle_r)
    };
    return pos;
}

public PVector plotVectorOnCircle(float origin_x, float origin_y, float circle_r, float vector_a) {
  PVector pos = new PVector(origin_x + (cos(vector_a) * circle_r), origin_y + (sin(vector_a) * circle_r));
  return pos;
}

public void drawMarker(float marker_x, float marker_y, float marker_r) {
  noStroke();
  fill(255, 0, 0);
  ellipseMode(CENTER);
  ellipse(marker_x, marker_y, marker_r * 2, marker_r * 2);
}

public float angleFromBetweenPVectors(PVector v1, PVector v2) {
  float dx = v2.x - v1.x;
  float dy = v2.y - v1.y;
  return atan2(dy, dx);
}

public float angleFromMouseToCircleCentre(float circle_x, float circle_y) {
  float dx = mouseX - circle_x;
  float dy = mouseY - circle_y;
  return atan2(dy, dx);
}

public boolean overCircle(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } 
  else {
    return false;
  }
}

public float plotTransitExtremesOnBezier(PVector observerPos, PVector[] transitBezier, boolean firstExtreme) {
  PVector curveEndPos = transitBezier[3];
  float arc_rad = PVector.dist(observerPos, curveEndPos) + 200;
  float ang;
  
  if (firstExtreme){
    ang = 1;
  } else {
    ang = 0;
  }
  
  PVector scan = new PVector();
  float[] lineAsArray;
  float[] bezierAsArray;
  float[] intersections;
  boolean located = false;
  float result = -1;
  int loops = 0;
  while (ang < PI) {
    loops++;
    float this_ang;
    if (firstExtreme){
      this_ang = 0 + ang;
    } else {
      this_ang = 2 - ang;
    }
    scan = plotVectorOnCircle(observerPos.x, observerPos.y, arc_rad, this_ang);
    lineAsArray =  new float[] { observerPos.x, observerPos.y, scan.x, scan.y };
    bezierAsArray = new float[] { transitBezier[0].x, transitBezier[0].y, transitBezier[1].x, transitBezier[1].y, transitBezier[2].x, transitBezier[2].y, transitBezier[3].x, transitBezier[3].y };
    intersections = intersectionLineBezier( lineAsArray, bezierAsArray );
    
    if (intersections.length > 0) {
      result = intersections[intersections.length -1];
      
      located = true;
      break;
    } else {
      ang += 0.001f;
    }
  }
  
  if (located) {
    println(loops);
    return result;
  } else {
    
    println("COULDNT FIND AN INTERSECTION - RETURNING NULL");
    return -1;
  }
}

public PVector plotTransitOnBezier(PVector observerPos, PVector planetPos, PVector[] transitBezier) {

  PVector curveEndPos = transitBezier[3];
  float arc_rad = PVector.dist(observerPos, curveEndPos) + 200;
  float ang = angleFromBetweenPVectors(planetPos, observerPos);
  rough_transB = plotVectorOnCircle(observerPos.x, observerPos.y, arc_rad, ang);

  float[] lineAsArray = new float[] { 
    observerPos.x, observerPos.y, rough_transB.x, rough_transB.y
  };

  float[] bezierAsArray = new float[] { 
    transitBezier[0].x, transitBezier[0].y, 
    transitBezier[1].x, transitBezier[1].y, 
    transitBezier[2].x, transitBezier[2].y, 
    transitBezier[3].x, transitBezier[3].y
  };

  float[] intersections =  intersectionLineBezier( lineAsArray, bezierAsArray );

  PVector plot = new PVector();

  if (intersections.length > 0) {
    float lastIntersection = intersections[intersections.length -1];
    plot.x = bezierPoint(transitBezier[0].x, transitBezier[1].x, transitBezier[2].x, transitBezier[3].x, lastIntersection);
    plot.y = bezierPoint(transitBezier[0].y, transitBezier[1].y, transitBezier[2].y, transitBezier[3].y, lastIntersection);
  } 
  else {
    plot = null;
  }
  return plot;
}


/**
 Derived from: ClosestPointOnCurve, Dave Bollinger, circa 2006, revised 9/2010
 numerical approximation by linearly subdividing the curves into a given number of segments
 
 * Returns the closest point on a bezier curve relative to a search location.
 * This is only an approximation, by subdividing the curve a given number of times.
 * More subdivisions gives a better approximation but takes longer, and vice versa.
 * No concern is given to handling multiple equidistant points on the curve - the
 *   first encountered equidistant point on the subdivided curve is returned.
 *
 * @param cps    array of four PVectors that define the control points of the curve
 * @param pt     the search-from location
 * @param ndivs  how many segments to subdivide the curve into
 * @returns      PVector containing closest subdivided point on curve, with t in the z...
 */

public PVector closestPointOnBezier(PVector [] cps, PVector pt, int ndivs) {
  PVector result = new PVector();
  float bestDistanceSquared = 0;
  float bestT = 0;
  for (int i=0; i<=ndivs; i++) {
    float t = (float)(i) / (float)(ndivs);
    float x = bezierPoint(cps[0].x, cps[1].x, cps[2].x, cps[3].x, t);
    float y = bezierPoint(cps[0].y, cps[1].y, cps[2].y, cps[3].y, t);
    float dx = x - pt.x;
    float dy = y - pt.y;
    float dissq = dx*dx+dy*dy;
    if (i==0 || dissq < bestDistanceSquared) {
      bestDistanceSquared = dissq;
      bestT = t;
      result.set(x, y, t);
    }
  }
  return result;
}

public PVector lineIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
  float bx = x2 - x1;
  float by = y2 - y1;
  float dx = x4 - x3;
  float dy = y4 - y3; 
  float b_dot_d_perp = bx*dy - by*dx;
  if (b_dot_d_perp == 0) {
    return null;
  }
  float cx = x3-x1; 
  float cy = y3-y1;
  float t = (cx*dy - cy*dx) / b_dot_d_perp; 

  return new PVector(x1+t*bx, y1+t*by);
}

/* Borrowed from CurveSplit by frankie zafe */
// Find collision point between straight lines and bezier curve. 
// The script only considers one curve at the time, 
// can be easily extends to all curves on the scene.
/* http://www.openprocessing.org/visuals/?visualID=8680 */

public float[] intersectionLineBezier( float[] lp, float[] cp ) {
  float[] li = computeLine(lp[0], lp[1], lp[2], lp[3]);
  double a = (double) ( -(li[0]*cp[0])+(3*li[0]*cp[2])-(3*li[0]*cp[4])+(li[0]*cp[6])+cp[1]-(3*cp[3])+(3*cp[5])-cp[7] );
  double b = (double) ( (3*li[0]*cp[0])-(6*li[0]*cp[2])+(3*li[0]*cp[4])-(3*cp[1])+(6*cp[3])-(3*cp[5]) );
  double c = (double) ( -(3*li[0]*cp[0])+(3*li[0]*cp[2])+(3*cp[1])-(3*cp[3]) );
  double d = (double) ( (li[0]*cp[0])-cp[1]+li[1] );
  return thirdDegree(a, b, c, d);
}


public static float[] thirdDegree( double a, double b, double c, double d ) {

  float[] out;

  double gDelta, x, y, z, im, re, u, v, p, q, m, n, theta, k;
  x=-1;
  y=-1;
  z=-1;

  //System.out.println("\nl'equation a resoudre est : " + a + "x^3+" + b + "x^2+" + c + "x+" + d + "=0\n");

  p = (c / a) - (Math.pow(b, 2.0f) / (3 * Math.pow(a, 2.0f)));
  q = ((2 * Math.pow(b, 3.0f)) / (27 * Math.pow(a, 3.0f)))
    - ((b * c) / (3 * Math.pow(a, 2.0f))) + (d / a);
  gDelta = 4 * Math.pow(p, 3.0f) + 27 * Math.pow(q, 2.0f);
  m = ((-q) / 2) + (0.5f) * Math.sqrt(gDelta / 27);
  n = ((-q) / 2) - (0.5f) * Math.sqrt(gDelta / 27);
  u = Math.pow(Math.abs(m), 1.0f / 3);
  v = Math.pow(Math.abs(n), 1.0f / 3);

  if (gDelta > 0) {
    if (m < 0)
      u = -u;
    if (n < 0)
      v = -v;
    x = u + v;
    x += (-b) / (3 * a);
    re = (-x) / 2;
    im = (Math.sqrt(3) / 2) * (u - v);
    re += (-b) / (3 * a);
    //System.out.println("1 racine reelle:\n x = " + x + "");
    //System.out.println("2 racines complexes:\n" + " y = " + re + "-" + im + "i , z = " + re + "+" + im + "i");
  }

  else if (gDelta == 0) {
    if (b == 0 & c == 0 && d == 0)
      System.out.println("1 racine reelle de multiplicite 3:\n x = y = z = 0 ");
    else {
      x = (3 * q) / p;
      x += (-b) / (3 * a);
      y = (-3 * q) / (2 * p);
      y += (-b) / (3 * a);
      //System.out.println("1 racine reelle simple:\n x = " + x + "");
      //System.out.println("1 racine reelle double:\n y = z = " + y + "");
    }
  } 
  else {
    k = (3 * q) / ((2 * p) * Math.sqrt((-p) / 3));
    theta = Math.acos(k);
    x = 2 * Math.sqrt((-p) / 3) * Math.cos(theta / 3);
    y = 2 * Math.sqrt((-p) / 3)
      * Math.cos((theta + 2 * Math.PI) / 3);
    z = 2 * Math.sqrt((-p) / 3)
      * Math.cos((theta + 4 * Math.PI) / 3);
    if (x > -1e-6f && x < 1e-6f)
      x = 0.0f;
    if (y > -1e-6f && y < 1e-6f)
      y = 0.0f;
    if (z > -1e-6f && z < 1e-6f)
      z = 0.0f;
    x += (-b) / (3 * a);
    y += (-b) / (3 * a);
    z += (-b) / (3 * a);
    //System.out.println("3 racines reelles:\n x = " + x + " , y = " + y + " , z = " + z + "");
  }

  ArrayList results = new ArrayList();

  if ( x >= 0 && x <= 1 ) { 
    results.add((float) x);
  }  
  if ( y >= 0 && y <= 1 ) { 
    results.add((float) y);
  }  
  if ( z >= 0 && z <= 1 ) { 
    results.add((float) z);
  }

  out = new float[results.size()];
  for (int i=0; i<results.size(); i++) { 
    out[i] = Float.parseFloat(results.get(i).toString());
  }

  return out;
}

public static float[] computeLine(float x1, float y1, float x2, float y2) {
  float[] out = new float[2];
  out[0] = (y1 - y2) / (x1 - x2);
  out[1] = y1 - (out[0] * x1);
  return out;
}

  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "howFarIsTheSun" });
  }
}
