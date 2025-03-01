import paho.mqtt.client as mqtt
import json
import time
import threading
import cv2
import base64
import numpy as np

# MQTT Broker Configuration
BROKER_ADDRESS = "localhost"
TOPIC_DRONE_STATUS = "drone/status"
TOPIC_DRONE_COMMAND = "drone/command"
TOPIC_FLIGHT_CONTROLLER = "flight_controller/status"
TOPIC_GROUND_CONTROL = "ground_control/command"
TOPIC_VIDEO_FEED = "drone/video"
TOPIC_COORDINATION = "swarm/coordination"

# Drone Class
class Drone:
    def __init__(self, drone_id):
        self.drone_id = drone_id
        self.position = [0.0, 0.0, 100.0]  # x, y, altitude
        self.status = "operational"
        self.client = mqtt.Client(f"drone_{drone_id}")
        self.client.on_message = self.on_message
        self.client.connect(BROKER_ADDRESS)
        self.client.subscribe(TOPIC_DRONE_COMMAND)
        self.client.subscribe(TOPIC_COORDINATION)
        self.client.loop_start()
        self.cap = cv2.VideoCapture(0)
    
    def on_message(self, client, userdata, message):
        command = json.loads(message.payload.decode())
        if command.get("target") == self.drone_id or command.get("target") == "all":
            print(f"Drone {self.drone_id} received command: {command['action']}")
            self.execute_command(command['action'])
        elif "coordinates" in command:
            self.coordinate_with_swarm(command)
    
    def execute_command(self, action):
        if action == "move_forward":
            self.position[0] += 5
        elif action == "hover":
            self.status = "hovering"
        elif action == "land":
            self.position[2] = 0
            self.status = "landed"
        print(f"Drone {self.drone_id} new status: {self.status}, position: {self.position}")
    
    def send_status(self):
        status = {
            "drone_id": self.drone_id,
            "position": self.position,
            "status": self.status
        }
        self.client.publish(TOPIC_DRONE_STATUS, json.dumps(status))
    
    def send_video_feed(self):
        while True:
            ret, frame = self.cap.read()
            if ret:
                _, buffer = cv2.imencode('.jpg', frame)
                encoded_image = base64.b64encode(buffer).decode()
                video_data = {"drone_id": self.drone_id, "image": encoded_image}
                self.client.publish(TOPIC_VIDEO_FEED, json.dumps(video_data))
            time.sleep(0.1)
    
    def coordinate_with_swarm(self, data):
        self.position = data["coordinates"]
        print(f"Drone {self.drone_id} coordinating with swarm: new position {self.position}")
    
    def start_status_updates(self):
        def status_updates():
            while True:
                self.send_status()
                time.sleep(5)
        threading.Thread(target=status_updates, daemon=True).start()
        threading.Thread(target=self.send_video_feed, daemon=True).start()

# Flight Controller Class
class FlightController:
    def __init__(self):
        self.client = mqtt.Client("flight_controller")
        self.client.on_message = self.on_message
        self.client.connect(BROKER_ADDRESS)
        self.client.subscribe(TOPIC_DRONE_STATUS)
        self.client.loop_start()
    
    def on_message(self, client, userdata, message):
        status_update = json.loads(message.payload.decode())
        print(f"Flight Controller received status: {status_update}")
        self.coordinate_swarm()
    
    def send_command(self, action, target="all"):
        command = {
            "action": action,
            "target": target
        }
        self.client.publish(TOPIC_DRONE_COMMAND, json.dumps(command))
        print(f"Flight Controller sent command: {action} to {target}")
    
    def coordinate_swarm(self):
        # Simulating coordinated swarm movement based on video recognition
        coordination_data = {
            "coordinates": [10.0, 20.0, 100.0]  # New position based on vision data
        }
        self.client.publish(TOPIC_COORDINATION, json.dumps(coordination_data))
        print("Flight Controller sent swarm coordination data.")

# Ground Control Class
class GroundControl:
    def __init__(self):
        self.client = mqtt.Client("ground_control")
        self.client.on_message = self.on_video_feed
        self.client.connect(BROKER_ADDRESS)
        self.client.subscribe(TOPIC_VIDEO_FEED)
        self.client.loop_start()
    
    def send_flight_instruction(self, action, target="all"):
        command = {
            "action": action,
            "target": target
        }
        self.client.publish(TOPIC_GROUND_CONTROL, json.dumps(command))
        print(f"Ground Control sent instruction: {action} to {target}")
    
    def on_video_feed(self, client, userdata, message):
        video_data = json.loads(message.payload.decode())
        img_data = base64.b64decode(video_data["image"])
        np_arr = np.frombuffer(img_data, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        cv2.imshow(f"Drone {video_data['drone_id']} Video Feed", frame)
        cv2.waitKey(1)
