from fastapi import FastAPI
from routes.auth_routes import router as auth_router

app = FastAPI()

app.include_router(auth_router, prefix="/auth")

@app.get("/")
def home():
    return {"message": "Welcome to the API"}