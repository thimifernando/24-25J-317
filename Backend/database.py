from pymongo import MongoClient
from config import MONGO_URI, DB_NAME

client = MongoClient("mongodb+srv://padumikeshala2000:Keshi#123@cluster0.9vgrn.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
db = client["greenhouse_db"]
users_collection = db["users"]