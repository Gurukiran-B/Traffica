# traffica

A Flutter app for traffic prediction, route optimization, and delivery management using open source solutions.

## Features

- **Map Visualization**: Interactive map with OpenStreetMap tiles
- **Navigation**: Route drawing and turn-by-turn navigation using OSRM API
- **Weather Integration**: Live weather data for route planning (with OpenWeatherMap API)
- **Traffic Prediction**: Real-time traffic data and predictions
- **Optimal Route Calculation**: AI-powered route optimization considering traffic and weather
- **Delivery Search**: Address search and delivery management

## Technology Stack

- **Frontend**: Flutter with flutter_map for mapping
- **Backend**: Python FastAPI with machine learning models
- **APIs**:
  - OSRM (Open Source Routing Machine) for routing
  - OpenWeatherMap for weather data
  - Custom backend API for traffic prediction and route optimization
- **Database**: PostgreSQL with PostGIS for spatial data

## Getting Started

1. Clone the repository
2. Install Flutter dependencies: `flutter pub get`
3. Set up the backend (see backend/README.md)
4. Configure API keys in `lib/core/config.dart`
5. Run the app: `flutter run`

## API Configuration

Update `lib/core/config.dart` with your API keys:

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';
  static const String osrmBaseUrl = 'https://router.project-osrm.org';
}
```

## Demo Data

The app includes demo addresses for testing:
- Bengaluru, New Delhi, Chennai, Mysuru, Hyderabad, Mumbai

Weather data falls back to believable mock data if API is unavailable.

## Notes

- Navigation and weather features are built with open source APIs and demo data
- HERE/MapmyIndia SDK is not required
- Location permissions are required for GPS-based features
