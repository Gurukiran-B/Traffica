from __future__ import annotations

from fastapi import FastAPI, Query, HTTPException, status, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from fastapi import Body
from typing import Dict, List, Tuple, Optional
import math
import random
import time
from datetime import datetime, timedelta
from uuid import uuid4
import shutil
import os
import httpx
from dotenv import load_dotenv

load_dotenv()

from .models import (
    GraphInput, RouteResult, HealthStatus,
    TrafficPrediction, CongestionPrediction, FleetStatus, VehicleStatus,
    OptimalRouteInput, WeatherData, DeliverySearchResult, RealtimeRouteInput,
    CommunityPhoto
)
from .models import RoadAlert
from .algorithms import hybrid_route_enhanced, real_time_route_update, calculate_route_metrics, RouteNode

# Additional in-memory store for community photos

import json

community_photos: List[CommunityPhoto] = []

METADATA_FILE = "app/static/community_photos/photos_metadata.json"


# Directory to save uploaded photos
UPLOAD_DIR = "app/static/community_photos"

app = FastAPI(title="Traffica Backend", version="1.0")

if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/static", StaticFiles(directory="app/static"), name="static")

def load_photos_metadata():
    global community_photos
    if os.path.exists(METADATA_FILE):
        try:
            with open(METADATA_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                community_photos = [CommunityPhoto(**item) for item in data]
        except Exception as e:
            print(f"Failed to load photos metadata: {e}")

def save_photos_metadata():
    try:
        with open(METADATA_FILE, "w", encoding="utf-8") as f:
            json.dump([photo.dict() for photo in community_photos], f, indent=2)
    except Exception as e:
        print(f"Failed to save photos metadata: {e}")

load_photos_metadata()

# Endpoint to upload a community photo with metadata
@app.post("/community/upload_photo")
async def upload_photo(
    user_id: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    route: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    file: UploadFile = File(...)
):
    # Save uploaded file to disk
    filename = f"{uuid4()}_{file.filename}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Failed to save file: {str(e)}")

    image_url = f"/static/community_photos/{filename}"
    photo = CommunityPhoto(
        id=str(uuid4()),
        user_id=user_id,
        image_url=image_url,
        latitude=latitude,
        longitude=longitude,
        route=route,
        timestamp=datetime.utcnow(),
        description=description,
        likes=0,
        reports=0,
    )
    community_photos.append(photo)
    # Instead of just returning dict, include a success flag for frontend
    return {"success": True, "message": "Photo uploaded successfully", "photo": photo.dict()}

# Endpoint to get community feed photos with pagination and optional route filter
@app.get("/community/feed", response_model=List[CommunityPhoto])
async def get_community_feed(
    skip: int = 0,
    limit: int = 20,
    route: Optional[str] = None,
):
    results = community_photos
    if route:
        r = route.lower()
        results = [p for p in results if (p.route or "").lower().find(r) != -1]
    return results[skip : skip + limit]

# Endpoint to like a photo by id
@app.post("/community/like/{photo_id}")
async def like_photo(photo_id: str):
    for photo in community_photos:
        if photo.id == photo_id:
            photo.likes += 1
            return {"message": "Photo liked", "likes": photo.likes}
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Photo not found")

# Endpoint to report a photo by id
@app.post("/community/report/{photo_id}")
async def report_photo(photo_id: str):
    for photo in community_photos:
        if photo.id == photo_id:
            photo.reports += 1
            return {"message": "Photo reported", "reports": photo.reports}
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Photo not found")

# Dummy Bangalore road alert data (add to the top level of main.py)
ROAD_ALERTS = [
    RoadAlert(
        location="Outer Ring Road, Marathahalli",
        type="Construction",
        description="Major road construction near Marathahalli bridge. Single lane traffic.",
        estimated_delay_minutes=25,
        image_url="/static/images/consrtuction.jpeg",
        source="Bengaluru Central",
        destination="MG Road, Bengaluru"
    ),
    RoadAlert(
        location="Sarjapur Road",
        type="Potholes",
        description="Severe potholes reported on Sarjapur Road. Drive with caution.",
        estimated_delay_minutes=15,
        image_url="/static/images/potholes.jpg",
        source="Whitefield, Bengaluru",
        destination="Indiranagar, Bengaluru"
    ),
    RoadAlert(
        location="Bannerghatta Road",
        type="Water Logging",
        description="Water logging due to heavy rains. Traffic moving slowly.",
        estimated_delay_minutes=20,
        image_url="/static/images/waterlog.webp",
        source="Jayanagar, Bengaluru",
        destination="MG Road, Bengaluru"
    ),
    # Show no alerts for this popular pair (as a control)
]

import bcrypt
from fastapi import FastAPI, Query, HTTPException, status, UploadFile, File, Form, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from typing import Dict, List, Optional
from uuid import uuid4
import math

from .models import (
    GraphInput, RouteResult, HealthStatus,
    TrafficPrediction, CongestionPrediction, FleetStatus, VehicleStatus,
    OptimalRouteInput, WeatherData, DeliverySearchResult, RealtimeRouteInput,
    RoadAlert, UserCreate, UserLogin, UserResponse
)
from .algorithms import hybrid_route_enhanced, real_time_route_update, calculate_route_metrics, RouteNode

community_photos: List[CommunityPhoto] = []
METADATA_FILE = "app/static/community_photos/photos_metadata.json"
UPLOAD_DIR = "app/static/community_photos"

app = FastAPI(title="Traffica Backend", version="1.0")

if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

app.mount("/static", StaticFiles(directory="app/static"), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ROAD_ALERTS = [
    RoadAlert(
        location="Outer Ring Road, Marathahalli",
        type="Construction",
        description="Major road construction near Marathahalli bridge. Single lane traffic.",
        estimated_delay_minutes=25,
        image_url="/static/images/consrtuction.jpeg",
        source="Bengaluru Central",
        destination="MG Road, Bengaluru"
    ),
    RoadAlert(
        location="Sarjapur Road",
        type="Potholes",
        description="Severe potholes reported on Sarjapur Road. Drive with caution.",
        estimated_delay_minutes=15,
        image_url="/static/images/potholes.jpg",
        source="Whitefield, Bengaluru",
        destination="Indiranagar, Bengaluru"
    ),
    RoadAlert(
        location="Bannerghatta Road",
        type="Water Logging",
        description="Water logging due to heavy rains. Traffic moving slowly.",
        estimated_delay_minutes=20,
        image_url="/static/images/waterlog.webp",
        source="Jayanagar, Bengaluru",
        destination="MG Road, Bengaluru"
    ),
]

# In-memory user "database"
users_db: Dict[str, Dict] = {}  # Key: email, Value: user dict with id, username, email, hashed_password

@app.post("/users/signup", response_model=UserResponse)
async def user_signup(user: UserCreate = Body(...)):
    if user.email in users_db:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
    
    hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt())
    user_id = str(uuid4())
    
    users_db[user.email] = {
        "id": user_id,
        "username": user.username,
        "email": user.email,
        "hashed_password": hashed_password,
    }
    
    return UserResponse(id=user_id, username=user.username, email=user.email)

@app.post("/users/login")
async def user_login(user: UserLogin = Body(...)):
    stored_user = users_db.get(user.email)
    if not stored_user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    
    if not bcrypt.checkpw(user.password.encode('utf-8'), stored_user["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    
    return JSONResponse({"message": "Login successful", "user": {"id": stored_user["id"], "username": stored_user["username"], "email": stored_user["email"]}})

@app.get("/health", response_model=HealthStatus)
async def health() -> HealthStatus:
    return HealthStatus(status="ok")

@app.get("/road_alerts", response_model=List[RoadAlert])
async def get_road_alerts() -> List[RoadAlert]:
    return ROAD_ALERTS

@app.get("/alerts", response_model=List[RoadAlert])
async def alerts() -> List[RoadAlert]:
    return ROAD_ALERTS

@app.get("/alerts/search", response_model=List[RoadAlert])
async def search_alerts(source: str = "", destination: str = "") -> List[RoadAlert]:
    if not source and not destination:
        return ROAD_ALERTS

    src = source.lower()
    dst = destination.lower()
    matched: List[RoadAlert] = []
    for a in ROAD_ALERTS:
        loc = (a.location or "").lower()
        s = (a.source or "").lower()
        d = (a.destination or "").lower()
        if (src and (src in s or src in d or src in loc)) or (dst and (dst in s or dst in d or dst in loc)):
            matched.append(a)
    return matched

@app.get("/alerts/json")
async def alerts_json(source: str = "", destination: str = "") -> List[dict]:
    alerts = await search_alerts(source, destination)
    results: List[dict] = []
    for a in alerts:
        ad = a.dict()
        ad["image_url"] = ad.get("image_url") or ad.get("image") or ""
        ad["image"] = ad["image_url"]
        results.append(ad)
    return results

@app.post("/optimal_route")
async def optimal_route(request: dict = Body(...)):
    edges = request.get("edges", [])
    start = request.get("start")
    end = request.get("end")
    nodes_data = None
    route, total_cost, node_to_idx = hybrid_route_enhanced(
        edges,
        start,
        end,
        nodes_data=nodes_data
    )

    if math.isinf(total_cost) or total_cost == float('inf'):
        total_cost = -1.0

    metrics = calculate_route_metrics(route, {}, edges)

    response = {
        "path": route,
        "total_cost": total_cost,
        "metrics": metrics,
    }

    return JSONResponse(content=response)

# Endpoint to upload a community photo with metadata
@app.post("/community/upload_photo")
async def upload_photo(
    user_id: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    route: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    file: UploadFile = File(...)
):
    filename = f"{uuid4()}_{file.filename}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to save file: {str(e)}")

    image_url = f"/static/community_photos/{filename}"
    photo = CommunityPhoto(
        id=str(uuid4()),
        user_id=user_id,
        image_url=image_url,
        latitude=latitude,
        longitude=longitude,
        route=route,
        timestamp=datetime.utcnow(),
        description=description,
        likes=0,
        reports=0,
    )
    community_photos.append(photo)
    return {"success": True, "message": "Photo uploaded successfully", "photo": photo.dict()}

@app.get("/community/feed", response_model=List[CommunityPhoto])
async def get_community_feed(skip: int = 0, limit: int = 20, route: Optional[str] = None):
    results = community_photos
    if route:
        r = route.lower()
        results = [p for p in results if (p.route or "").lower().find(r) != -1]
    return results[skip : skip + limit]
