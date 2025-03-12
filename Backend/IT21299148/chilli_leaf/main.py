from fastapi import FastAPI, File, UploadFile
from keras.models import load_model
from PIL import Image, ImageOps
import numpy as np
import io

app = FastAPI()

# Load the model
model = load_model("chilli_leaf_model.h5", compile=False)

# Hardcoded labels
class_names = ["Healthy Leaf", "Curl Leaf", "Yellowish Leaf", "Spot Leaf"]

@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    # Read image file
    image = Image.open(io.BytesIO(await file.read())).convert("RGB")

    # Resize and preprocess the image
    size = (224, 224)
    image = ImageOps.fit(image, size, Image.Resampling.LANCZOS)
    image_array = np.asarray(image)
    normalized_image_array = (image_array.astype(np.float32) / 127.5) - 1

    # Prepare input data
    data = np.ndarray(shape=(1, 224, 224, 3), dtype=np.float32)
    data[0] = normalized_image_array

    # Make prediction
    prediction = model.predict(data)
    index = np.argmax(prediction)
    class_name = class_names[index]
    confidence_score = float(prediction[0][index])

    return {"class": class_name, "confidence": confidence_score}
