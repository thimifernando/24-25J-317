from fastapi import APIRouter, HTTPException, Depends
from database import users_collection
from models.user_model import UserCreate, UserLogin
from passlib.hash import bcrypt
import jwt
from config import JWT_SECRET
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="signin")

class UserProfile(BaseModel):
    name: str
    email: str

def create_jwt(email):
    return jwt.encode({"email": email}, JWT_SECRET, algorithm="HS256")

def decode_jwt(token: str):
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_current_user(token: str = Depends(oauth2_scheme)):
    payload = decode_jwt(token)
    email = payload.get("email")
    
    user = users_collection.find_one({"email": email})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"name": user["name"], "email": user["email"]}

@router.post("/signup")
def signup(user: UserCreate):
    if users_collection.find_one({"email": user.email}):
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_password = bcrypt.hash(user.password)
    users_collection.insert_one({"name": user.name, "email": user.email, "password": hashed_password})
    return {"message": "User registered successfully"}

@router.post("/signin")
def signin(user: UserLogin):
    db_user = users_collection.find_one({"email": user.email})
    if not db_user or not bcrypt.verify(user.password, db_user["password"]):
        raise HTTPException(status_code=400, detail="Invalid credentials")
    
    token = create_jwt(user.email)
    return {"token": token, "message": "Signin successful"}

@router.get("/user/profile", response_model=UserProfile)
def get_user_profile(user: dict = Depends(get_current_user)):
    return user