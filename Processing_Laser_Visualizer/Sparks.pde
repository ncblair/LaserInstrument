class Sparks {
  int num;
  float[] x_pos;
  float[] y_pos;
  PVector origin;
  color colo;
  int lifespan;
  float range;
  
  Sparks(int seg_length, PVector v, color col, float rnge) {
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
  
  void update() {
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
  
  void display() {
    //fill(colo);
    colorMode(RGB);
    for(int i=1; i<num; i++) {    
      stroke(colo);
      line(x_pos[i-1], y_pos[i-1], x_pos[i], y_pos[i]);
    }
  }
  
  boolean is_dead() {
    if (lifespan < 0) {
      return true;
    }
    return false;
  }
}
