import subprocess
import time
import requests
import re

# FastAPI serveri başlat
fastapi = subprocess.Popen([
    r"C:\Users\user\pythonProject\my_fastapi_project\venv\Scripts\uvicorn.exe",
    "main:app", "--host", "0.0.0.0", "--port", "8000"
], cwd=r"C:\Users\user\pythonProject\my_fastapi_project")

print("FastAPI server başladı...")
time.sleep(3)

# ngrok başlat
ngrok = subprocess.Popen([
    r"C:\Users\user\AppData\Local\Microsoft\WindowsApps\ngrok.exe",
    "http", "8000"
    "--host-header", "rewrite" 
])

print("ngrok başladı...")
time.sleep(5)

# ngrok URL-i al
try:
    res = requests.get("http://127.0.0.1:4040/api/tunnels")
    data = res.json()
    url = data["tunnels"][0]["public_url"]
    print(f"ngrok URL: {url}")

    # api_service.dart faylını yenilə
    dart_file = r"C:\Users\user\pythonProject\my_fastapi_project\milli_meclis\lib\services\api_service.dart"
    
    with open(dart_file, "r", encoding="utf-8") as f:
        content = f.read()
    
    content = re.sub(
        r'const String baseUrl = ".*?";',
        f'const String baseUrl = "{url}";',
        content
    )
    
    with open(dart_file, "w", encoding="utf-8") as f:
        f.write(content)
    
    print(f"api_service.dart yenilendi: {url}")

    # APK build et
    print("APK build edilir, gözləyin...")
    flutter_dir = r"C:\Users\user\pythonProject\my_fastapi_project\milli_meclis"
    subprocess.run([r"C:\flutter\bin\flutter.bat", "build", "apk", "--release"], cwd=flutter_dir, check=True)
    print("APK hazırdır!")

    # Telefona yüklə
    print("Telefona yüklənir...")
    subprocess.run([r"C:\flutter\bin\flutter.bat", "install", "--release"], cwd=flutter_dir, check=True)
    print("Telefona yükləndi!")

except Exception as e:
    print(f"Xeta: {e}")

print("Hər şey hazırdır!")

# Prosesləri saxla
fastapi.wait()