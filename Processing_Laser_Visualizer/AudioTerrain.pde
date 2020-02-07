import ddf.minim.*;
import ddf.minim.analysis.*;
import java.lang.Math;


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
  
  float threshLow = 0.01; // 3%
  float threshMid = 0.125;  // 12.5%
  float threshHi = 0.20;   // 20%
  
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
  
  void display() {
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
  
  
  float update() {
    flying -= in.mix.level()*.5;
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
    
    scoreGlobal = 0.66*scoreLow + 0.8*scoreMid + 1*scoreHi;
    
    
    
    
    float yoff = flying;
    
    for (int y = 0; y < rows; y++) {
      float xoff = 0;
      for (int x = 0; x < cols; x++) {
        terrain[x][y] = map(noise(xoff, yoff), 0, 1, -nois_rng, nois_rng);
        
        if (x == 0 || x == cols-1) {
          terrain[x][y] = 0;
        }
        xoff += 0.2;
      }
      yoff += 0.2;
    }
    
    return scoreGlobal;
  }
}
