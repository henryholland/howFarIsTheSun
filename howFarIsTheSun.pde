import java.awt.*;
import java.awt.geom.*;

float[] dashes = {  
  4.0f, 8.0f, 4.0f, 8.0f
};

float[] dots = {  
  1.0f, 8.0f, 1.0f, 8.0f
};
Graphics2D graphics;

BasicStroke pen_dashed, pen_dotted, pen_solid, pen_hairline;

float axis_rotation;
float globe_tilt_ratio;
float globeX, globeY, globeR;
float sunX, sunY, sunR;

float markerAX, markerAY, markerBX, markerBY;
float markerA_angle, markerB_angle;
boolean markerA_dragging, markerB_dragging;

float[] markerA_pos_adjusted_for_tilt, markerB_pos_adjusted_for_tilt;

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

  //pens!
  pen_dotted = new BasicStroke(2.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER, 2.0f, dots, 0.0f);
  pen_dashed = new BasicStroke(2.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER, 4.0f, dashes, 0.0f);
  pen_solid = new BasicStroke(4.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER);
  pen_hairline = new BasicStroke(1.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER);

  //GUI vars
  markerA_dragging = markerB_dragging = false;

  globe_tilt_ratio = 0.4;
  axis_rotation = 0;//0.2;

  globeX = 200;
  globeY = 580;
  globeR = 90;

  sunX = 1200;
  sunY = 200;
  sunR = 120;
}

void draw() {
  background(127); 
  noFill();

  drawEarth();
  drawSun();
  drawVenus();
  //draw tmp screen guide
  stroke(0, 0, 255);
  graphics.setStroke(pen_hairline);
  line(1368, 0, 1368, 768);
}

void drawSun() {

  graphics.setStroke(pen_solid);
  fill(255);
  noStroke();  
  ellipse(sunX, sunY, sunR * 2, sunR * 2);

  pushMatrix();
  translate(sunX, sunY);
  rotate(axis_rotation);

  //float[] sunMarkerPos = plotMarkerPos(sunX, sunY, sunR, (markerA_angle/3) + PI);
  
  float[] sunMarkerA_pos_start = plotMarkerPos(sunX, sunY, sunR, ((markerA_angle/3) - axis_rotation) + PI );
  float[] sunMarkerA_pos_end = plotMarkerPos(sunX, sunY, sunR, (-(markerA_angle/3) - axis_rotation) );
  
  float[] sunMarkerB_pos_start = plotMarkerPos(sunX, sunY, sunR, ((markerB_angle/3) - axis_rotation) + PI );
  float[] sunMarkerB_pos_end = plotMarkerPos(sunX, sunY, sunR, (-(markerB_angle/3) - axis_rotation)  );

  
  //draw axis markers
  noFill();
  stroke(255);
  graphics.setStroke(pen_solid);
  line(0, -sunR + 5, 0, -sunR-10);
  line(0, sunR+1, 0, sunR+8);

  
  //draw transit lines
  stroke(127);
  graphics.setStroke(pen_dashed);
  
  //A track
  float sun_hack = 0.8;
  arc(0, -70, (sunR * 2) * sun_hack, ((sunR * 2)*sun_hack) * (globe_tilt_ratio - 0.05), 0, PI);    

  //B track
  float sun_hack2 = 1;

  //arc(0, 32, (sunR * 2) * sun_hack2, ((sunR * 2)*sun_hack2) * (globe_tilt_ratio + 0.2), 0+0.8, PI-0.8);
  //println(sunMarkerPos[1]- sunY);

  float chordLengthA = abs(calcChordLength(sunR, ((PI/2) + axis_rotation) - ((markerA_angle/3) + PI)));
  float chordLengthB = abs(calcChordLength(sunR, ((PI/2) + axis_rotation) - ((markerA_angle/3) + PI)));
  //line(sunMarkerA_pos_start[0] - sunX, sunMarkerA_pos_start[1] - sunY, (sunMarkerA_pos_start[0] - sunX)+ chordLengthA, sunMarkerA_pos_start[1] - sunY);
  //arc(globeX - (markerA_pos_adjusted_for_tilt[0] - (chordLengthA/2)), markerA_pos_adjusted_for_tilt[1] - globeY, chordLengthA, chordLengthA * globe_tilt_ratio, 0, PI);

  float transit_l_X = sunMarkerA_pos_start[0] - (sunX - (chordLengthA/2));
  float transit_l_Y = sunMarkerA_pos_start[1] - sunY; 
  float transit_l_w = chordLengthA;//(sunR * 2) * sun_hack2;
  float transit_l_h = chordLengthA * (globe_tilt_ratio - 0.1); //((sunR * 2) * sun_hack2) * (globe_tilt_ratio + 0.2);

  //arc(transit_l_X, transit_l_Y, transit_l_w, transit_l_h, 0 + 0.5, PI - 0.5);
  arc(transit_l_X, transit_l_Y, transit_l_w, transit_l_h, 0, PI);

  popMatrix();  

  drawMarkerHitArea(sunMarkerA_pos_start[0], sunMarkerA_pos_start[1], 8);
  drawMarkerHitArea(sunMarkerB_pos_start[0], sunMarkerB_pos_start[1], 6);
  
  drawMarkerHitArea(sunMarkerA_pos_end[0], sunMarkerA_pos_end[1], 8);
  drawMarkerHitArea(sunMarkerB_pos_end[0], sunMarkerB_pos_end[1], 6);
  
  stroke(200);
  graphics.setStroke(pen_hairline);
  
  line(markerAX, markerAY, sunMarkerA_pos_start[0], sunMarkerA_pos_start[1]);
  line(markerBX, markerBY, sunMarkerB_pos_start[0], sunMarkerB_pos_start[1]);
  
  line(markerAX, markerAY, sunMarkerA_pos_end[0], sunMarkerA_pos_end[1]);
  line(markerBX, markerBY, sunMarkerB_pos_end[0], sunMarkerB_pos_end[1]);
}

void drawVenus() {
  //draw orbital path
  stroke(100);
  noFill();
  graphics.setStroke(pen_dotted);
  //arc(783, 0, 1152, 398, 0, PI);
  ellipse(sunX, sunY, 2500, 270);
  
  //draw planet
  graphics.setStroke(pen_solid);
  ellipseMode(CENTER);
  stroke(0);
  fill(0);
  //ellipse(812, 326, 40, 40);
}

void drawEarth() {
  markerA_angle = angleFromCircleCentre(globeX, globeY);
  markerB_angle = 0.8;

  //upper limit
  if (markerA_angle < 0-(PI/2) + (0.8)) {//+ (axis_rotation))) {
    markerA_angle = (0-(PI/2)) + (0.8 );//+ (axis_rotation));
  }
  // lower limit
  if (markerA_angle >= -0.14) {
    markerA_angle = -0.14;
  }

  float[] markerA_pos = plotMarkerPos(globeX, globeY, globeR, markerA_angle);
  markerAX = markerA_pos[0];
  markerAY = markerA_pos[1];

  float[] markerB_pos = plotMarkerPos(globeX, globeY, globeR, markerB_angle);
  markerBX = markerB_pos[0];
  markerBY = markerB_pos[1];

  markerA_pos_adjusted_for_tilt = plotMarkerPos(globeX, globeY, globeR, markerA_angle - axis_rotation);
  markerB_pos_adjusted_for_tilt = plotMarkerPos(globeX, globeY, globeR, markerB_angle - axis_rotation);

  pushMatrix();
  translate(globeX, globeY);
  rotate(axis_rotation);

  //draw axis markers
  stroke(255); 
  graphics.setStroke(pen_solid);
  line(0, -globeR + 5, 0, -globeR-6);
  line(0, globeR+1, 0, globeR+6);

  //draw equator
  stroke(200);
  graphics.setStroke(pen_dotted);
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
  arc(globeX - (markerB_pos_adjusted_for_tilt[0] - (chordLengthB/2)), markerB_pos_adjusted_for_tilt[1] - globeY, chordLengthB, chordLengthB * (globe_tilt_ratio - 0.09), 0+0.2, PI-0.2);

  popMatrix();

  //draw planet
  graphics.setStroke(pen_solid);
  ellipseMode(CORNER);
  stroke(255);  
  ellipse(globeX - (globeR), globeY - (globeR), globeR * 2, globeR * 2);

  //draw marker
  drawMarkerHitArea(markerAX, markerAY, 7);
  drawMarkerHitArea(markerBX, markerBY, 7);
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

