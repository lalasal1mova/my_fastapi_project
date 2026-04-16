from fastapi import FastAPI, HTTPException, Depends, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, text
from pydantic import BaseModel
from jose import JWTError, jwt
from datetime import datetime, timedelta

# FastAPI
app = FastAPI()
templates = Jinja2Templates(directory="templates")

@app.middleware("http")
async def add_cors_header(request: Request, call_next):
    if request.method == "OPTIONS":
        from fastapi.responses import Response
        response = Response(status_code=200)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "*"
        response.headers["Access-Control-Max-Age"] = "86400"
        return response
    response = await call_next(request)
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "*"
    return response

DATABASE_URL = "mssql+pyodbc://@localhost/MilliMeclis?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
engine = create_engine(DATABASE_URL)

# JWT
SECRET_KEY = "supersecretkey123"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

security = HTTPBearer()

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token etibarsizdir")
        return payload
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token etibarsizdir")

def verify_admin(payload: dict = Depends(verify_token)):
    if payload.get("rol") != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="İcazəniz yoxdur")
    return payload


# Modellər
class Login(BaseModel):
    username: str
    password: str

class Vezife(BaseModel):
    ad: str

class Isci(BaseModel):
    ad: str
    soyad: str
    vezife_id: int
    telefon_nomresi1: str
    telefon_nomresi2: str
    seher_nomresi1: str
    seher_nomresi2: str
    daxili_nomre: str


# LOGIN
@app.post("/login")
def login(user: Login):
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT * FROM istifadeci WHERE username=:username AND password=:password"),
            {"username": user.username, "password": user.password}
        )
        row = result.fetchone()
        if row is None:
            raise HTTPException(status_code=401, detail="Login yanlisdir")
        istifadeci = dict(row._mapping)

    token = create_access_token({
        "sub": istifadeci["username"],
        "rol": istifadeci["rol"],
        "id": istifadeci["id"]
    })
    return {
        "access_token": token,
        "token_type": "bearer",
        "rol": istifadeci["rol"],
        "username": istifadeci["username"]
    }

@app.get("/login")
def login_page(request: Request):
    return templates.TemplateResponse("login.html", {"request": request})

@app.get("/admin")
def admin_page(request: Request):
    with engine.connect() as conn:
        vezifeler = conn.execute(text("SELECT * FROM vezife")).fetchall()
        isciler = conn.execute(text("SELECT * FROM isci")).fetchall()

    return templates.TemplateResponse(
        "admin.html",
        {
            "request": request,
            "vezifeler": [dict(r._mapping) for r in vezifeler],
            "isciler": [dict(r._mapping) for r in isciler],
        }
    )


# VƏZİFƏLƏR
@app.get("/vezifeler", dependencies=[Depends(verify_token)])
def get_vezifeler():
    with engine.connect() as conn:
        result = conn.execute(text("SELECT * FROM vezife"))
        rows = [dict(row._mapping) for row in result]
    return rows

@app.post("/vezifeler", dependencies=[Depends(verify_admin)])
def add_vezife(vezife: Vezife):
    with engine.begin() as conn:
        result = conn.execute(
            text("INSERT INTO vezife (ad) OUTPUT INSERTED.id VALUES (:ad)"),
            {"ad": vezife.ad}
        )
        new_id = result.scalar()
    return {"id": new_id, "ad": vezife.ad}

@app.put("/vezifeler/{vezife_id}", dependencies=[Depends(verify_admin)])
def update_vezife(vezife_id: int, vezife: Vezife):
    with engine.begin() as conn:
        result = conn.execute(
            text("UPDATE vezife SET ad=:ad WHERE id=:id"),
            {"ad": vezife.ad, "id": vezife_id}
        )
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Vezife tapilmadi")
    return {"message": "Vezife yenilendi"}

@app.delete("/vezifeler/{vezife_id}", dependencies=[Depends(verify_admin)])
def delete_vezife(vezife_id: int):
    with engine.begin() as conn:
        result = conn.execute(
            text("DELETE FROM vezife WHERE id=:id"),
            {"id": vezife_id}
        )
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Vezife tapilmadi")
    return {"message": "Vezife silindi"}


# İŞÇİLƏR
@app.get("/vezifeler/{vezife_id}/isciler", dependencies=[Depends(verify_token)])
def get_isciler(vezife_id: int):
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT * FROM isci WHERE vezife_id=:vezife_id"),
            {"vezife_id": vezife_id}
        )
        rows = [dict(row._mapping) for row in result]
    return rows

@app.get("/isciler/{isci_id}", dependencies=[Depends(verify_token)])
def get_isci(isci_id: int):
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT i.*, v.ad as vezife_adi 
                FROM isci i 
                JOIN vezife v ON i.vezife_id = v.id 
                WHERE i.id=:id
            """),
            {"id": isci_id}
        )
        row = result.fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Isci tapilmadi")
    return dict(row._mapping)

@app.post("/isciler", dependencies=[Depends(verify_admin)])
def add_isci(isci: Isci):
    with engine.begin() as conn:
        result = conn.execute(
            text("""INSERT INTO isci (ad, soyad, vezife_id, telefon_nomresi1, telefon_nomresi2, seher_nomresi1, seher_nomresi2, daxili_nomre)
                    OUTPUT INSERTED.id
                    VALUES (:ad, :soyad, :vezife_id, :telefon_nomresi1, :telefon_nomresi2, :seher_nomresi1, :seher_nomresi2, :daxili_nomre)"""),
            {"ad": isci.ad, "soyad": isci.soyad, "vezife_id": isci.vezife_id,
             "telefon_nomresi1": isci.telefon_nomresi1, "telefon_nomresi2": isci.telefon_nomresi2,
             "seher_nomresi1": isci.seher_nomresi1, "seher_nomresi2": isci.seher_nomresi2,
             "daxili_nomre": isci.daxili_nomre}
        )
        new_id = result.scalar()
    return {"id": new_id, **isci.dict()}

@app.put("/isciler/{isci_id}", dependencies=[Depends(verify_admin)])
def update_isci(isci_id: int, isci: Isci):
    with engine.begin() as conn:
        result = conn.execute(
            text("""UPDATE isci SET ad=:ad, soyad=:soyad, vezife_id=:vezife_id,
                    telefon_nomresi1=:telefon_nomresi1, telefon_nomresi2=:telefon_nomresi2,
                    seher_nomresi1=:seher_nomresi1, seher_nomresi2=:seher_nomresi2,
                    daxili_nomre=:daxili_nomre WHERE id=:id"""),
            {"ad": isci.ad, "soyad": isci.soyad, "vezife_id": isci.vezife_id,
             "telefon_nomresi1": isci.telefon_nomresi1, "telefon_nomresi2": isci.telefon_nomresi2,
             "seher_nomresi1": isci.seher_nomresi1, "seher_nomresi2": isci.seher_nomresi2,
             "daxili_nomre": isci.daxili_nomre, "id": isci_id}
        )
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Isci tapilmadi")
    return {"message": "Isci yenilendi"}

@app.delete("/isciler/{isci_id}", dependencies=[Depends(verify_admin)])
def delete_isci(isci_id: int):
    with engine.begin() as conn:
        result = conn.execute(
            text("DELETE FROM isci WHERE id=:id"),
            {"id": isci_id}
        )
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="Isci tapilmadi")
    return {"message": "Isci silindi"}


# İSTİFADƏÇİLƏR (yalnız admin)
@app.get("/istifadeciler", dependencies=[Depends(verify_admin)])
def get_istifadeciler():
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT id, username, rol FROM istifadeci")
        )
        rows = [dict(row._mapping) for row in result]
    return rows

class IstifadeciCreate(BaseModel):
    username: str
    password: str
    rol: str = "user"

@app.post("/istifadeciler", dependencies=[Depends(verify_admin)])
def add_istifadeci(istifadeci: IstifadeciCreate):
    with engine.begin() as conn:
        result = conn.execute(
            text("INSERT INTO istifadeci (username, password, rol) OUTPUT INSERTED.id VALUES (:username, :password, :rol)"),
            {"username": istifadeci.username, "password": istifadeci.password, "rol": istifadeci.rol}
        )
        new_id = result.scalar()
    return {"id": new_id, "username": istifadeci.username, "rol": istifadeci.rol}

@app.delete("/istifadeciler/{istifadeci_id}", dependencies=[Depends(verify_admin)])
def delete_istifadeci(istifadeci_id: int):
    with engine.begin() as conn:
        result = conn.execute(
            text("DELETE FROM istifadeci WHERE id=:id"),
            {"id": istifadeci_id}
        )
        if result.rowcount == 0:
            raise HTTPException(status_code=404, detail="İstifadəçi tapılmadı")
    return {"message": "İstifadəçi silindi"}
