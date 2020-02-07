import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import ddf.minim.*; 
import ddf.minim.analysis.*; 
import oscP5.*; 
import netP5.*; 
import ddf.minim.*; 
import ddf.minim.analysis.*; 
import java.lang.Math; 
import processing.video.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Laser_Pointer_instrument extends PApplet {

ArrayList<Sparks> sprks;






Minim minim;
AudioInput in;
AudioTerrainGrid grid;
WebCamVisualizer webCam;
OscP5 oscP5;


public void setup() {
  //size(600, 600, P3D);
  
  sprks = new ArrayList<Sparks>();
  
  minim = new Minim(this);
  in = minim.getLineIn();
  
  grid = new AudioTerrainGrid(in);
  
  webCam = new WebCamVisualizer(this);
  
  oscP5 = new OscP5(this, 5005);
  
  
}

public void draw() {
  background(0);
  
  // terrain
  float volume = grid.update();
  background(volume/300, volume/300, volume/300);
  grid.display();
  
  
  
  //webcam
  webCam.display();
  
  
  for (int i = sprks.size()-1; i>=0; i--) {
    Sparks spk = sprks.get(i);
    spk.update();
    spk.display();
    if (spk.is_dead()) {
      sprks.remove(i);
    }
  }
}

public void mousePressed() {
  sprks.add(new Sparks(50, new PVector(mouseX, mouseY), color(255, 0, 0), 5.0f));
}

public void oscEvent(OscMessage msg) {
  print("RECIEVED OSC MESSAGE");
  print(" addrpattern: "+msg.addrPattern());
  println(" typetag: "+msg.typetag());
  println(msg);
  float x_pos = msg.get(0).floatValue();
  float y_pos = msg.get(1).floatValue();
  int color_bit = msg.get(2).intValue();
  x_pos = x_pos * width;
  y_pos = y_pos * height;
  int colr = color(0, 0, 0);
  if (color_bit == 0) {
    colr = color(0, 0, 255);
  }
  if (color_bit == 1) {
    colr = color(0, 255, 0);
  }
  if (color_bit == 2) {
    colr = color(255, 0, 0);
  }
  
  
  sprks.add(new Sparks(50, new PVector(x_pos, y_pos), colr, 5.0f));
}

public void keyPressed()
{
  if ( key == 'm' || key == 'M' )
  {
    if ( in.isMonitoring() )
    {
      in.disableMonitoring();
    }
    else
    {
      in.enableMonitoring();
    }
  }
}





class AudioTerrain {
  AudioInput in;
  FFT fft;
  int w = width;
  int h = height*5;
  int scl = height/10;
  int nois_rng = height/5;
  float flying = 0;
  int cols = (w / scl) + 1;
  int rows = h / scl;
  float[][] terrain = new float[cols][rows];
  int rotation;
  
  float threshLow = 0.01f; // 3%
  float threshMid = 0.125f;  // 12.5%
  float threshHi = 0.20f;   // 20%
  
  float scoreLow = 0;
  float scoreMid = 0;
  float scoreHi = 0;
  
  float oldScoreLow = 0;
  float oldScoreMid = 0;
  float oldScoreHi = 0;
  
  float scoreGlobal = 0;
  
  float scoreDecreaseRate = 1;
  
  AudioTerrain(AudioInput inp, int r) {
    in = inp;
    fft = new FFT(in.bufferSize(), in.sampleRate());
    rotation = r;
  }
  
  public void display() {
    //noFill();
    colorMode(HSB,100, rows-1, 1, rows-1);

    if (rotation == 0) {
      translate(width/2, height);
      rotateX(PI/2);
      translate(-width/2, -h/2);
    }
    if (rotation == 1) {
      translate(width/2, 0);
      rotateX(PI/2);
      translate(-width/2, -h/2);
    }
    if (rotation == 2) {
      translate(width/2, height/2);
      rotateX(PI/2);
      rotateY(PI/2);
      translate(-width/2, -h/2, width/2);
    }
    if (rotation == 3) {
      translate(width/2, height/2);
      rotateX(PI/2);
      rotateY(PI/2);
      translate(-width/2, -h/2, -width/2);
    }
    
    noFill();
    for (int y = 0; y < rows-1; y++) {
      //stroke(255*(float(y)/rows));
      strokeWeight(1 + (scoreGlobal/10));
      //print(255*(y/rows));
      beginShape(TRIANGLE_STRIP);
      for (int x = 0; x < cols; x++) {
        if (x < cols / 3) {
          stroke(0, rows-1, scoreLow, y);
        }
        else if (x < 2*cols /3) {
          stroke(33, rows-1, scoreMid, y);
        }
        else {
          stroke(66, rows-1, scoreHi, y);
        }
        vertex(x*scl, y*scl, terrain[x][y]);
        vertex(x*scl, (y+1)*scl, terrain[x][y+1]);
      }
      endShape();
    }
    if (rotation == 0) {
      translate(width/2, h/2);
      rotateX(-PI/2);
      translate(-width/2, -height);
    }
    if (rotation == 1) {
      translate(width/2, h/2);
      rotateX(-PI/2);
      translate(-width/2, 0);
    }
    if (rotation == 2) {
      translate(width/2, h/2, -width/2);
      rotateY(-PI/2);
      rotateX(-PI/2);
      translate(-width/2, -height/2);
    }
    if (rotation == 3) {
      translate(width/2, h/2, width/2);
      rotateY(-PI/2);
      rotateX(-PI/2);
      translate(-width/2, -height/2);
    }
  }
  
  
  public float update() {
    flying -= in.mix.level()*.5f;
    fft.forward(in.mix);
    
    oldScoreLow = scoreLow;
    oldScoreMid = scoreMid;
    oldScoreHi = scoreHi;
    scoreLow = 0;
    scoreMid = 0;
    scoreHi = 0;
    
    
    for(int i = 0; i < fft.specSize()*threshLow; i++)
    {
      scoreLow += Math.abs(fft.getBand(i));
    }
    
    for(int i = (int)(fft.specSize()*threshLow); i < fft.specSize()*threshMid; i++)
    {
      scoreMid += Math.abs(fft.getBand(i));
    }
    
    for(int i = (int)(fft.specSize()*threshMid); i < fft.specSize()*threshHi; i++)
    {
      scoreHi += Math.abs(fft.getBand(i));
    }
    scoreLow = scoreLow/(fft.specSize()*threshLow);
    scoreMid = scoreMid/(fft.specSize()*threshMid - fft.specSize()*threshLow);
    scoreHi = scoreHi/(fft.specSize()*threshHi - fft.specSize()*threshMid);
    
    if (oldScoreLow > scoreLow) {
      scoreLow = oldScoreLow - scoreDecreaseRate;
    }
  
    if (oldScoreMid > scoreMid) {
      scoreMid = oldScoreMid - scoreDecreaseRate;
    }
  
    if (oldScoreHi > scoreHi) {
      scoreHi = oldScoreHi - scoreDecreaseRate;
    }
    
    scoreGlobal = 0.66f*scoreLow + 0.8f*scoreMid + 1*scoreHi;
    
    
    
    
    float yoff = flying;
    
    for (int y = 0; y < rows; y++) {
      float xoff = 0;
      for (int x = 0; x < cols; x++) {
        terrain[x][y] = map(noise(xoff, yoff), 0, 1, -nois_rng, nois_rng);
        
        if (x == 0 || x == cols-1) {
          terrain[x][y] = 0;
        }
        xoff += 0.2f;
      }
      yoff += 0.2f;
    }
    
    return scoreGlobal;
  }
}
class AudioTerrainGrid {
  ArrayList<AudioTerrain> grid = new ArrayList<AudioTerrain>();
  AudioInput inp;
  
  float rotation;
  
  AudioTerrainGrid(AudioInput i) {
    inp = i;
    grid.add(new AudioTerrain(i, 0));
    grid.add(new AudioTerrain(i, 1));
    grid.add(new AudioTerrain(i, 2));
    grid.add(new AudioTerrain(i, 3));
  }
  
  public float update() {
    float volume = 0;
    for (AudioTerrain terr : grid) {
      volume += terr.update();
    }
    rotation += .0003f*volume;
    rotation = rotation % (2*PI);
    return volume;
  }
  
  public void display() {
    translate(width/2, height/2);
    rotateZ(rotation);
    translate(-width/2, -height/2);
    for (AudioTerrain terr : grid) {
      terr.display();
    }
    translate(width/2, height/2);
    rotateZ(-rotation);
    translate(-width/2, -height/2);
    
  }
}
class Sparks {
  int num;
  float[] x_pos;
  float[] y_pos;
  PVector origin;
  int colo;
  int lifespan;
  float range;
  
  Sparks(int seg_length, PVector v, int col, float rnge) {
    num = seg_length;
    range = rnge;
    lifespan = seg_length;
    x_pos = new float[num];
    y_pos = new float[num];
    origin = v.copy();
    colo = col;
    for(int i = 0; i < seg_length; i++) {
      x_pos[i] = origin.x;
      y_pos[i] = origin.y;
    }
  }
  
  public void update() {
    // Shift all elements 1 place to the left
    for(int i = 1; i < num; i++) {
      x_pos[i-1] = x_pos[i];
      y_pos[i-1] = y_pos[i];
    }
  
    // Put a new value at the end of the array
    x_pos[num-1] += random(-range, range);
    y_pos[num-1] += random(-range, range);
  
    // Constrain all points to the screen
    x_pos[num-1] = constrain(x_pos[num-1], 0, width);
    y_pos[num-1] = constrain(y_pos[num-1], 0, height);
    
    lifespan -= 1;
  }
  
  public void display() {
    //fill(colo);
    colorMode(RGB);
    for(int i=1; i<num; i++) {    
      stroke(colo);
      line(x_pos[i-1], y_pos[i-1], x_pos[i], y_pos[i]);
    }
  }
  
  public boolean is_dead() {
    if (lifespan < 0) {
      return true;
    }
    return false;
  }
}

class WebCamVisualizer {
  Capture cam;
  
  WebCamVisualizer(PApplet parent) {
    String[] cameras = Capture.list();
    
    if (cameras.length == 0) {
      println("There are no cameras available for capture.");
      exit();
    } else {
      println("Available cameras:");
      for (int i = 0; i < cameras.length; i++) {
        println(cameras[i]);
      }
      
      // The camera can be initialized directly using an 
      // element from the array returned by list():
      cam = new Capture(parent, cameras[7]);
      cam.start();     
    }
  }
  
  public void display() {
    if (cam.available() == true) {
      cam.read();
    }
    //translate(width/2, height/2);
    imageMode(CENTER);
    image(cam, width/2, height/2, width/4, height/4);
    //translate(-width/2, -height/2);
  }
}
  public void settings() {  fullScreen(P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Laser_Pointer_instrument" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
