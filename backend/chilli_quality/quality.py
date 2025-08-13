import os
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from io import BytesIO
from PIL import Image
import numpy as np
import tensorflow as tf
import base64
import hashlib
import cv2
from collections import Counter

router = APIRouter()


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(BASE_DIR, "model", "chili_pepper_trained_3class.keras")


try:
    MODEL = tf.keras.models.load_model(model_path)
    print("Model Loaded Successfully")
except Exception as e:
    print(f"Error Loading Model: {e}")
    MODEL = None


CLASS_NAMES = ["chilli_anthracnose", "chilli_healthy", "chilli_red"]


def read_file_as_image(data) -> np.ndarray:
    """Convert file bytes to a numpy array image and print its size."""
    image = np.array(Image.open(BytesIO(data)))
    print("Image size (height, width, channels):", image.shape)
    return image


def split_and_find_boxes(orig_img, mask, label, w, h, min_area=500):
    """
    Given a binary mask, separate touching blobs via watershed and
    return one bounding box per pepper.
    """
    kernel = np.ones((3,3), np.uint8)
    opening = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=2)

    sure_bg = cv2.dilate(opening, kernel, iterations=3)

    dist = cv2.distanceTransform(opening, cv2.DIST_L2, 5)
    _, sure_fg = cv2.threshold(dist, 0.5 * dist.max(), 255, 0)
    sure_fg = np.uint8(sure_fg)

    unknown = cv2.subtract(sure_bg, sure_fg)

    _, markers = cv2.connectedComponents(sure_fg)
    markers = markers + 1
    markers[unknown == 255] = 0

    ws_img = orig_img.copy()
    cv2.watershed(ws_img, markers)

    boxes = []
    for marker_val in np.unique(markers):
        if marker_val <= 1:
            continue
        single_pepper = np.uint8(markers == marker_val)
        x, y, bw, bh = cv2.boundingRect(single_pepper)
        area = bw * bh
        if area < min_area:
            continue
        boxes.append({
            "x": x / w,
            "y": y / h,
            "width": bw / w,
            "height": bh / h,
            "class": label
        })
    return boxes


def looks_like_a_chilli(patch: np.ndarray) -> bool:
    """
    Run the Keras model on a cropped patch and return True only when the model
    says the patch is a chilli class (i.e. not "others").
    """
    if patch.size == 0:
        return False

    H, W = MODEL.input_shape[1:3]
    patch = cv2.resize(patch, (W, H))
    patch = patch.astype("float32") / 255.0
    patch = np.expand_dims(patch, axis=0)

    preds = MODEL.predict(patch, verbose=0)
    cls = CLASS_NAMES[int(np.argmax(preds[0]))]
    return cls in CLASS_NAMES


@router.post("/detect-quality/")
async def detect_quality(file: UploadFile = File(...)):
    """
    Detect pepper quality and draw coloured contours for
    chilli_red, chilli_healthy and chilli_anthracnose
    """
    if MODEL is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    try:
        image_data = await file.read()
        raw = read_file_as_image(image_data)

        model_img = raw

        if raw.dtype != np.uint8:
            bgr = np.clip(raw * 255, 0, 255).astype(np.uint8)
        else:
            bgr = raw.copy()
        bgr = cv2.cvtColor(bgr, cv2.COLOR_RGB2BGR)

        h, w = bgr.shape[:2]

        hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)

        lower_g, upper_g = np.array([36,  50, 70]), np.array([89, 255, 255])
        mask_g = cv2.inRange(hsv, lower_g, upper_g)

        lower_r1, upper_r1 = np.array([0,  120, 70]), np.array([10, 255, 255])
        lower_r2, upper_r2 = np.array([170,120,70]), np.array([180,255,255])
        mask_r = cv2.inRange(hsv, lower_r1, upper_r1) | cv2.inRange(hsv, lower_r2, upper_r2)

        lower_anthracnose = np.array([10, 100, 20])
        upper_anthracnose = np.array([25, 255, 255])
        mask_anthracnose  = cv2.inRange(hsv, lower_anthracnose, upper_anthracnose)

        red_boxes         = split_and_find_boxes(bgr, mask_r,          "chilli_red",         w, h)
        green_boxes       = split_and_find_boxes(bgr, mask_g,          "chilli_healthy",     w, h)
        anthracnose_boxes = split_and_find_boxes(bgr, mask_anthracnose,"chilli_anthracnose", w, h)

        all_boxes = red_boxes + green_boxes + anthracnose_boxes

        box_classes = [b["class"] for b in all_boxes]
        class_counts = Counter(box_classes)
        unique_classes = set(class_counts)
        total_chilli = sum(class_counts.values())

        colour_map = {
            "chilli_red"        : (  0,   0, 255),  # red
            "chilli_healthy"    : (  0, 255,   0),  # green
            "chilli_anthracnose": (255,   0,   0),  # blue
        }

        annotated = bgr.copy()
        for box in all_boxes:
            x1 = int(box["x"] * w)
            y1 = int(box["y"] * h)
            x2 = x1 + int(box["width"] * w)
            y2 = y1 + int(box["height"] * h)

            x1, y1 = max(x1, 0), max(y1, 0)
            x2, y2 = min(x2, w - 1), min(y2, h - 1)

            crop_rgb = raw[y1:y2, x1:x2]
            if not looks_like_a_chilli(crop_rgb):
                continue

            colour = colour_map.get(box["class"], (255, 255, 255))
            cv2.rectangle(annotated, (x1, y1), (x2, y2), colour, 2)

        if unique_classes:
            if len(unique_classes) == 1:
                predicted_class = next(iter(unique_classes))
                confidence = class_counts[predicted_class] / total_chilli
            else:  # ➌ MIX CASE
                predicted_class = "Mix"
                confidence = None
            verdict = lambda c: (
                "High-level market" if c == "chilli_healthy" else "Not suitable for market"
            )
            market_recommendation = "\n".join(
                f"{c.replace('chilli_', '').replace('_', ' ').title()}: {verdict(c)}"
                for c in sorted(unique_classes)
            )
        else:
            img_batch = np.expand_dims(model_img, axis=0)
            preds = MODEL.predict(img_batch, verbose=0)
            idx = int(np.argmax(preds[0]))
            predicted_class = CLASS_NAMES[idx]
            confidence = float(preds[0][idx])
            market_recommendation = (
                "High-level market" if predicted_class == "chilli_healthy"
                else "Not suitable for market"
            )

        _, buf = cv2.imencode('.jpg', annotated)
        img_b64_annotated = base64.b64encode(buf).decode('utf-8')

        record = {
            "class": predicted_class,
            "confidence": confidence,
            "market_recommendation": market_recommendation,
            "boxes": all_boxes,
            "counts": dict(class_counts),
            "image_annotated": img_b64_annotated,
        }
        return JSONResponse(content=record)

    except Exception as e:
        print(f"Error in detect_quality: {e}")
        raise HTTPException(status_code=500, detail="Error processing the image")
