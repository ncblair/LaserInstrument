public class LaserInstrument {
	MidiOut mout_track;
	MidiOut mout_ctrl;
	MidiMsg midi_msg;
	MidiMsg ctrl_msg;

	fun void MIDInote(int onoff, int note, int velocity, int chan) {
	    if (onoff == 0) {
	        128 + chan => midi_msg.data1;
	    }
	    else {
	        144 + chan => midi_msg.data1;
	    }
	    note => midi_msg.data2;
	    velocity => midi_msg.data3;
	    <<<"MIDI MESSAGE", note, velocity, onoff, chan>>>;
	    mout_track.send(midi_msg);
	    20::ms=>now;
	}

	fun void MIDIcontrol(int channel, int ccControl, int ccvalue) {
		//ccControl is 0 or 1, ccvalue is 0-127, channel is 0-15
		176 => ctrl_msg.data1;
		43 + 2*channel + ccControl => ctrl_msg.data2;
		ccvalue => ctrl_msg.data3;
		mout_ctrl.send(ctrl_msg);
	}

	OscIn oin;
	OscMsg msg;

	6449 => oin.port;

	if ( !mout_track.open(0) ) {
		<<< "ERROR: MIDI PORT FAILURE ", 0>>>;
		me.exit();
	}
	if ( !mout_ctrl.open(1) ) {
		<<< "ERROR: MIDI PORT FAILURE ", 0>>>;
		me.exit();
	}


	[60, 60, 60] @=> int notes[];
	int gain;
	[0, 0, 0] @=> int note_on[];
	["/Bass", "/Lead", "/Pad"] @=> string addresses[];
	[0, 1, 2] @=> int chans[];

	// add addresses
	for (0 => int i; i < addresses.cap();i++) {
		oin.addAddress(addresses[i]);
	}

	fun void run() {
		spork ~ play();
		while(1) {

			oin => now;

			while (oin.recv(msg) != 0) {
				for (0 => int i; i < addresses.cap(); i++) {
					if (msg.address == addresses[i]) {
						msg.getFloat(0) => float x;
						msg.getFloat(1) => float y;
						msg.getInt(2) => int onoff;

						if (onoff == 1) {
							<<< "LASER ", addresses[i], " RECIEVED" >>>;
							Std.ftoi(Math.round(x*127)) => int cc1;
							Std.ftoi(Math.round(y*127)) => int cc2;
							MIDIcontrol(chans[i], 0, cc1);
							MIDIcontrol(chans[i], 1, cc2);
							if (!note_on[i]) {
								<<< "NOTE ON ", addresses[i] >>>;
								MIDInote(1, notes[i], 127, chans[i]);
								1 => note_on[i];
							}
						}
						if (onoff == 0) {
							if (note_on[i]) {
								<<< "NOTE OFF ", addresses[i]>>>;
								MIDInote(0, notes[i], 0, chans[i]);
								0 => note_on[i];
							}
						}
					}
				}
			}
		}
	}	




	fun void play() {
		while (1) {
			1::samp => now;
		}
	}
}