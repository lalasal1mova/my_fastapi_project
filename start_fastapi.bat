@echo off
echo =======================
echo Starting FastAPI Server
echo =======================

cd /d C:\Users\user\pythonProject\my_fastapi_project

venv\Scripts\activate

uvicorn main:app --host 0.0.0.0 --port 8000 --reload

pause