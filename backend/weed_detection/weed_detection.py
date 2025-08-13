import asyncio
import os
from concurrent.futures import ThreadPoolExecutor
from functools import partial

import cv2
import numpy as np
import base64
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from tensorflow.keras.models import load_model

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(BASE_DIR, "model", "weed_nonweed_model.h5")

try:
    model = load_model(model_path, compile=False)
except Exception as e:
    raise RuntimeError("Failed to load model weed_nonweed_model.h5") from e

KERNEL = np.ones((5, 5), np.uint8)

def preprocess_image(image: np.array) -> np.array:
    processed = cv2.resize(image, (224, 224))
    processed = processed.astype("float32") / 255.0
    processed = np.expand_dims(processed, axis=0)
    return processed

def extract_plant_crops(image: np.array, min_area=200):
    """
    Detects green blobs (plants) and returns (crop, bbox) for each.
    """
    hsv = cv2.cvtColor(image, cv2.COLOR_RGB2HSV)
    lower_green = np.array([25, 40, 40])
    upper_green = np.array([85, 255, 255])
    mask = cv2.inRange(hsv, lower_green, upper_green)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, KERNEL, iterations=2)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, KERNEL, iterations=2)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    crops = []
    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)
        if w * h >= min_area:
            crop = image[y:y+h, x:x+w]
            crops.append((crop, (x, y, w, h)))
    return crops

def classify_plant_crops_batched(crops, model, threshold=0.5, batch_size=32):
    """
    Classifies all crops in *one* model.predict() call.

    Returns (weed_bboxes, chili_bboxes)
    """
    if not crops:
        return [], []

    # Build one big tensor:  (N, 224, 224, 3)
    batch = np.vstack([preprocess_image(c)[0:1] for c, _ in crops])
    preds = model.predict(
        batch,
        batch_size=min(batch_size, len(batch)),
        verbose=0,
    )

    weed, chili = [], []
    for (crop, bbox), p in zip(crops, preds):
        # binary or two-class softmax / sigmoid both handled here
        is_weed = (p[0] > threshold) if p.shape[0] == 1 else (p[0] > p[1])
        (x, y, w, h) = bbox
        (weed if is_weed else chili).append((x, y, w, h))

    return weed, chili

def draw_bounding_boxes(original_image: np.array,
                        weed_bboxes: list,
                        chili_bboxes: list,
                        thickness: int = 4):          #  ← default was 2
    """
    Draws boxes around weeds (red) and chilis (green, for debugging).
    """
    annotated = original_image.copy()

    # Weed   ⇒ red
    for x, y, w, h in weed_bboxes:
        cv2.rectangle(
            annotated, (x, y), (x + w, y + h),
            (255, 0, 0), thickness
        )

    # Chili  ⇒ green  (comment out if you don’t need it)
    for x, y, w, h in chili_bboxes:
        cv2.rectangle(
            annotated, (x, y), (x + w, y + h),
            (0, 255, 0), thickness
        )

    _, buf = cv2.imencode(".jpg", cv2.cvtColor(annotated, cv2.COLOR_RGB2BGR))
    return base64.b64encode(buf).decode("utf-8")


executor = ThreadPoolExecutor(max_workers=2)

@router.websocket("/ws/detect_weed")
async def detect_weed_ws(websocket: WebSocket):
    """
    Receives JPEG/PNG frames, returns JSON with the
    bounding boxes of *weeds* in real time.
    """
    await websocket.accept()
    loop = asyncio.get_running_loop()

    try:
        while True:
            frame_bytes = await websocket.receive_bytes()

            img_arr = np.frombuffer(frame_bytes, np.uint8)
            frame_bgr = cv2.imdecode(img_arr, cv2.IMREAD_COLOR)
            if frame_bgr is None:
                await websocket.send_json({"error": "Decoding failed"})
                continue
            frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)

            weed_bboxes, chili_bboxes = await loop.run_in_executor(
                executor,
                partial(_detect, frame_rgb)
            )

            annotated_b64 = await loop.run_in_executor(
                executor,
                partial(draw_bounding_boxes,
                        frame_rgb, weed_bboxes, chili_bboxes)
            )

            await websocket.send_json({
                "image_width":  frame_rgb.shape[1],
                "image_height": frame_rgb.shape[0],
                "num_weeds":    len(weed_bboxes),
                "bounding_boxes": [
                    {"x": x, "y": y, "width": w, "height": h}
                    for x, y, w, h in weed_bboxes
                ],
                "annotated_image": annotated_b64,
            })

    except WebSocketDisconnect:
        print("Client disconnected")


# helper so run_in_executor only needs one arg
def _detect(frame_rgb: np.ndarray):
    crops = extract_plant_crops(frame_rgb)
    return classify_plant_crops_batched(crops, model)

