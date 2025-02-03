from fastapi import FastAPI, File, UploadFile
import numpy as np
import io
from PIL import Image
import cv2
from tensorflow import keras
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from ultralyticsplus import YOLO, render_result


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

disease_model = keras.models.load_model('tomato_disease.h5')


leaf_model = YOLO('foduucom/plant-leaf-detection-and-classification')
leaf_model.overrides['conf'] = 0.25  
leaf_model.overrides['iou'] = 0.45  
leaf_model.overrides['agnostic_nms'] = False  
leaf_model.overrides['max_det'] = 1000  


face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

def read_image(image):
    img = Image.open(io.BytesIO(image))
    img = img.resize((256, 256))
    img = np.array(img)
    return img

def crop_leaf(image, leaf_results):
    """Crop the leaf from the detected bounding box."""
    original_image = np.array(image)
    boxes = leaf_results[0].boxes.xyxy  
    if len(boxes) > 0: 
        x_min, y_min, x_max, y_max = map(int, boxes[0])  
        cropped = original_image[y_min:y_max, x_min:x_max]
        return cropped
    return original_image  

disease_profiles = {
     "Tomato_Bacterial_spot": {
        "name": "Bacterial Spot",
        "severity": "Severe",
        "harmfulness": "Can cause severe yield loss",
        "prevention": [
            "Use certified disease-free seeds",
            "Avoid working in wet fields",
            "Remove and destroy infected plants",
            "Practice crop rotation"
        ],
        "treatment": "Limited chemical control; copper-based bactericides may reduce spread",
        "pesticide": [
            "Copper-based bactericides"
        ],
        "confidence": ""
    },
    "Tomato_Early_blight": {
        "name": "Early Blight",
        "severity": "Moderate",
        "harmfulness": "Can reduce yield if not managed",
        "prevention": [
            "Use resistant varieties",
            "Ensure proper spacing for air circulation",
            "Remove plant debris",
            "Practice crop rotation"
        ],
        "treatment": "Apply fungicides when necessary",
        "pesticide": [
            "Chlorothalonil",
            "Mancozeb",
            "Copper-based fungicides"
        ],
        "confidence": ""
    },
    "Tomato_Late_blight": {
        "name": "Late Blight",
        "severity": "Severe",
        "harmfulness": "Can destroy entire crops rapidly",
        "prevention": [
            "Use resistant varieties",
            "Remove volunteer plants",
            "Avoid overhead irrigation"
        ],
        "treatment": "Prompt application of effective fungicides",
        "pesticide": [
            "Chlorothalonil",
            "Mancozeb",
            "Copper-based fungicides"
        ],
        "confidence": ""
    },
    "Tomato_Leaf_Mold": {
        "name": "Leaf Mold",
        "severity": "Moderate",
        "harmfulness": "Affects leaves, leading to reduced photosynthesis",
        "prevention": [
            "Ensure good air circulation",
            "Avoid overhead irrigation",
            "Remove and destroy infected leaves"
        ],
        "treatment": "Apply fungicides if necessary",
        "pesticide": [
            "Chlorothalonil",
            "Copper-based fungicides"
        ],
        "confidence": ""
    },
    "Tomato_Septoria_leaf_spot": {
        "name": "Septoria Leaf Spot",
        "severity": "Moderate",
        "harmfulness": "Causes defoliation, reducing yield",
        "prevention": [
            "Use disease-free seeds",
            "Avoid overhead irrigation",
            "Remove infected leaves",
            "Implement crop rotation"
        ],
        "treatment": "Apply fungicides as needed",
        "pesticide": [
            "Chlorothalonil",
            "Copper-based fungicides"
        ],
        "confidence": ""
    },
    "Tomato_Spider_mites_Two_spotted_spider_mite": {
        "name": "Two-Spotted Spider Mite",
        "severity": "Moderate",
        "harmfulness": "Causes leaf discoloration and reduces photosynthesis",
        "prevention": [
            "Avoid drought stress",
            "Encourage natural predators like ladybugs"
        ],
        "treatment": "Apply miticides if infestation is severe",
        "pesticide": [
            "Abamectin",
            "Bifenazate"
        ],
        "confidence": ""
    },
    "Tomato__Target_Spot": {
        "name": "Target Spot",
        "severity": "Moderate to Severe",
        "harmfulness": "Leads to defoliation and fruit lesions",
        "prevention": [
            "Ensure proper plant spacing",
            "Remove crop residues",
            "Practice crop rotation"
        ],
        "treatment": "Apply appropriate fungicides",
        "pesticide": [
            "Azoxystrobin",
            "Chlorothalonil"
        ],
        "confidence": ""
    },
    "Tomato__Tomato_YellowLeaf__Curl_Virus": {
        "name": "Tomato Yellow Leaf Curl Virus",
        "severity": "Severe",
        "harmfulness": "Causes stunted growth and significant yield loss",
        "prevention": [
            "Control whiteflies (vectors)",
            "Use resistant varieties",
            "Employ reflective mulches to deter vectors"
        ],
        "treatment": "No direct treatment; focus on controlling vector populations",
        "pesticide": [
            "Insecticides against whiteflies like imidacloprid"
        ],
        "confidence": ""
    },
    "Tomato__Tomato_mosaic_virus": {
        "name": "Tomato Mosaic Virus",
        "severity": "Moderate to Severe",
        "harmfulness": "Can cause significant yield loss",
        "prevention": [
            "Use virus-free seeds",
            "Practice crop rotation",
            "Sanitize tools and equipment",
            "Control weeds that may host the virus"
        ],
        "treatment": "No chemical treatment available; remove and destroy infected plants",
        "pesticide": "Not applicable",
        "confidence": ""
    },
    "Tomato_healthy": {
        "name": "Healthy",
        "severity": "None",
        "harmfulness": "None",
        "prevention": [
            "Maintain good agricultural practices",
            "Monitor plants regularly for early detection of issues"
        ],
        "treatment": "Not required",
        "pesticide": "Not applicable",
        "confidence": ""
    },
    "Not_a_leaf": {
        "name": "Not a Leaf",
        "severity": "None",
        "harmfulness": "Not applicable",
        "prevention": [],
        "treatment": "Ensure to upload a valid leaf",
        "pesticide": [],
        "confidence": ""
    },
    "Human_detected": {
        "name": "Human Detected",
        "severity": "None",
        "harmfulness": "Not applicable",
        "prevention": [],
        "treatment": "This is a photo of a human.",
        "pesticide": [],
        "confidence": ""
    }
}

@app.get('/')
async def home():
    return "Welcome to the enhanced tomato disease detection app"

@app.post('/detect')
async def detect(file: UploadFile = File(...)):
   
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    image_np = np.array(image)

  
    leaf_results = leaf_model.predict(image_np)
    if len(leaf_results[0].boxes) > 0:  
   
        cropped_image = crop_leaf(image, leaf_results)
        cropped_image = cv2.resize(cropped_image, (256, 256))
        cropped_image = np.expand_dims(cropped_image, axis=0)

      
        prediction = disease_model.predict(cropped_image)
        pred = np.argmax(prediction.tolist())
        confidence = float(np.max(prediction[0]))
        class_labels = ['Tomato_Bacterial_spot', 'Tomato_Early_blight', 'Tomato_Late_blight', 
                        'Tomato_Leaf_Mold', 'Tomato_Septoria_leaf_spot', 
                        'Tomato_Spider_mites_Two_spotted_spider_mite', 
                        'Tomato__Target_Spot', 'Tomato__Tomato_YellowLeaf__Curl_Virus', 
                        'Tomato__Tomato_mosaic_virus', 'Tomato_healthy']

        predicted_class = class_labels[pred]

      
        disease_profile = disease_profiles.get(predicted_class, {
            "name": "Unknown",
            "severity": "Unknown",
            "harmfulness": "Unknown",
            "prevention": [],
            "treatment": "Not available",
            "pesticide": [],
            "confidence": ""
        })


        disease_profile["confidence"] = confidence

        return JSONResponse(content={"prediction": disease_profile})

 
    gray_image = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
    faces = face_cascade.detectMultiScale(gray_image, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))
    if len(faces) > 0:  
        response = disease_profiles["Human_detected"]
        response["confidence"] = 1.0 
        return JSONResponse(content={"prediction": response})

    response = disease_profiles["Not_a_leaf"]
    response["confidence"] = 0.0
    return JSONResponse(content={"prediction": response})

