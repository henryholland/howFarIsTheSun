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

float chordLengthA, chordLengthB;

PVector start_intersection, end_intersection, rough_transA, rough_transB;
PVector trackA_start, trackB_start, trackA_end, trackB_end;
PVector observerA, observerB; 

PVector [] tA_bezier_cps = {
  null, null, null, null
};
PVector [] tB_bezier_cps = {
  null, null, null, null
};

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

  globe_tilt_ratio =  0.2;
  axis_rotation = 0;//0.2;

  globeX = 200;
  globeY = 550;//580;
  globeR = 70;

  sunX = 1100;
  sunY = 250;
  sunR = 200;

  venusX = 812;
  venusY = 326;

  observerA = new PVector();
  observerB = new PVector();

  start_intersection = new PVector();
  end_intersection = new PVector();

  trackA_start = new PVector();
  trackB_start = new PVector();
  trackA_end = new PVector();
  trackB_end = new PVector();

  rough_transA = new PVector();
  rough_transB = new PVector();
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
  int orbitW = 2000;
  int orbitH = 470;

  PVector orb_PtA = new PVector(sunX, sunY-(orbitH/2) + 30);
  PVector orb_PtA_ctrl = new PVector(sunX-(orbitW/2) - 200, sunY-(orbitH/2) + 30);
  PVector orb_PtB = new PVector(sunX, sunY+(orbitH/2)- 5);
  PVector orb_PtB_ctrl = new PVector(sunX-(orbitW/2) - 200, sunY+(orbitH/2)-10);

  PVector [] cps = {
    orb_PtA, orb_PtA_ctrl, orb_PtB_ctrl, orb_PtB
  };

  PVector mouse_pos = new PVector(mouseX, mouseY);
  PVector venus_pos = ClosestPointOnBezier(cps, mouse_pos, 800);
  
//  drawTransitObservation(PVector observerPos, PVector planetPos, 

    float arc_rad = PVector.dist(observerB, trackB_end) + 200;
    float ang = angleFromBetweenPVectors(venus_pos, observerB);
    rough_transB = plotVectorOnCircle(observerB.x, observerB.y, arc_rad, ang);

    //drawMarker(rough_transB.x, rough_transB.y, 2);
    stroke(0,127,0);
    //line(markerBX, markerBY, -rough_transB.x, -rough_transB.y);

    float[] lineAsArray = new float[] {
      markerBX, markerBY, rough_transB.x, rough_transB.y
    };

    float[] bezierAsArray = new float[] {
      tB_bezier_cps[0].x, tB_bezier_cps[0].y, tB_bezier_cps[1].x, tB_bezier_cps[1].y, tB_bezier_cps[2].x, tB_bezier_cps[2].y, tB_bezier_cps[3].x, tB_bezier_cps[3].y
    };
   
    float[] tArray =  intersectionLineBezier( lineAsArray, bezierAsArray );

    if (tArray.length > 0) {
      PVector pt4 = new PVector();
      pt4.x = bezierPoint(tB_bezier_cps[0].x, tB_bezier_cps[1].x, tB_bezier_cps[2].x, tB_bezier_cps[3].x, tArray[tArray.length-1]);
      pt4.y = bezierPoint(tB_bezier_cps[0].y, tB_bezier_cps[1].y, tB_bezier_cps[2].y, tB_bezier_cps[3].y, tArray[tArray.length-1]);   

      stroke(255, 0, 255);
      line(venus_pos.x, venus_pos.y, pt4.x, pt4.y);
      
      stroke(255, 0, 255);
      line(observerB.x, observerB.y, venus_pos.x, venus_pos.y);
    }
//}

  fill(0, 0, 127, 255);
  noStroke();
  ellipse(venus_pos.x, venus_pos.y, 30, 30);
    
  //draw orbital path
  noFill();
  stroke(100);
  graphics.setStroke(pen_dotted);
  bezier(orb_PtA.x, orb_PtA.y, orb_PtA_ctrl.x, orb_PtA_ctrl.y, orb_PtB_ctrl.x, orb_PtB_ctrl.y, orb_PtB.x, orb_PtB.y);
}

void drawSun() {
  float tilt = 0.2;

  float[] sunMarkerA_pos_start = plotPosOnCircle(sunX, sunY, sunR, tilt + (((markerA_angle/3) - axis_rotation) - 0.2) + PI );
  float[] sunMarkerA_pos_end = plotPosOnCircle(sunX, sunY, sunR, tilt + (-(markerA_angle/3) - axis_rotation) + 0.2 );  

  float[] sunMarkerB_pos_start = plotPosOnCircle(sunX, sunY, sunR, tilt + (((markerB_angle/6) - axis_rotation) + 0.1) + PI );
  float[] sunMarkerB_pos_end = plotPosOnCircle(sunX, sunY, sunR, tilt + (-(markerB_angle/6) - axis_rotation) - 0.1 );

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
  stroke(127);
  graphics.setStroke(pen_dashed);

  chordLengthA = PVector.dist(trackA_start, trackA_end);
  chordLengthB = PVector.dist(trackB_start, trackB_end);

  //draw transit tracks..
  //A track (lower)
  PVector tA_srt = new PVector(trackA_start.x, trackA_start.y);
  PVector tA_srt_ctrl = new PVector(tA_srt.x, tA_srt.y + (chordLengthA * globe_tilt_ratio));
  PVector tA_end_ctrl = new PVector(trackA_end.x, trackA_end.y + (chordLengthA * globe_tilt_ratio));
  PVector tA_end = new PVector(trackA_end.x, trackA_end.y);

  stroke(127);
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

  stroke(127);
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

  // find intersections  
  start_intersection = lineIntersection( markerAX, markerAY, trackA_start.x, trackA_start.y, markerBX, markerBY, trackB_start.x, trackB_start.y);
  drawMarker(start_intersection.x, start_intersection.y, 4);  
  
  end_intersection = lineIntersection(markerAX, markerAY, trackA_end.x, trackA_end.y, markerBX, markerBY, trackB_end.x, trackB_end.y);
  drawMarker(end_intersection.x, end_intersection.y, 4);

  //markers
  drawMarker(trackA_start.x, trackA_start.y, 5);
  drawMarker(trackB_start.x, trackB_start.y, 5);

  drawMarker(trackA_end.x, trackA_end.y, 4);
  drawMarker(trackB_end.x, trackB_end.y, 4);

  //PoV lines...
  stroke(115);
  graphics.setStroke(pen_hairline);

  line(markerAX, markerAY, trackA_start.x, trackA_start.y);
  line(markerAX, markerAY, trackA_end.x, trackA_end.y);

  line(markerBX, markerBY, trackB_start.x, trackB_start.y);
  line(markerBX, markerBY, trackB_end.x, trackB_end.y);
}

void drawEarth() {
  markerA_angle = angleFromMouseToCircleCentre(globeX, globeY);
  //markerA_angle = -PI/2;
  markerB_angle = 0.5;

  //upper limit
  if (markerA_angle < 0-(PI/2) + (0.8)) {//+ (axis_rotation))) {
    markerA_angle = (0-(PI/2)) + (0.8 );//+ (axis_rotation));
  }
  // lower limit
  if (markerA_angle >= -0.14) {
    markerA_angle = -0.14;
  }

  float[] markerA_pos = plotPosOnCircle(globeX, globeY, globeR, markerA_angle);
  markerAX = markerA_pos[0];
  markerAY = markerA_pos[1];

  float[] markerB_pos = plotPosOnCircle(globeX, globeY, globeR, markerB_angle);
  markerBX = markerB_pos[0];
  markerBY = markerB_pos[1];

  
  
  markerA_pos_adjusted_for_tilt = plotPosOnCircle(globeX, globeY, globeR, markerA_angle - axis_rotation);
  markerB_pos_adjusted_for_tilt = plotPosOnCircle(globeX, globeY, globeR, markerB_angle - axis_rotation);

  observerB.x = markerBX;
  observerB.y = markerBY;

  observerA.x = markerAX;
  observerA.y = markerAY;

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

float[] plotPosOnCircle(float circle_x, float circle_y, float circle_r, float marker_a) {
  float[] pos = { 
    circle_x + (cos(marker_a) * circle_r), circle_y + (sin(marker_a) * circle_r)
    };
    return pos;
}

PVector plotVectorOnCircle(float origin_x, float origin_y, float circle_r, float vector_a) {
  PVector pos = new PVector(origin_x + (cos(vector_a) * circle_r), origin_y + (sin(vector_a) * circle_r));
  return pos;
}

void drawMarker(float marker_x, float marker_y, float marker_r) {
  noStroke();
  fill(255, 0, 0);
  ellipseMode(CENTER);
  ellipse(marker_x, marker_y, marker_r * 2, marker_r * 2);
}

float angleFromBetweenPVectors(PVector v1, PVector v2) {
  float dx = v2.x - v1.x;
  float dy = v2.y - v1.y;
  return atan2(dy, dx);
}

float angleFromMouseToCircleCentre(float circle_x, float circle_y) {
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
    float x = bezierPoint(cps[0].x, cps[1].x, cps[2].x, cps[3].x, t);
    float y = bezierPoint(cps[0].y, cps[1].y, cps[2].y, cps[3].y, t);
    float dx = x - pt.x;
    float dy = y - pt.y;
    float dissq = dx*dx+dy*dy;
    if (i==0 || dissq < bestDistanceSquared) {
      bestDistanceSquared = dissq;
      bestT = t;
      result.set(x, y, 0);
    }
  }
  return result;
}

PVector lineIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) {
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

  p = (c / a) - (Math.pow(b, 2.0) / (3 * Math.pow(a, 2.0)));
  q = ((2 * Math.pow(b, 3.0)) / (27 * Math.pow(a, 3.0)))
    - ((b * c) / (3 * Math.pow(a, 2.0))) + (d / a);
  gDelta = 4 * Math.pow(p, 3.0) + 27 * Math.pow(q, 2.0);
  m = ((-q) / 2) + (0.5) * Math.sqrt(gDelta / 27);
  n = ((-q) / 2) - (0.5) * Math.sqrt(gDelta / 27);
  u = Math.pow(Math.abs(m), 1.0 / 3);
  v = Math.pow(Math.abs(n), 1.0 / 3);

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
    if (x > -1E-6 && x < 1E-6)
      x = 0.0;
    if (y > -1E-6 && y < 1E-6)
      y = 0.0;
    if (z > -1E-6 && z < 1E-6)
      z = 0.0;
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

