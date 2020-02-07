# LaserInstrument

Use laser pointers and a webcam to control MIDI.

Different colored lasers send different MIDI on/off messages. 

MIDI Control messages are sent based on laser position in the camera field of view.

Results can be visualized in Processing. 

To Run: 
`
python python_detext_laser/detect_laser.py
ChucK Chuck_Midi_Controller/initialize.ck
processing-java --sketch=`pwd`/Processing_Laser_Visualizer --output=`pwd`/Processing_Laser_Visualizer/output --force --run
`

Demo Video under the music portfolio at www.nathanblair.me