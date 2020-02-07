import processing.video.*;
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
  
  void display() {
    if (cam.available() == true) {
      cam.read();
    }
    //translate(width/2, height/2);
    imageMode(CENTER);
    image(cam, width/2, height/2, width/4, height/4);
    //translate(-width/2, -height/2);
  }
}
