from fastapi import FastAPI, HTTPException, status, Body, Depends
from pymongo import MongoClient
from pydantic import BaseModel
from werkzeug.security import generate_password_hash, check_password_hash
import os
import datetime
from typing import Optional
from bson import ObjectId

from weed_detection.weed_detection import router as weed_router
from chilli_quality.quality import router as chilli_quality_router


app = FastAPI()

# Load MongoDB URI from environment variables
MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://ecommerce:admin1234@cluster0.2sqjp.mongodb.net/greeny")
client = MongoClient(MONGO_URI)
db = client["greeny"]
users_collection = db["users"]
recommendations_collection = db["recommendations"]
saved_recommendations_collection = db["saved_recommendations"]

# Define a User model for sign-up
class User(BaseModel):
    name: str
    email: str
    password: str

# Define a SignIn model for sign-in
class SignIn(BaseModel):
    email: str
    password: str

# Define a Recommendation model
class Recommendation(BaseModel):
    class_name: str  # Class name for recommendation
    title: str
    description: str

class SavedRecommendation(BaseModel):
    user_id: str
    title: str
    description: str
    class_name: str
    saved_at: Optional[datetime.datetime] = None

# Helper function to validate password strength
def validate_password_strength(password: str):
    if len(password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 8 characters long",
        )

# API Endpoint to add a user (Sign Up)
@app.post("/add_user/")
async def add_user(user: User):
    validate_password_strength(user.password)
    hashed_password = generate_password_hash(user.password)
    user_dict = {
        "name": user.name,
        "email": user.email,
        "password": hashed_password,
        "is_admin": False  # Ensure new users are not admins
    }

    # Check if user already exists
    if users_collection.find_one({"email": user.email}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already exists",
        )

    result = users_collection.insert_one(user_dict)
    return {"message": "User added", "user_id": str(result.inserted_id), "is_admin": False}

# API Endpoint to sign in a user
@app.post("/sign_in/")
async def sign_in(user: SignIn):
    db_user = users_collection.find_one({"email": user.email})

    if db_user is None or not check_password_hash(db_user["password"], user.password):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid email or password")

    return {
        "message": "Sign-in successful",
        "user_id": str(db_user["_id"]),  # Ensure this is converted to string
        "name": db_user["name"],
        "email": db_user["email"],
        "is_admin": db_user.get("is_admin", False)
    }

@app.get("/routes")
async def get_routes():
    return [{"path": route.path, "name": route.name} for route in app.routes]


# Recommendation endpoints
allowed_class_names = ["Curl Leaf", "Yellowish Leaf", "Spot Leaf"]

@app.post("/add_recommendation/")
async def add_recommendation(recommendation: Recommendation):
    if recommendation.class_name not in allowed_class_names:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid class name. Allowed values: " + ", ".join(allowed_class_names),
        )

    recommendations_collection.insert_one(recommendation.dict())
    return {"message": "Recommendation added"}

@app.get("/get_recommendations/")
async def get_recommendations(class_name: str = None):
    query = {}
    if class_name:
        query["class_name"] = class_name
    
    recommendations = []
    for doc in recommendations_collection.find(query):
        recommendations.append({
            "_id": str(doc["_id"]),
            "class_name": doc["class_name"],
            "title": doc["title"],
            "description": doc["description"]
        })
    
    return recommendations

# User-specific saved recommendations
@app.post("/save_recommendation/")
async def save_recommendation(
    title: str = Body(...),
    description: str = Body(...),
    class_name: str = Body(...),
    user_id: str = Body(...)
):
    print(f"Received save request for user_id: {user_id}")  # Add this line
    try:
        recommendation = {
            "user_id": user_id,
            "title": title,
            "description": description,
            "class_name": class_name,
            "saved_at": datetime.datetime.utcnow()
        }
        print(f"Storing recommendation: {recommendation}")  # Add this line
        result = saved_recommendations_collection.insert_one(recommendation)
        return {"message": "Recommendation saved", "id": str(result.inserted_id)}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error saving recommendation: {str(e)}"
        )

@app.get("/get_saved_recommendations/")
async def get_saved_recommendations(user_id: str):
    try:
        recommendations = []
        for doc in saved_recommendations_collection.find({"user_id": user_id}).sort("saved_at", -1):
            recommendations.append({
                "_id": str(doc["_id"]),
                "title": doc["title"],
                "description": doc["description"],
                "class_name": doc["class_name"],
                "saved_at": doc["saved_at"].isoformat()
            })
        return recommendations
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching recommendations: {str(e)}"
        )

@app.delete("/delete_recommendation/{recommendation_id}")
async def delete_recommendation(recommendation_id: str):
    try:
        result = recommendations_collection.delete_one(
            {"_id": ObjectId(recommendation_id)}
        )
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Recommendation not found")
        return {"message": "Recommendation deleted"}
    except:
        raise HTTPException(status_code=400, detail="Invalid ID format")
    

@app.put("/update_recommendation/{recommendation_id}")
async def update_recommendation(
    recommendation_id: str,
    new_title: str = Body(None),
    new_description: str = Body(None),
    new_class_name: str = Body(None)
):
    try:
        print(f"Received update request for {recommendation_id}")  # Debug log
        print(f"Data received - title: {new_title}, desc: {new_description}, class: {new_class_name}")  # Debug log
        
        update_data = {}
        if new_title is not None:
            update_data["title"] = new_title
        if new_description is not None:
            update_data["description"] = new_description
        if new_class_name is not None:
            if new_class_name not in allowed_class_names:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid class name. Allowed values: " + ", ".join(allowed_class_names),
                )
            update_data["class_name"] = new_class_name

        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update provided",
            )

        result = recommendations_collection.update_one(
            {"_id": ObjectId(recommendation_id)},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            raise HTTPException(status_code=404, detail="Recommendation not found or no changes made")
        
        return {"message": "Recommendation updated"}
    except Exception as e:
        print(f"Error in update: {str(e)}")  # Debug log
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
app.include_router(weed_router)
app.include_router(chilli_quality_router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)