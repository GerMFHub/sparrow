import paho.mqtt.client as mqtt
import json
import time
import threading

# MQTT Broker Configuration
BROKER_ADDRESS = "localhost"
TOPIC_DRONE_STATUS = "drone/status"
TOPIC_DRONE_COMMAND = "drone/command"
TOPIC_FLIGHT_CONTROLLER = "flight_controller/status"
TOPIC_GROUND_CONTROL = "ground_control/command"

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
        self.client.loop_start()
    
    def on_message(self, client, userdata, message):
        command = json.loads(message.payload.decode())
        if command.get("target") == self.drone_id or command.get("target") == "all":
            print(f"Drone {self.drone_id} received command: {command['action']}")
            self.execute_command(command['action'])
    
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
    
    def start_status_updates(self):
        def status_updates():
            while True:
                self.send_status()
                time.sleep(5)
        threading.Thread(target=status_updates, daemon=True).start()

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
    
    def send_command(self, action, target="all"):
        command = {
            "action": action,
            "target": target
        }
        self.client.publish(TOPIC_DRONE_COMMAND, json.dumps(command))
        print(f"Flight Controller sent command: {action} to {target}")

# Ground Control Class
class GroundControl:
    def __init__(self):
        self.client = mqtt.Client("ground_control")
        self.client.connect(BROKER_ADDRESS)
    
    def send_flight_instruction(self, action, target="all"):
        command = {
            "action": action,
            "target": target
        }
        self.client.publish(TOPIC_GROUND_CONTROL, json.dumps(command))
        print(f"Ground Control sent instruction: {action} to {target}")
