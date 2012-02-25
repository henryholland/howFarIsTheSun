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
float venusX, venusY;

float markerAX, markerAY, markerBX, markerBY;
float markerA_angle, markerB_angle;
boolean markerA_dragging, markerB_dragging, venus_dragging;

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
  venus_dragging = true;
  
  globe_tilt_ratio = 0.4;
  axis_rotation = 0;//0.2;

  globeX = 200;
  globeY = 580;
  globeR = 90;

  sunX = 1200;
  sunY = 200;
  sunR = 120;
  
  venusX = 812;
  venusY = 326;
}

void draw() {
  background(127); 
  drawEarth();
  drawSun();
  drawVenus();

  //draw tmp screen guide
  stroke(0, 0, 255);
  graphics.setStroke(pen_hairline);
  line(1368, 0, 1368, 768);
}

void drawVenus() {
  //draw orbital path
  stroke(100);
  noFill();
  graphics.setStroke(pen_dotted);
  //arc(783, 0, 1152, 398, 0, PI);
  
  int orbitW = 2500;
  int orbitH = 270;
  
  PVector orb_PtA = new PVector(sunX, sunY-(orbitH/2));
  PVector orb_PtA_ctrl = new PVector(sunX-(orbitW/2), sunY-(orbitH/2));
  PVector orb_PtB = new PVector(sunX, sunY+(orbitH/2));
  PVector orb_PtB_ctrl = new PVector(sunX-(orbitW/2), sunY+(orbitH/2));
  
  PVector [] cps = {orb_PtA, orb_PtA_ctrl, orb_PtB_ctrl, orb_PtB};
  PVector mouse_pos = new PVector(mouseX, mouseY);
  
  PVector venus_pos = ClosestPointOnBezier(cps, mouse_pos, 300);
  noStroke();
  fill(0, 0, 127, 100);
  ellipse(venus_pos.x, venus_pos.y, 40, 40);
  noFill();
  
  ellipse(sunX, sunY, orbitW, orbitH);
  stroke(100, 0, 0);
  //draw bezier version
  bezier(orb_PtA.x, orb_PtA.y, orb_PtA_ctrl.x,orb_PtA_ctrl.y, orb_PtB_ctrl.x, orb_PtB_ctrl.y, orb_PtB.x, orb_PtB.y);

  //draw planet
  //graphics.setStroke(pen_solid);
  ellipseMode(CENTER);
  noStroke();
  fill(0, 0, 0, 30);
  ellipse(812, 326, 40, 40);

  /*
  float t = angleFromCircleCentre(sunX, sunY);

  int a = 2500/2; // major axis of ellipse
  int b = 270/2; // minor axis of ellipse

  int x = (int)(sunX + a * cos(t));
  
  int y = (int)(sunY + b * sin(t));
  
  fill(0, 127, 0);
  ellipse(x, y, 40, 40);
  */
  
}

void drawSun() {
  //draw bg
  graphics.setStroke(pen_solid);
  fill(255);
  noStroke();  
  ellipse(sunX, sunY, sunR * 2, sunR * 2);

  pushMatrix();
  translate(sunX, sunY);
  rotate(axis_rotation);

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

  float chordLengthA = abs(calcChordLength(sunR, ((PI/2) + axis_rotation) - ((markerA_angle/3) + PI)));
  float chordLengthB = abs(calcChordLength(sunR, ((PI/2) + axis_rotation) - ((markerB_angle/3) + PI)));

  //A track
  float transitA_l_X = sunMarkerB_pos_start[0] - (sunX - (chordLengthB/2));
  float transitA_l_Y = sunMarkerB_pos_start[1] - sunY; 
  float transitA_l_w = chordLengthB;
  float transitA_l_h = chordLengthB * (globe_tilt_ratio - 0.2);
  arc(transitA_l_X, transitA_l_Y, transitA_l_w, transitA_l_h, 0, PI);
  //  float sun_hack = 0.8;
  //  arc(0, -70, (sunR * 2) * sun_hack, ((sunR * 2)*sun_hack) * (globe_tilt_ratio - 0.05), 0, PI);    

  //B track
  float transit_l_X = sunMarkerA_pos_start[0] - (sunX - (chordLengthA/2));
  float transit_l_Y = sunMarkerA_pos_start[1] - sunY; 
  float transit_l_w = chordLengthA;
  float transit_l_h = chordLengthA * (globe_tilt_ratio - 0.2);
  arc(transit_l_X, transit_l_Y, transit_l_w, transit_l_h, 0, PI);

  ellipse(transit_l_X, transit_l_Y, transit_l_w, transit_l_h);

  popMatrix();  

  //markers
  drawMarkerHitArea(sunMarkerA_pos_start[0], sunMarkerA_pos_start[1], 4);
  drawMarkerHitArea(sunMarkerB_pos_start[0], sunMarkerB_pos_start[1], 4);

  drawMarkerHitArea(sunMarkerA_pos_end[0], sunMarkerA_pos_end[1], 4);
  drawMarkerHitArea(sunMarkerB_pos_end[0], sunMarkerB_pos_end[1], 4);

  //PoV lines...
  stroke(200);
  graphics.setStroke(pen_hairline);

  line(markerAX, markerAY, sunMarkerA_pos_start[0], sunMarkerA_pos_start[1]);
  line(markerBX, markerBY, sunMarkerB_pos_start[0], sunMarkerB_pos_start[1]);

  line(markerAX, markerAY, sunMarkerA_pos_end[0], sunMarkerA_pos_end[1]);
  line(markerBX, markerBY, sunMarkerB_pos_end[0], sunMarkerB_pos_end[1]);
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
  noFill();
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

/**
ClosestPointOnCurve, Dave Bollinger, circa 2006, revised 9/2010
numerical approximation by linearly subdividing the curves into a given number of segments
*/


/**
 * Returns the closest point on a bezier curve relative to a search location.
 * This is only an approximation, by subdividing the curve a given number of times.
 * More subdivisions gives a better approximation but takes longer, and vice versa.
 * No concern is given to handling multiple equidistant points on the curve - the
 *   first encountered equidistant point on the subdivided curve is returned.
 *
 * @param cps    array of four PVectors that define the control points of the curve
 * @param pt     the search-from location
 * @param ndivs  how many segments to subdivide the curve into
 * @returns      PVector containing closest subdivided point on curve
 */
PVector ClosestPointOnBezier(PVector [] cps, PVector pt, int ndivs) {
  PVector result = new PVector();
  float bestDistanceSquared = 0;
  float bestT = 0;
  for (int i=0; i<=ndivs; i++) {
    float t = (float)(i) / (float)(ndivs);
    float x = bezierPoint(cps[0].x,cps[1].x,cps[2].x,cps[3].x,t);
    float y = bezierPoint(cps[0].y,cps[1].y,cps[2].y,cps[3].y,t);
    float dx = x - pt.x;
    float dy = y - pt.y;
    float dissq = dx*dx+dy*dy;
    if (i==0 || dissq < bestDistanceSquared) {
      bestDistanceSquared = dissq;
      bestT = t;
      result.set(x,y,0);
    }
  }
  return result;
}


