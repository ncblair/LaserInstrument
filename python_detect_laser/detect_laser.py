import cv2
import numpy as np
from pythonosc import udp_client
from pythonosc import osc_message_builder
import time

client_proc = udp_client.SimpleUDPClient("127.0.0.1", 5005)
client_chuck = udp_client.SimpleUDPClient("127.0.0.1", 6449)

SIZE = (40, 40)
buffer_size = 50

def prepro_frame(im):
	im = cv2.resize(im, SIZE)
	return im


im_buffer = np.zeros((buffer_size, SIZE[0], SIZE[1]))


# cv2.namedWindow("preview")
vc = cv2.VideoCapture(0)

if vc.isOpened(): # try to get the first frame
	rval, frame = vc.read()
	frame = prepro_frame(frame)
	avg_im = np.mean(frame, axis=2)/255
else:
	rval = False


box_size = 10

def assign(im, r, c, v):
	r = min(max(r, 0), im.shape[0]-1)
	c = min(max(c, 0), im.shape[1]-1)
	im[r, c] = v

def brightness(im, r, c, s):
	r = min(max(r, s), im.shape[0]-s-1)
	c = min(max(c, s), im.shape[1]-s-1)
	return np.mean(im[r-s:r+s, c-s:c+s])

def detect_color(im, r, c, s):
	blue_score = brightness(im[:, :, 0], r, c, s)
	green_score = brightness(im[:, :, 1], r, c, s)
	red_score = brightness(im[:, :, 2], r, c, s)
	return 	max([(np.array([255, 0, 0]), blue_score), 
			(np.array([0, 255, 0]), green_score), 
			(np.array([0, 0, 255]), red_score)], key=lambda x:x[1])[0]

def get_color_map(frame):
	frame = frame
	blur = cv2.GaussianBlur(frame,(3,3),0)
	b_over_g = blur[:, :, 0] > blur[:, :, 1]
	b_over_r = blur[:, :, 0] > blur[:, :, 2]
	g_over_r = blur[:, :, 1] > blur[:, :, 2]
	b_map = b_over_g * b_over_r
	g_map = (1 - b_over_g)*b_over_r
	r_map = (1-b_over_r)*(1-g_over_r)
	color_map = np.stack([b_map, g_map, r_map], axis=2)*255
	return b_map, g_map, r_map, color_map



j = 0

lasers_on = [0, 0, 0]

while rval:
	# Get Frame
	rval, raw_frame = vc.read()
	frame = prepro_frame(raw_frame)

	# Get location of brightest pixel in difference image

	b_map, g_map, r_map, color_map = get_color_map(frame) # b_map is 1 if blue area, same size as frame
	frame = np.mean(frame, axis=2)/255
	dif_im = (frame  - avg_im)/(1 - np.max(avg_im)) # expand to full possible range
	for color_bit, c_map in enumerate([b_map, g_map, r_map]):
		d_im = dif_im*c_map
		max_bright = np.max(d_im)
		locations = np.nonzero(d_im == max_bright)
		location = max([(brightness(dif_im, r, c, box_size//5), np.array([r, c])) for r, c in zip(*locations)], key=lambda x:x[0])[1]

		loc = np.array([location[0]*raw_frame.shape[0]//frame.shape[0], location[1]*raw_frame.shape[1]//frame.shape[1]])

		b = brightness(d_im, *location, box_size//5)
		# print(b)
		if (b > .15):
			print("LASER DETECTED", loc, b)
			color = color_map[location[0], location[1]]
			for i in range(-box_size, box_size):
				assign(raw_frame, loc[0] + box_size, loc[1] + i, color)
				assign(raw_frame, loc[0] - box_size, loc[1] + i, color)
				assign(raw_frame, loc[0] + i, loc[1] + box_size, color)
				assign(raw_frame, loc[0] + i, loc[1] - box_size, color)
		

			client_proc.send_message("/loc", [loc[1]/raw_frame.shape[1], loc[0]/raw_frame.shape[0], color_bit])
			if color_bit == 0:
				client_chuck.send_message("/Bass", [loc[1]/raw_frame.shape[1], loc[0]/raw_frame.shape[0], 1])
			if color_bit == 1:
				client_chuck.send_message("/Pad", [loc[1]/raw_frame.shape[1], loc[0]/raw_frame.shape[0], 1])
			if color_bit == 2:
				client_chuck.send_message("/Lead", [loc[1]/raw_frame.shape[1], loc[0]/raw_frame.shape[0], 1])
		else:
			# client_proc.send_message("/loc", [loc[1]/raw_frame.shape[1], loc[0]/raw_frame.shape[0], 3])
			if color_bit == 0:
				client_chuck.send_message("/Bass", [loc[1]/raw_frame.shape[1], loc[0]/raw_frame.shape[0], 0])
			if color_bit == 1:
				client_chuck.send_message("/Pad", [loc[1]/raw_frame.shape[1], loc[0]/raw_frame.shape[0], 0])
			if color_bit == 2:
				client_chuck.send_message("/Lead", [loc[1]/raw_frame.shape[1], loc[0]/raw_frame.shape[0], 0])

		# cv2.imshow("preview", raw_frame)


	im_buffer[1:] = im_buffer[:-1]
	im_buffer[0] = frame
	j += 1
	if (j < buffer_size):
		print("\n\n", j, "\n\n")
		avg_im = np.mean(im_buffer, axis=0)


	key = cv2.waitKey(20)
	if key == 27: # exit on ESC
		break
# cv2.destroyWindow("preview")