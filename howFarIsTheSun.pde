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

PVector start_intersection, end_intersection, trackA_start, trackB_start, rough_transA, rough_transB;

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
  
  start_intersection = new PVector();
  end_intersection = new PVector();
  trackA_start = new PVector();
  trackB_start = new PVector();
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
  int orbitW = 2500;
  int orbitH = 270;
  
  PVector orb_PtA = new PVector(sunX, sunY-(orbitH/2) + 30);
  PVector orb_PtA_ctrl = new PVector(sunX-(orbitW/2) - 200, sunY-(orbitH/2) + 30);
  PVector orb_PtB = new PVector(sunX, sunY+(orbitH/2)- 5);
  PVector orb_PtB_ctrl = new PVector(sunX-(orbitW/2) - 200, sunY+(orbitH/2)-10);
  
  PVector [] cps = {orb_PtA, orb_PtA_ctrl, orb_PtB_ctrl, orb_PtB};
  PVector mouse_pos = new PVector(mouseX, mouseY);
  PVector venus_pos = ClosestPointOnBezier(cps, mouse_pos, 800);
  
  noStroke();
  fill(0, 0, 127, 100);
  
  boolean transiting = false;
  
  if ((venus_pos.x > start_intersection.x) && (venus_pos.x < end_intersection.x)) {
    transiting = true;
    fill(0, 0, 127, 255);
  }
  
  if (transiting) {
    float total_length = dist(start_intersection.x, start_intersection.y, end_intersection.x, end_intersection.y);
    float curr_length = dist(start_intersection.x, start_intersection.y, venus_pos.x, venus_pos.y);
    float percent = curr_length/total_length;
    rough_transA.x = trackA_start.x + (chordLengthA*percent);
    rough_transA.y = trackA_start.y;
    ellipse(venus_pos.x, venus_pos.y, 40, 40);
  }
  
  ellipse(rough_transA.x, rough_transA.y, 10, 10);
  noFill();
  
  //ellipse(sunX, sunY, orbitW, orbitH);
  stroke(100, 0, 0);

  //draw orbital path
  stroke(100);
  noFill();
  graphics.setStroke(pen_dotted);
  bezier(orb_PtA.x, orb_PtA.y, orb_PtA_ctrl.x,orb_PtA_ctrl.y, orb_PtB_ctrl.x, orb_PtB_ctrl.y, orb_PtB.x, orb_PtB.y);

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

  //
  trackA_start.x = sunMarkerA_pos_start[0];
  trackA_start.y = sunMarkerA_pos_start[1];
  trackB_start.x = sunMarkerB_pos_start[0];
  trackB_start.y = sunMarkerB_pos_start[1];


  //draw axis markers
  noFill();
  stroke(255);
  graphics.setStroke(pen_solid);
  line(0, -sunR + 5, 0, -sunR-10);
  line(0, sunR+1, 0, sunR+8);

  //draw transit lines
  stroke(127);
  graphics.setStroke(pen_dashed);


  //TO DO - these need to be available to other functions... global probably..
  float chordLengthA = abs(calcChordLength(sunR, ((PI/2) + axis_rotation) - ((markerA_angle/3) + PI)));
  float chordLengthB = abs(calcChordLength(sunR, ((PI/2) + axis_rotation) - ((markerB_angle/3) + PI)));

  //A track
  PVector tA_srt = new PVector(sunMarkerB_pos_start[0] - (sunX ), sunMarkerB_pos_start[1] - sunY);
  PVector tA_srt_ctrl = new PVector(tA_srt.x, tA_srt.y + (chordLengthB * (globe_tilt_ratio - 0.2)));
  PVector tA_end_crtl = new PVector(tA_srt.x + chordLengthB, tA_srt.y + (chordLengthB * (globe_tilt_ratio - 0.2)));
  PVector tA_end = new PVector(tA_srt.x + chordLengthB, tA_srt.y);
  
  stroke(0,255,0);
  bezier(tA_srt.x, tA_srt.y, tA_srt_ctrl.x, tA_srt_ctrl.y, tA_end_crtl.x, tA_end_crtl.y, tA_end.x, tA_end.y);
   
//  float transitA_l_X = sunMarkerB_pos_start[0] - (sunX - (chordLengthB/2));
//  float transitA_l_Y = sunMarkerB_pos_start[1] - sunY; 
//  float transitA_l_w = chordLengthB;
//  float transitA_l_h = chordLengthB * (globe_tilt_ratio - 0.2);
//  stroke(0,255,0);
//  arc(transitA_l_X, transitA_l_Y, transitA_l_w, transitA_l_h, 0, PI);
     

  //B track
  float transit_l_X = sunMarkerA_pos_start[0] - (sunX - (chordLengthA/2));
  float transit_l_Y = sunMarkerA_pos_start[1] - sunY; 
  float transit_l_w = chordLengthA;
  float transit_l_h = chordLengthA * (globe_tilt_ratio - 0.2);
  stroke(127,127,0); 
  arc(transit_l_X, transit_l_Y, transit_l_w, transit_l_h, 0, PI);

  ellipse(transit_l_X, transit_l_Y, transit_l_w, transit_l_h);


  popMatrix();  

  // find intersections
  //put a marker where markerA's view on tA_srt is and 
  start_intersection = lineIntersection(markerAX, markerAY, sunMarkerA_pos_start[0], sunMarkerA_pos_start[1], 
                                                markerBX, markerBY, sunMarkerB_pos_start[0], sunMarkerB_pos_start[1]);
  end_intersection = lineIntersection(markerAX, markerAY, sunMarkerA_pos_end[0], sunMarkerA_pos_end[1], 
                                                markerBX, markerBY, sunMarkerB_pos_end[0], sunMarkerB_pos_end[1]);


  drawMarker(start_intersection.x, start_intersection.y, 4);
  drawMarker(end_intersection.x, end_intersection.y, 4);
  
//  PVector [] cps = {tA_srt, tA_srt_ctrl, tA_end_crtl, tA_end};
//  PVector mouse_pos = new PVector(mouseX, mouseY);
//  PVector venus_pos = ClosestPointOnBezier(cps, mouse_pos, 300);

  //markers
  drawMarker(sunMarkerA_pos_start[0], sunMarkerA_pos_start[1], 4);
  drawMarker(sunMarkerB_pos_start[0], sunMarkerB_pos_start[1], 10);

  drawMarker(sunMarkerA_pos_end[0], sunMarkerA_pos_end[1], 4);
  drawMarker(sunMarkerB_pos_end[0], sunMarkerB_pos_end[1], 4);

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
  //markerA_angle = -PI/2;
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
  drawMarker(markerAX, markerAY, 7);
  drawMarker(markerBX, markerBY, 7);
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

void drawMarker(float marker_x, float marker_y, float marker_r) {
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

PVector lineIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4)
{
  float bx = x2 - x1;
  float by = y2 - y1;
  float dx = x4 - x3;
  float dy = y4 - y3; 
  float b_dot_d_perp = bx*dy - by*dx;
  if(b_dot_d_perp == 0) {
    return null;
  }
  float cx = x3-x1; 
  float cy = y3-y1;
  float t = (cx*dy - cy*dx) / b_dot_d_perp; 
 
  return new PVector(x1+t*bx, y1+t*by); 
}


