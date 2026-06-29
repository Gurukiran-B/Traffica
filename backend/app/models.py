from typing import Dict, List, Tuple, Optional
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime


class Edge(BaseModel):
    source: str
    target: str
    weight: float


class GraphInput(BaseModel):
    # Either edges or adjacency can be provided; edges is preferred for simplicity
    edges: List[Edge] = Field(default_factory=list)
    adjacency: Optional[Dict[str, List[Tuple[str, float]]]] = None
    start: str
    end: str
    # Heuristic per node for A*; optional
    heuristic: Optional[Dict[str, float]] = None
    # Optional factors to scale edge weights (traffic, weather, priority)
    traffic_factor: float = 1.0
    weather_factor: float = 1.0
    priority_factor: float = 1.0


class RouteResult(BaseModel):
    path: List[str]
    total_cost: float
    eta_minutes: float
    distance_km: Optional[float] = None


class HealthStatus(BaseModel):
    status: str
    version: str = "1.0"


class CongestionPrediction(BaseModel):
    timestamp: datetime
    level: float  # 0-1 scale
    description: str


class TrafficPrediction(BaseModel):
    location: str
    predictions: List[CongestionPrediction]


class VehicleStatus(BaseModel):
    id: str
    status: str  # e.g., "en_route", "idle", "maintenance"
    current_location: str
    eta_minutes: Optional[float] = None
    source: Optional[str] = None  # Pickup location for deliveries
    destination: Optional[str] = None  # Delivery destination


class FleetStatus(BaseModel):
    vehicles: List[VehicleStatus]


class OptimalRouteInput(BaseModel):
    from_location: str
    to_location: str
    time: Optional[datetime] = None
    weather_condition: Optional[str] = None  # e.g., "rain", "clear"
    start_lat: Optional[float] = None
    start_lng: Optional[float] = None
    end_lat: Optional[float] = None
    end_lng: Optional[float] = None


class WeatherData(BaseModel):
    location: str
    temperature: float
    condition: str  # e.g., "clear", "rain", "cloudy"
    humidity: float
    wind_speed: float


class DeliverySearchResult(BaseModel):
    address: str
    city: str
    state: str
    pincode: str
    latitude: float
    longitude: float
    delivery_type: str  # "standard", "express", "same_day"
    delivery_fee: float
    estimated_time_minutes: int


class RealtimeRouteInput(BaseModel):
    start_lat: float
    start_lng: float
    end_lat: float
    end_lng: float
    traffic_factor: float = 1.0
    weather_factor: float = 1.0
    priority_factor: float = 1.0


class RoadAlert(BaseModel):
    location: str
    type: str
    description: str
    estimated_delay_minutes: int
    image_url: str
    source: str
    destination: str


# User models for authentication APIs

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)


class UserLogin(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)


class UserResponse(BaseModel):
    id: str
    username: str
    email: EmailStr


# New CommunityPhoto model for Community Feature
class CommunityPhoto(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str
    image_url: str
    latitude: float
    longitude: float
    route: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    description: Optional[str] = None
    likes: int = 0
    reports: int = 0

