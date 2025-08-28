#!/usr/bin/env python3
import os, sys, time, requests

API_KEY = os.environ.get("SHODAN_API_KEY")
if not API_KEY:
    sys.stderr.write("SHODAN_API_KEY not set\n")
    sys.exit(1)

URL = f"https://stream.shodan.io/shodan/alert?key={API_KEY}"
OUT_DIR = "/var/log/shodan"
OUT_FILE = os.path.join(OUT_DIR, "stream.ndjson")

def stream():
    timeout = (5, None)  # 5s connect, infinite read
    headers = {"Accept": "application/json"}
    with requests.Session() as s:
        s.headers.update(headers)
        with s.get(URL, stream=True, timeout=timeout) as r:
            r.raise_for_status()
            os.makedirs(OUT_DIR, exist_ok=True)
            with open(OUT_FILE, "a", buffering=1) as f:
                for line in r.iter_lines(decode_unicode=True):
                    if line:
                        f.write(line + "\n")

if __name__ == "__main__":
    while True:
        try:
            stream()
        except Exception as e:
            sys.stderr.write(f"[shodan-forwarder] error: {e}\n")
            time.sleep(5)
