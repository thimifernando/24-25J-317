from fastapi import FastAPI, HTTPException, status
from pymongo import MongoClient
from pydantic import BaseModel
from werkzeug.security import generate_password_hash, check_password_hash
import os
from typing import Optional

app = FastAPI()

# Load MongoDB URI from environment variables (for security)
MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://ecommerce:admin1234@cluster0.2sqjp.mongodb.net/greeny")
client = MongoClient(MONGO_URI)
db = client["greeny"]
collection = db["users"]  # Collection name

# Define a User model for sign-up
class User(BaseModel):
    name: str
    email: str
    password: str

# Define a SignIn model for sign-in
class SignIn(BaseModel):
    email: str
    password: str

# Helper function to validate password strength
def validate_password_strength(password: str):
    if len(password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 8 characters long",
        )
    # Add more password strength rules if needed

# API Endpoint to add a user (Sign Up)
@app.post("/add_user/")
async def add_user(user: User):
    # Validate password strength
    validate_password_strength(user.password)

    # Hash password before storing
    hashed_password = generate_password_hash(user.password)
    user_dict = {"name": user.name, "email": user.email, "password": hashed_password}

    # Check if user already exists
    if collection.find_one({"email": user.email}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        )

    result = collection.insert_one(user_dict)
    return {"message": "User added", "user_id": str(result.inserted_id)}

# API Endpoint to sign in a user
@app.post("/sign_in/")
async def sign_in(user: SignIn):
    # Fetch user from MongoDB
    db_user = collection.find_one({"email": user.email})

    if db_user is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email or password",
        )

    # Check if the provided password matches the stored hashed password
    if not check_password_hash(db_user["password"], user.password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email or password",
        )

    # Return user data along with the success message
    return {
        "message": "Sign-in successful",
        "user_id": str(db_user["_id"]),
        "name": db_user["name"],
        "email": db_user["email"],
    }

# Optional: Add a health check endpoint
@app.get("/health/")
async def health_check():
    return {"status": "healthy"}