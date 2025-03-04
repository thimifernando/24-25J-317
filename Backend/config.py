import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
DB_NAME = "flutter_auth"
JWT_SECRET = os.getenv("JWT_SECRET", "your_jwt_secret")