import java.awt.*;
import java.awt.geom.*;

float[] dashes = {  
  4.0f, 8.0f, 4.0f, 8.0f
};
Graphics2D graphics;

BasicStroke pen_dashed, pen_solid, pen_hairline;

float axis_rotation;
float globe_tilt_ratio;
float globeX, globeY, globeR;
float sunX, sunY, sunR;

float markerAX, markerAY, markerBX, markerBY;
float markerA_angle, markerB_angle;
boolean markerA_dragging, markerB_dragging;

static public void main(String args[]) {
  Frame frame = new Frame("testing");
  frame.setUndecorated(true);
  // The name "sketch_name" must match the name of your program
  PApplet applet = new howFarIsTheSun();
  frame.add(applet);
  
  frame.setBounds(0, 0, 2048, 768); 
  frame.setVisible(true);
  
  applet.init();
}

void setup() {
  size(2048, 768);  
  frameRate(60);
  smooth();

  graphics = ((PGraphicsJava2D) g).g2;
  pen_dashed = new BasicStroke(2.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER, 4.0f, dashes, 0.0f);
  pen_solid = new BasicStroke(4.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER);
  pen_hairline = new BasicStroke(1.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER);

  markerA_dragging = markerB_dragging = false;

  globe_tilt_ratio = 0.4;
  axis_rotation = 0.2;
  globeX = 200;
  globeY = 580;
  globeR = 90;
}

void draw() {
  background(127); 
  noFill();

  drawEarth();
  //drawSun();
  
}

//void drawSun() {
//  //draw  sun
//  graphics.setStroke(pen_solid);
//  ellipseMode(CORNER);
//  stroke(255);  
//  ellipse(sX - (globeR), globeY - (globeR), globeR * 2, globeR * 2);
//}

void drawEarth() {
  markerA_angle = angleFromCircleCentre(globeX, globeY);
  markerB_angle = 0.7;
  
  //upper limit
  if (markerA_angle < (0-(PI/2) + (axis_rotation + axis_rotation))) {
    markerA_angle = (0-(PI/2)) + (axis_rotation + axis_rotation);
  }
  // lower limit
  if (markerA_angle >= (axis_rotation) ) {
    markerA_angle = (axis_rotation);
  }

  float[] markerA_pos = plotMarkerPos(globeX, globeY, globeR, markerA_angle);
  markerAX = markerA_pos[0];
  markerAY = markerA_pos[1];
  
  float[] markerA_pos_adjusted_for_tilt = plotMarkerPos(globeX, globeY, globeR, markerA_angle - axis_rotation);
  float[] markerB_pos_adjusted_for_tilt = plotMarkerPos(globeX, globeY, globeR, markerB_angle - axis_rotation);
  
  pushMatrix();
  translate(globeX, globeY);
  rotate(axis_rotation);

  //draw axis markers
  stroke(255); 
  graphics.setStroke(pen_solid);
  line(0, -globeR + 5, 0, -globeR-10);
  line(0, globeR+1, 0, globeR+8);
  
  //draw equator
  stroke(204, 102, 0);
  graphics.setStroke(pen_dashed);
  arc(0, 0, globeR * 2, (globeR * 2) * globe_tilt_ratio, 0, PI);

  //draw markerA lattitude
  stroke(220);
  noFill();
  graphics.setStroke(pen_dashed);
  float chordLengthA = abs(calcChordLength(globeR, ((PI/2) + axis_rotation) - (markerA_angle)));
  arc(globeX - (markerA_pos_adjusted_for_tilt[0] - (chordLengthA/2)), markerA_pos_adjusted_for_tilt[1] - globeY, chordLengthA, chordLengthA * globe_tilt_ratio, 0, PI);
 
  //draw markerB lattitude
  stroke(220);
  noFill();
  graphics.setStroke(pen_dashed);
  float chordLengthB = abs(calcChordLength(globeR, ((PI/2) + axis_rotation) - markerB_angle));
  arc(globeX - (markerB_pos_adjusted_for_tilt[0] - (chordLengthB/2)), markerB_pos_adjusted_for_tilt[1] - globeY, chordLengthB, chordLengthB * (globe_tilt_ratio + 0.01) , 0, PI);
 
  popMatrix();

  //draw tmp screen guide
  stroke(0, 0, 255);
  graphics.setStroke(pen_hairline);
  line(1368, 0, 1368, 768);

  //draw  planet
  graphics.setStroke(pen_solid);
  ellipseMode(CORNER);
  stroke(255);  
  ellipse(globeX - (globeR), globeY - (globeR), globeR * 2, globeR * 2);

  //draw marker
  drawMarkerHitArea(markerAX, markerAY, 7);
}

float calcChordLength(float circle_r, float intersect_a) {
  return (circle_r * 2) * (sin(intersect_a));
}

float[] plotMarkerPos(float circle_x, float circle_y, float circle_r, float marker_a) {
  float[] pos = { 
    circle_x + (cos(marker_a) * circle_r), circle_y + (sin(marker_a) * circle_r)
    };
    return pos;
}

void drawMarkerHitArea(float marker_x, float marker_y, float marker_r) {
  noStroke();
  fill(255, 0, 0);
  ellipseMode(CENTER);
  ellipse(marker_x, marker_y, marker_r * 2, marker_r * 2);
}

float angleFromCircleCentre(float circle_x, float circle_y) {
  float dx = mouseX - circle_x;
  float dy = mouseY - circle_y;
  return atan2(dy, dx);
}

boolean overCircle(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } 
  else {
    return false;
  }
}

