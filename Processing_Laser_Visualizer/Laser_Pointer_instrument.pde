ArrayList<Sparks> sprks;

import ddf.minim.*;
import ddf.minim.analysis.*;
import oscP5.*;
import netP5.*;

Minim minim;
AudioInput in;
AudioTerrainGrid grid;
WebCamVisualizer webCam;
OscP5 oscP5;


void setup() {
  //size(600, 600, P3D);
  fullScreen(P3D);
  sprks = new ArrayList<Sparks>();
  
  minim = new Minim(this);
  in = minim.getLineIn();
  
  grid = new AudioTerrainGrid(in);
  
  webCam = new WebCamVisualizer(this);
  
  oscP5 = new OscP5(this, 5005);
  
  
}

void draw() {
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

void mousePressed() {
  sprks.add(new Sparks(50, new PVector(mouseX, mouseY), color(255, 0, 0), 5.0));
}

void oscEvent(OscMessage msg) {
  print("RECIEVED OSC MESSAGE");
  print(" addrpattern: "+msg.addrPattern());
  println(" typetag: "+msg.typetag());
  println(msg);
  float x_pos = msg.get(0).floatValue();
  float y_pos = msg.get(1).floatValue();
  int color_bit = msg.get(2).intValue();
  x_pos = x_pos * width;
  y_pos = y_pos * height;
  color colr = color(0, 0, 0);
  if (color_bit == 0) {
    colr = color(0, 0, 255);
  }
  if (color_bit == 1) {
    colr = color(0, 255, 0);
  }
  if (color_bit == 2) {
    colr = color(255, 0, 0);
  }
  
  
  sprks.add(new Sparks(50, new PVector(x_pos, y_pos), colr, 5.0));
}

void keyPressed()
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
