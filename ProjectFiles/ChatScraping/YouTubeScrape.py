import json
import time
import socket
import psutil
from bs4 import BeautifulSoup as bs
from selenium import webdriver
from webdriver_manager import driver
from webdriver_manager.chrome import ChromeDriverManager


opened_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
LiveStream_URL = "https://www.youtube.com/watch?v=5qap5aO4i9A"
YouTube_BaseURL = "https://www.youtube.com"
chat_src = ""
lastChat = []
UDP_IP = "127.0.0.1"
UDP_PORT = 4243


def main():
    global chat_src
    user_pids = get_chrome_pids()
    driver_pids = []
    driver = create_driver()

    while True:
        if not chat_src:
            driver.get(LiveStream_URL)
            time.sleep(1)
            content = driver.page_source.encode("utf-8").strip()
            soup = bs(content, "lxml")
            chat_src = soup.find(id="chat").find("iframe").get("src")

            driver_pids = get_chrome_pids(user_pids)
            send_chat(driver_pids)
        
        get_chat(driver)

    driver.quit()


def get_chat(driver):
    SUCCESS = False

    while not SUCCESS:
        try:
            chat_url = "{}{}".format(YouTube_BaseURL, chat_src)
            driver.get(chat_url)
            content = driver.page_source.encode("utf-8").strip()
            soup = bs(content, "lxml")

            usernames = soup.find_all("span", id="author-name")
            messages = soup.find_all("span", id="message")
            global lastChat
            chat = []

            for x in range(len(usernames)-1):
                item = [usernames[x].text, messages[x].text]
                if not item in lastChat:
                    chat.append(item)
            
            if chat:
                send_chat(chat)
                lastChat.extend(chat)
            
            SUCCESS = True
        
        except Exception as e:
            # print("get chat attempt unsuccessful.")
            # print(e)
            time.sleep(1)
            # print("retrying...")
            continue


def create_driver():
    # Chrome options: https://peter.sh/experiments/chromium-command-line-switches/
    options_ = webdriver.ChromeOptions()
    options_.add_argument('window-size=100,100')
    options_.add_argument('window-position=10000,0')

    return webdriver.Chrome(ChromeDriverManager().install(), options=options_)


def print_list(list):
    for item in list:
        print(item)


def send_chat(chat):
    byte_message = bytes(json.dumps(chat), "utf-8")
    opened_socket.sendto(byte_message, (UDP_IP, UDP_PORT))


def get_chrome_pids(previous=[]):
    pids = []

    for process in psutil.process_iter(["pid", "name"]):
        process = process.info
        if "Google Chrome" in process.get("name"):
            if not process.get("pid") in previous:
                pids.append(process.get("pid")) # int
    
    return pids


if __name__ == "__main__":
    main()
