import sys
import subprocess
from pynput.mouse import Controller, Button, Listener
import tkinter as tk
from tkinter import simpledialog
import datetime
import queue
import time
import shutil
import os


if len(sys.argv) < 3:
    print("Please provide a file path for logging and a path to the appSandbox directory.")
    sys.exit(1)

log_file_path = sys.argv[1]
appSandbox = sys.argv[2]
mouse_controller = Controller()
log_clicks = True

def log_action(action, timestamp, position):
    with open(log_file_path, "a") as file:
        file.write(f"Timestamp: {timestamp}, Action: {action}, Position: {position}\n")
    copy_folder(action)

def copy_folder(user_action):

    try:
        shutil.copytree(appSandbox, os.getcwd()+"/"+appSandbox+"/before_"+user_action)
    except Exception as e:
        print(f"An error occurred: {e}")


def on_click(x, y, button, pressed):
    global log_clicks
    if pressed and log_clicks:
        log_clicks = False

        action_queue.put(("clicked", (x, y)))

def show_dialog():
    global log_clicks

    timestamp = datetime.datetime.now()

    action, position = action_queue.get_nowait()

    root.withdraw()

    user_action = simpledialog.askstring("Input", "What action did you just perform?", parent=root)

    if user_action:
        log_action(user_action, timestamp, position)

        mouse_controller.position = position
        time.sleep(0.2)
        mouse_controller.press(Button.left)
        mouse_controller.release(Button.left)
        mouse_controller.press(Button.left)
        mouse_controller.release(Button.left)

    root.deiconify()

    time.sleep(0.5)

    log_clicks = True

def check_queue():
    try:
        if not action_queue.empty():
            show_dialog()
    except queue.Empty:
        pass
    finally:
        root.after(100, check_queue)

action_queue = queue.Queue()

root = tk.Tk()

screen_width = root.winfo_screenwidth()
screen_height = root.winfo_screenheight()

root.geometry(f"{screen_width}x{screen_height}+0+0")

root.attributes('-alpha', 0.3)

listener = Listener(on_click=on_click)
listener.start()

root.after(100, check_queue)

root.mainloop()
