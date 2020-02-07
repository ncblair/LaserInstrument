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
  
  float update() {
    float volume = 0;
    for (AudioTerrain terr : grid) {
      volume += terr.update();
    }
    rotation += .0003*volume;
    rotation = rotation % (2*PI);
    return volume;
  }
  
  void display() {
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
