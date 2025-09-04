import subprocess
import requests
import json
import os
import time
import shutil
from datetime import datetime

CONFIG_FILE = "config.json"

def get_node_status():
    try:
        result = subprocess.run(
            ["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
             "-d", '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}',
             "http://localhost:8080"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            output = json.loads(result.stdout)
            number = output.get("result", {}).get("proven", {}).get("number")
            return number
    except Exception as e:
        print(f"[{timestamp()}] Error fetching node status: {e}")
    return None

def get_storage_info(path="/"):
    try:
        total, used, free = shutil.disk_usage(path)
        # Convert to GB for readability
        return {
            "total_gb": round(total / (1024 ** 3), 2),
            "used_gb": round(used / (1024 ** 3), 2),
            "free_gb": round(free / (1024 ** 3), 2)
        }
    except Exception as e:
        print(f"[{timestamp()}] Error fetching storage info: {e}")
        return None

def get_public_ip():
    try:
        response = requests.get("https://api.ipify.org?format=json", timeout=5)
        if response.status_code == 200:
            return response.json().get("ip")
        else:
            print(f"[{timestamp()}] Error fetching public IP: {response.text}")
    except Exception as e:
        print(f"[{timestamp()}] Error fetching public IP: {e}")
    return "Unavailable"

def send_telegram_message(bot_token, chat_id, message):
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {"chat_id": chat_id, "text": message}
    try:
        response = requests.post(url, json=payload)
        if response.status_code == 200:
            print(f"[{timestamp()}] Telegram message sent: {message}")
        else:
            print(f"[{timestamp()}] Telegram error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"[{timestamp()}] Failed to send Telegram message: {e}")
        return False

def load_or_create_config():
    if os.path.exists(CONFIG_FILE):
        use_existing = input("Found existing config. Use it? (y/n): ").strip().lower()
        if use_existing == 'y':
            with open(CONFIG_FILE, "r") as file:
                return json.load(file)

    bot_token = input("Enter your Telegram Bot API key: ").strip()
    chat_id = input("Enter your Telegram Chat ID: ").strip()
    node_id = input("Enter a label or number for this node (e.g., 1, 2, 3): ").strip()
    config = {"bot_token": bot_token, "chat_id": chat_id, "node_id": node_id}
    with open(CONFIG_FILE, "w") as file:
        json.dump(config, file)
    return config

def timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def format_message(node_id, number, public_ip, storage, node_ok=True):
    # Emojis: 🟢 OK | 🔴 Error | 🌐 IP | 💾 Disk | 🔢 Block
    if node_ok:
        msg = (
            f"🟢 [{node_id}]\n"
            f"Node is running fine.\n"
            f"🔢 Block number: {number}\n"
        )
    else:
        msg = (
            f"🔴 [{node_id}]\n"
            f"Node is NOT running properly or returned invalid data.\n"
        )
    msg += (
        f"🌐 Public IP: {public_ip}\n"
        f"💾 Storage:\n"
    )
    if storage:
        msg += (
            f"\tTotal: {storage['total_gb']}GB\n"
            f"\tUsed: {storage['used_gb']}GB\n"
            f"\tFree: {storage['free_gb']}GB"
        )
    else:
        msg += "\tStorage info not available"
    return msg

def main():
    config = load_or_create_config()
    bot_token = config["bot_token"]
    chat_id = config["chat_id"]
    node_id = config["node_id"]

    print(f"[{timestamp()}] Bot started for Node {node_id}. Checking node status every 30 minutes.")

    while True:
        number = get_node_status()
        storage = get_storage_info("/")
        public_ip = get_public_ip()
        node_ok = isinstance(number, int) and 0 <= number <= 99999
        message = format_message(node_id, number if node_ok else "N/A", public_ip, storage, node_ok=node_ok)
        send_telegram_message(bot_token, chat_id, message)
        time.sleep(1800)  # 30 minutes

if __name__ == "__main__":
    main()
