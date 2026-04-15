@echo off
echo =======================
echo Starting Flutter Web Server
echo =======================
cd /d C:\Users\user\pythonProject\my_fastapi_project\milli_meclis\build\web
py -m http.server 8000
pause