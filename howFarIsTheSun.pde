//import processing.opengl.*;
import java.awt.*;
//import java.awt.geom.*;

PFont font;
PShape title_gfx, sun_gfx, earth_gfx;

float[] hairline_dashes = { 
  2.0f, 4.0f, 2.0f, 4.0f
};

float[] dashes = { 
  4.0f, 8.0f, 4.0f, 8.0f
};
float[] dots = { 
  1.0f, 8.0f, 1.0f, 8.0f
};
float[] orbit_dash = { 
  100.0f, 20.0f, 10.0f, 80.0f
};

color bg = color(16, 16, 32);

Graphics2D graphics;

BasicStroke pen_dashed, pen_dotted, pen_solid, pen_hairline, pen_hairline_dashed, pen_orbit;

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

float curr_transitA_pos, curr_transitB_pos;

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

void setup() {
  size(2732, 768, JAVA2D);  
  frameRate(60);
  smooth();

  title_gfx = loadShape("gfx/title.svg");
  sun_gfx = loadShape("gfx/sun.svg");
  earth_gfx = loadShape("gfx/earth.svg");

  font = createFont("Helvetica-Bold", 14);
  //textFont(font);
  graphics = ((PGraphicsJava2D) g).g2;

  //pens!
  pen_dotted = new BasicStroke(2.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER, 2.0f, dots, 0.0f);
  pen_dashed = new BasicStroke(2.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER, 4.0f, dashes, 0.0f);
  pen_solid = new BasicStroke(4.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER);
  pen_hairline = new BasicStroke(1.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER);
  pen_hairline_dashed = new BasicStroke(1.0f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_MITER, 1.0f, hairline_dashes, 0.0f);
  pen_orbit = new BasicStroke(9.0f, BasicStroke.CAP_SQUARE, BasicStroke.JOIN_MITER);
  //GUI vars
  textFont(font, 14);

  init = false; 
  orbitLeft = true;
  markerA_dragging = markerB_dragging = false;
  venus_dragging = true;

  globe_tilt_ratio =  0.2;
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

  curr_venusT = 0.5;
  venusAccelleration = 0;
  venusAccellerationMax = 5;
  venusFriction = 0.90;

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
}

void drawTransitImage(int x, int y, int mode) {
  float tilt = 0.2;
  fill(255);
  noStroke();
  float t1, t2, angle1, angle2;
  float transitImage_radius = 0;
  float transit_duration1, transit_duration2;
  float transit_start_ang1, transit_start_ang2;
  float transit_end_ang1, transit_end_ang2;
  float sun_gfx_scalar = 0;
  t1 = t2 =0;
  transit_duration1 = transit_duration2 = 0;
  transit_start_ang1 = transit_start_ang2 = 0;
  transit_end_ang1 = transit_end_ang2 = 0;
  int dotSize = 0;
  // 
  switch(mode) {
  case 1:
    angle1 = markerA_angle;
    t1 = curr_transitA_pos;
    transitImage_radius = 20;
    sun_gfx_scalar = 0.4;
    dotSize = 8;
    break;
  case 2:
    angle1 = markerB_angle;
    t1 = curr_transitB_pos;
    transitImage_radius = 20;
    sun_gfx_scalar = 0.4;
    dotSize = 8;
    break;
  case 3:
    angle1 = markerA_angle;
    t1 = curr_transitA_pos;
    angle2 = markerB_angle;
    t2 = curr_transitB_pos;
    transitImage_radius = 40;
    sun_gfx_scalar = 0.8;
    dotSize = 9;
    break;
  }

  //transforms
  pushMatrix();
  translate(x, y);
  ((PGraphicsJava2D) g).skewY(PI/40);

  //draw box
  float boxWidth = transitImage_radius * 1.65;
  float boxHeight = transitImage_radius * 1.85;

  if (mode == 3) {
    fill(167, 167, 167, 127);
    rect(-(boxWidth)+21, -(boxHeight) -21, boxWidth *2, boxHeight *2);
    shapeMode(CENTER);
    shape(sun_gfx, 21, -21, sunR * sun_gfx_scalar, sunR * sun_gfx_scalar);

    fill(127, 127, 127, 200);
  } 
  else {
    fill(127);
  }

  rect(-(boxWidth), -(boxHeight), boxWidth *2, boxHeight *2);

  //draw sun
  noStroke();
  fill(255);
  shapeMode(CENTER);
  shape(sun_gfx, 0, 0, sunR * sun_gfx_scalar, sunR * sun_gfx_scalar);
  ellipseMode(CENTER);
  ellipse(0, 0, transitImage_radius*2, transitImage_radius*2);

  //draw transit & text
  String s = null;
  switch(mode) {
  case 1:
    s = "A";
    transit_duration1 = last_A_t;
    transit_start_ang1 = tilt + (((markerA_angle/3) - axis_rotation) - 0.2) + PI;
    transit_end_ang1 =  tilt + (-(markerA_angle/3) - axis_rotation) + 0.2;
    break;
  case 2:
    s = "B";
    transit_duration1 = last_B_t;      
    transit_start_ang1 = tilt + (((markerB_angle/6) - axis_rotation) - 0.1) + PI ;
    transit_end_ang1 =  tilt + (-(markerB_angle/6) - axis_rotation) + 0.1;
    break;
  case 3:
    s = "COMBINED";
    transit_duration1 = last_A_t;
    transit_start_ang1 = tilt + (((markerA_angle/3) - axis_rotation) - 0.2) + PI;
    transit_end_ang1 =  tilt + (-(markerA_angle/3) - axis_rotation) + 0.2;

    transit_duration2 = last_B_t;
    transit_start_ang2 = tilt + (((markerB_angle/6) - axis_rotation) - 0.1) + PI ;
    transit_end_ang2 =  tilt + (-(markerB_angle/6) - axis_rotation) + 0.1;
    break;
  }

  textFont(font, 14);
  textAlign(LEFT);
  text(s, -(boxWidth) + 1, -(boxHeight) + 13);

  float transit_progress1 = t1 * (1/transit_duration1);
  float transit_progress2 = t2 * (1/transit_duration2);

  PVector transit_start1 = plotVectorOnCircle( 0, 0, transitImage_radius, transit_start_ang1 );
  PVector transit_end1 = plotVectorOnCircle( 0, 0, transitImage_radius, transit_end_ang1 ); 
  PVector transit_start2 = plotVectorOnCircle( 0, 0, transitImage_radius, transit_start_ang2 );
  PVector transit_end2 = plotVectorOnCircle( 0, 0, transitImage_radius, transit_end_ang2 ); 

  graphics.setStroke(pen_hairline_dashed);
  stroke(200);
  line(transit_start1.x, transit_start1.y, transit_end1.x, transit_end1.y);
  line(transit_start2.x, transit_start2.y, transit_end2.x, transit_end2.y);

  if (transit_progress1 >= 0) {
    PVector dotPos = new PVector();
    dotPos.x = transit_start1.x + ((transit_end1.x - transit_start1.x) * transit_progress1);
    dotPos.y = transit_start1.y + ((transit_end1.y - transit_start1.y) * transit_progress1);

    noStroke();
    fill(10);
    ellipseMode(CENTER);
    ellipse(dotPos.x, dotPos.y, dotSize, dotSize);
  }

  if (transit_progress2 >= 0) {
    PVector dotPos = new PVector();
    dotPos.x = transit_start2.x + ((transit_end2.x - transit_start2.x) * transit_progress2);
    dotPos.y = transit_start2.y + ((transit_end2.y - transit_start2.y) * transit_progress2);

    noStroke();
    fill(10);
    ellipseMode(CENTER);
    ellipse(dotPos.x, dotPos.y, dotSize, dotSize);
  }
  popMatrix();
}

void drawSolarParallax(float x, float y) {

  float dia_earth_x = x - 400;
  float dia_earth_y = y;
  float dia_earth_r = 40;

  float dia_venus_x = x- 80;
  float dia_venus_y = y;
  float dia_venus_r = 20;

  float dia_sun_x = x + 400;
  float dia_sun_y = y;  
  float dia_sun_r = 80;    

  //draw earth
  graphics.setStroke(pen_solid);

  fill(bg);
  stroke(255);  
  ellipseMode(CORNER);
  ellipse(dia_earth_x - (dia_earth_r), dia_earth_y - (dia_earth_r), dia_earth_r * 2, dia_earth_r * 2);
  shapeMode(CENTER);
  shape(earth_gfx, dia_earth_x, dia_earth_y, (dia_earth_r * 3.02), (dia_earth_r * 3.02));

  //draw sun
  ellipseMode(CENTER);
  shape(sun_gfx, dia_sun_x, dia_sun_y, dia_sun_r* 4, dia_sun_r * 4);
  graphics.setStroke(pen_solid);
  fill(255);
  noStroke();
  float actual_sun_diameter = dia_sun_r * 1.8;
  ellipse(dia_sun_x, dia_sun_y, actual_sun_diameter, actual_sun_diameter);

  //calc markers
  float[] markerA_pos = plotPosOnCircle(dia_earth_x, dia_earth_y, dia_earth_r, markerA_angle);
  float[] markerB_pos = plotPosOnCircle(dia_earth_x, dia_earth_y, dia_earth_r, markerB_angle);

  PVector markerA = new PVector(markerA_pos[0], markerA_pos[1]);
  PVector venus = new PVector(dia_venus_x, dia_venus_y);
  PVector target = new PVector(dia_sun_x, dia_sun_y);

  PVector sun_bez_a = new PVector(dia_sun_x - (actual_sun_diameter/2), dia_sun_y);
  PVector sun_bez_b = new PVector(dia_sun_x, dia_sun_y + (actual_sun_diameter/2));

  PVector sun_bez_a_ctrl = new PVector(sun_bez_a.x, sun_bez_a.y + (actual_sun_diameter/3.5));
  PVector sun_bez_b_ctrl = new PVector(sun_bez_b.x -(actual_sun_diameter/3.5), sun_bez_b.y );

  float distfromObserverToVenus = PVector.dist(markerA, target);
  float angle = angleFromBetweenPVectors(markerA, venus);

  float[] targetPos = plotPosOnCircle(venus.x, venus.y, distfromObserverToVenus/1.5, angle);
  float[] lineAsArray = {
    venus.x, venus.y, targetPos[0], targetPos[1]
  };
  float[] bezierAsArray = {
    sun_bez_a.x, sun_bez_a.y, sun_bez_a_ctrl.x, sun_bez_a_ctrl.y, sun_bez_b_ctrl.x, sun_bez_b_ctrl.y, sun_bez_b.x, sun_bez_b.y
  };

  float [] intersections = intersectionLineBezier( lineAsArray, bezierAsArray );
  float[] sunMarkerB_pos_start = plotPosOnCircle(dia_sun_x, dia_sun_y, dia_sun_r-7, (markerB_angle/9) + PI + 0.4 );

  PVector corrected_marker_pos = new PVector();

  if (intersections.length > 0) {
    corrected_marker_pos.x = bezierPoint(bezierAsArray[0], bezierAsArray[2], bezierAsArray[4], bezierAsArray[6], intersections[0]);
    corrected_marker_pos.y = bezierPoint(bezierAsArray[1], bezierAsArray[3], bezierAsArray[5], bezierAsArray[7], intersections[0]);
  }

  noFill();
  stroke(255);

  line(markerA.x, markerA.y, corrected_marker_pos.x, corrected_marker_pos.y);
  line(markerB_pos[0], markerB_pos[1], sunMarkerB_pos_start[0], sunMarkerB_pos_start[1]);

  //draw observers
  drawMarker(markerA_pos[0], markerA_pos[1], 4);
  drawMarker(markerB_pos[0], markerB_pos[1], 4);

  //sun markers
  drawMarker(corrected_marker_pos.x, corrected_marker_pos.y, 4);
  drawMarker(sunMarkerB_pos_start[0], sunMarkerB_pos_start[1], 4);

  //draw venus
  ellipseMode(CENTER);
  graphics.setStroke(pen_solid);
  fill(33, 209, 255, 255);
  noStroke();
  ellipse(dia_venus_x, dia_venus_y, dia_venus_r * 1.8, dia_venus_r * 1.8);
}

void draw() {
  frame.setLocation(0, 0);
  background(bg);
  drawEarth();
  drawSun();
  drawVenus();

  if (!init) {
    calculateTransitExtremes();
    init = true;
  }

  drawScreen2BG();
  drawLabels();

  /*  drawTransitImage(1857, 550, 1);
   drawTransitImage(1857, 640, 2);
   drawTransitImage(2207, 600, 3);*/

  drawTransitImage(1857, 250, 1);
  drawTransitImage(1857, 340, 2);
  drawTransitImage(2207, 300, 3);
  drawSolarParallax(1366 + (1366/2), 580);

  //draw tmp screen guide
  stroke(0, 0, 255);
  graphics.setStroke(pen_hairline);
  line(1368, 0, 1368, 768);
  line(1368 + (1368/2), 0, 1368 + (1368/2), 768);
}

void calculateTransitExtremes() {
  last_B_t = plotTransitExtremesOnBezier(observerB, tB_bezier_cps, false);
  last_A_t = plotTransitExtremesOnBezier(observerA, tA_bezier_cps, false);
  first_B_t = plotTransitExtremesOnBezier(observerB, tB_bezier_cps, true);
  first_A_t = plotTransitExtremesOnBezier(observerA, tA_bezier_cps, true);
}

void drawScreen2BG() {
  noStroke();
  fill(bg);
  rect(1368, 0, 1368, 768);
}

void drawLabels() {
  shapeMode(CORNER);
  //  shape(title_gfx, 1368 - (title_gfx.width*2) + 10, 768 - (title_gfx.height*2) + 10, title_gfx.width*2, title_gfx.height*2);
  shape(title_gfx, 1368 + 10, 10, title_gfx.width*2, title_gfx.height*2);
  fill(255);
  textFont(font, 20);

  float hint1_x = 1368 - 500;
  float hint1_y = 768 -  130;
  text("Try dragging Venus around its orbit.", hint1_x, hint1_y);

  strokeWeight(5);
  stroke(150);
  noFill();

  arrow(hint1_x + 400, hint1_y - 30, hint1_x + 400, hint1_y - 120); 
  arc(hint1_x + 375, hint1_y - 31, 50, 50, 0, PI/2);

  text("Try moving this \nobserver around.", 70, 375);
  arrow(observerA.x, 400, observerA.x, observerA.y - 50);
  arc(observerA.x - 25, 400, 50, 50, TWO_PI-PI/2, TWO_PI);

  textFont(font, 14);
  strokeWeight(4);
  textAlign(RIGHT);
  text("If we use two different\n views of the transit...", 1366 + 420, 285);
  line(1366 + 550, 255, 1366 + (1366/2), 295);
  line(1366 + 550, 340, 1366 + (1366/2), 295); 
  arrow(1366 + (1366/2), 295, 1366 + (1366/2) + 60, 295);
  textAlign(LEFT);
  text("...we can measure the\ndistance between the tracks.", 1366 + (1366/2) + 280, 285);

  line(1366 + (1366/2) + 500, 290, 1366 + (1366/2) + 560, 290);
  arc(1366 + (1366/2) + 560, 315, 50, 50, TWO_PI-PI/2, TWO_PI);
  line(1366 + (1366/2) + 585, 315, 1366 + (1366/2) + 585, 558);
  arc(1366 + (1366/2) + 560, 558, 50, 50, 0, PI/2);
  arrow(1366 + (1366/2) + 560, 583, 1366 + (1366/2) + 540, 583);
}

void arrow(float x1, float y1, float x2, float y2) {
  line(x1, y1, x2, y2);
  pushMatrix();
  translate(x2, y2);
  float a = atan2(x1-x2, y2-y1);
  rotate(a);
  line(0, 0, -10, -10);
  line(0, 0, 10, -10);
  popMatrix();
} 

void mousePressed() {
  if ( overCircle(int(venus_pos.x), int(venus_pos.y), int(venusDia*2))) {
    venusDragging = true;
  }

  if ( overCircle(int(markerAX), int(markerAY), int(venusDia*2))) {
    observerADragging = true;
  }
}

void mouseReleased() {
  if (venusDragging) {
    venusDragging = false;
  }

  if (observerADragging) {
    observerADragging = false;
  }
}

void checkVenusDirection() {

  if (curr_venusT - prev_venusT < 0) {
    venusDirection = -1;
  } 
  else if (curr_venusT - prev_venusT > 0) {
    venusDirection = 1;
  }
  //text(venusDirection, 10, 145);
}

void drawVenus() {
  int orbitW = 1800;
  int orbitH = 500;
  int orbitY_offset = -30;

  //left half of the orbit..
  PVector orb_PtA = new PVector(sunX, sunY + orbitY_offset -(orbitH/2) );
  PVector orb_PtA_ctrl = new PVector(sunX + orbitY_offset-(orbitW/2) - 200, sunY-(orbitH/2));
  PVector orb_PtB = new PVector(sunX, sunY + orbitY_offset +(orbitH/2)- 5);
  PVector orb_PtB_ctrl = new PVector(sunX-(orbitW/2) - 200, sunY + orbitY_offset +(orbitH/2)-10 );

  //right half of the orbit..
  PVector orb2_PtA = new PVector(sunX, sunY + orbitY_offset - (orbitH/2) );
  PVector orb2_PtA_ctrl = new PVector(sunX + (orbitW/2) + 200, sunY + orbitY_offset + orbitY_offset-(orbitH/2));
  PVector orb2_PtB = new PVector(sunX, sunY + orbitY_offset + (orbitH/2) - 5);
  PVector orb2_PtB_ctrl = new PVector(sunX + (orbitW/2) + 200, sunY + orbitY_offset +(orbitH/2)-10 );

  PVector [] cps_left = { 
    orb_PtA, orb_PtA_ctrl, orb_PtB_ctrl, orb_PtB
  };

  PVector [] cps_right = { 
    orb2_PtB, orb2_PtB_ctrl, orb2_PtA_ctrl, orb2_PtA
  }; 

  PVector [] cps;

  PVector mouse_pos = new PVector(mouseX, mouseY);

  if (orbitLeft) {
    cps = cps_left;
  } 
  else {
    cps = cps_right;
  }

  //text((float)venusAccelleration, 10, 50);

  if (venusDragging) {
    //text("dragging", 10, 100);
    venus_pos = closestPointOnBezier(cps, mouse_pos, 800);
    curr_venusT = venus_pos.z;
    checkVenusDirection();
    //lower slingshot
    if (!orbitLeft && ((curr_venusT > 0.02) && (curr_venusT <= 0.5)) && venusDirection == 1) {
      venusDragging = false;
      venusAccelleration = 0.1861;
    }

    //upper slingshot
    //    if (orbitLeft && ((curr_venusT < 0.05)) && ( curr_venusT >= 0.01) && venusDirection == -1) {
    if (orbitLeft && ((curr_venusT < 0.2)) && venusDirection == -1) {
      venusDragging = false;
      venusAccelleration = -0.148;
    }

    if (!orbitLeft && (curr_venusT > 0.05)) {
      venusDragging = false;
      venusAccelleration = 0.1821;
    }
  }  
  else {
    venusRolling = true;

    if (Math.abs(venusAccelleration) > .001) {
      venusAccelleration *= venusFriction;
      //text("rolling", 10, 75);
    } 
    else {
      venusRolling = false;
      venusAccelleration = 0;
      //text("stopped", 10, 75);
    }
    checkVenusDirection();
  }

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
  } 
  else {
    cps = cps_right;
  }

  //debug
  /*
  if (orbitLeft) {
   text("left", 10, 125);
   } 
   else {
   text("right", 10, 125);
   }
   */
  curr_venusT = curr_venusT + venusAccelleration; 
  prev_venusT = curr_venusT;

  //text(curr_venusT, 10, 175);

  venus_pos.x = bezierPoint(cps[0].x, cps[1].x, cps[2].x, cps[3].x, curr_venusT);
  venus_pos.y = bezierPoint(cps[0].y, cps[1].y, cps[2].y, cps[3].y, curr_venusT);

  PVector plotA = null;
  PVector plotB = null;

  // calcualte points of view from observers (only if venus is in the left hand, lower part of the orbit)
  if (orbitLeft && curr_venusT > 0.5) {

    curr_transitA_pos = findTransitOnBezier( observerA, venus_pos, tA_bezier_cps);
    curr_transitB_pos = findTransitOnBezier( observerB, venus_pos, tB_bezier_cps);

    if (curr_transitA_pos != -1) plotA = plotPositionOnBezier(curr_transitA_pos, tA_bezier_cps);
    if (curr_transitB_pos != -1) plotB = plotPositionOnBezier(curr_transitB_pos, tB_bezier_cps);
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

  // draw line between the transits...
  /*if (plotA != null && plotB !=null) {
   stroke(255, 0, 0);
   graphics.setStroke(pen_dashed);
   line(plotB.x, plotB.y, plotA.x, plotA.y);
   }*/

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
  } 
  else {
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
  
  drawMarker(observerA.x, observerA.y, 8);
  drawMarker(observerB.x, observerB.y, 8);
  
  fill(33, 209, 255, 255);
  noStroke();
  ellipse(venus_pos.x, venus_pos.y, scaled_dia/1.2, scaled_dia/1.5);
}

void drawSun() {
  float tilt = 0.1;

  float[] sunMarkerA_pos_start = plotPosOnCircle(sunX, sunY, sunR, tilt + (((markerA_angle/3) - axis_rotation) - 0.2) + PI );
  float[] sunMarkerA_pos_end = plotPosOnCircle(sunX, sunY, sunR, tilt + (-(markerA_angle/3) - axis_rotation) + 0.2 );  

  float[] sunMarkerB_pos_start = plotPosOnCircle(sunX, sunY, sunR, tilt + (((markerB_angle/8) - axis_rotation) + 0.1) + PI );
  float[] sunMarkerB_pos_end = plotPosOnCircle(sunX, sunY, sunR, tilt + (-(markerB_angle/8) - axis_rotation) - 0.1 );

  trackA_start.x = sunMarkerA_pos_start[0];
  trackA_start.y = sunMarkerA_pos_start[1];

  trackB_start.x = sunMarkerB_pos_start[0];
  trackB_start.y = sunMarkerB_pos_start[1];

  trackA_end.x = sunMarkerA_pos_end[0];
  trackA_end.y = sunMarkerA_pos_end[1];

  trackB_end.x = sunMarkerB_pos_end[0];
  trackB_end.y = sunMarkerB_pos_end[1];

  shapeMode(CENTER);
  shape(sun_gfx, sunX, sunY, sunR * 3.8, sunR * 3.8);

  //draw bg
  graphics.setStroke(pen_solid);
  fill(255);
  //stroke(bg);  
  noStroke();
  ellipse(sunX, sunY, sunR * 2, sunR * 2);

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

  /*drawMarker(tA_srt.x, tA_srt.y, 4);
   drawMarker(tA_srt_ctrl.x, tA_srt_ctrl.y, 4);
   drawMarker(tA_end_ctrl.x, tA_end_ctrl.y, 4);
   drawMarker(tA_end.x, tA_end.y, 4);*/

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

  /*
  drawMarker(tB_srt.x, tB_srt.y, 4);
   drawMarker(tB_srt_ctrl.x, tB_srt_ctrl.y, 4);
   drawMarker(tB_end_ctrl.x, tB_end_ctrl.y, 4);
   drawMarker(tB_end.x, tB_end.y, 4);
   */

  tB_bezier_cps [0] = tB_srt; 
  tB_bezier_cps [1] = tB_srt_ctrl;
  tB_bezier_cps [2] = tB_end_ctrl;
  tB_bezier_cps [3] = tB_end ;

  float last_BX = bezierPoint(tB_srt.x, tB_srt_ctrl.x, tB_end_ctrl.x, tB_end.x, last_B_t);
  float last_BY = bezierPoint(tB_srt.y, tB_srt_ctrl.y, tB_end_ctrl.y, tB_end.y, last_B_t);

  float last_AX = bezierPoint(tA_srt.x, tA_srt_ctrl.x, tA_end_ctrl.x, tA_end.x, last_A_t);
  float last_AY = bezierPoint(tA_srt.y, tA_srt_ctrl.y, tA_end_ctrl.y, tA_end.y, last_A_t);

  float first_BX = bezierPoint(tB_srt.x, tB_srt_ctrl.x, tB_end_ctrl.x, tB_end.x, first_B_t);
  float first_BY = bezierPoint(tB_srt.y, tB_srt_ctrl.y, tB_end_ctrl.y, tB_end.y, first_B_t);

  float first_AX = bezierPoint(tA_srt.x, tA_srt_ctrl.x, tA_end_ctrl.x, tA_end.x, first_A_t);
  float first_AY = bezierPoint(tA_srt.y, tA_srt_ctrl.y, tA_end_ctrl.y, tA_end.y, first_A_t);
}

void drawEarth() {
  if (observerADragging) {
    markerA_angle = angleFromMouseToCircleCentre(globeX, globeY);
    calculateTransitExtremes();
  }

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

  shapeMode(CENTER);
  shape(earth_gfx, globeX, globeY, (globeR * 3.02), (globeR * 3.02) );

  //draw equator
  stroke(200);
  noFill();
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
  arc(markerB_pos_adjusted_for_tilt[0] - (chordLengthB/2), markerB_pos_adjusted_for_tilt[1], chordLengthB, chordLengthB * (globe_tilt_ratio - 0.09), 0+0.2, PI-0.2);

  //draw marker
  //drawMarker(markerAX, markerAY, 7);
  //drawMarker(markerBX, markerBY, 7);
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

public void init() {
  frame.removeNotify();
  frame.setUndecorated(true);
  frame.addNotify();
  super.init();
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

float plotTransitExtremesOnBezier(PVector observerPos, PVector[] transitBezier, boolean firstExtreme) {
  PVector curveEndPos = transitBezier[3];
  float arc_rad = PVector.dist(observerPos, curveEndPos) + 200;
  float ang;

  if (firstExtreme) {
    ang = 1;
  } 
  else {
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
    if (firstExtreme) {
      this_ang = 0 + ang;
    } 
    else {
      this_ang = 2 - ang;
    }
    scan = plotVectorOnCircle(observerPos.x, observerPos.y, arc_rad, this_ang);
    lineAsArray =  new float[] { 
      observerPos.x, observerPos.y, scan.x, scan.y
    };
    bezierAsArray = new float[] { 
      transitBezier[0].x, transitBezier[0].y, transitBezier[1].x, transitBezier[1].y, transitBezier[2].x, transitBezier[2].y, transitBezier[3].x, transitBezier[3].y
    };
    intersections = intersectionLineBezier( lineAsArray, bezierAsArray );

    if (intersections.length > 0) {
      result = intersections[intersections.length -1];

      located = true;
      break;
    } 
    else {
      ang += 0.001;
    }
  }

  if (located) {
    println(loops);
    return result;
  } 
  else {

    println("COULDNT FIND AN INTERSECTION - RETURNING NULL");
    return -1;
  }
}

float findTransitOnBezier(PVector observerPos, PVector planetPos, PVector[] transitBezier) {
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
  float lastIntersection = -1;
  if (intersections.length > 0) {
    lastIntersection = intersections[intersections.length -1];
  } 
  return lastIntersection;
}

PVector plotPositionOnBezier(float position, PVector[] transitBezier) {
  PVector plot = new PVector();
  plot.x = bezierPoint(transitBezier[0].x, transitBezier[1].x, transitBezier[2].x, transitBezier[3].x, position);
  plot.y = bezierPoint(transitBezier[0].y, transitBezier[1].y, transitBezier[2].y, transitBezier[3].y, position);
  return plot;
}

PVector plotTransitOnBezier(PVector observerPos, PVector planetPos, PVector[] transitBezier) {

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

PVector closestPointOnBezier(PVector [] cps, PVector pt, int ndivs) {
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

