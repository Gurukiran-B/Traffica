# TODO: Integrate HERE Maps and Navigation

## Dependency Updates
- [x] Add here_sdk dependency to pubspec.yaml (reverted due to package unavailability - using open source alternatives)

## Configuration
- [x] Update lib/core/config.dart to include HERE API credentials (REST Key, ClientId, ClientSecret) - kept for future use

## Widget Updates
- [x] Enhanced lib/widgets/map_widget.dart with navigation features (route drawing, location markers, ETA, distance, cost display)

## Screen Enhancements
- [x] Update lib/screens/map_screen.dart to allow source/destination input (addresses/coordinates), dummy address suggestions
- [x] Integrate OSRM for routing with ETA, distance, cost
- [x] Add weather tab functionality using OpenWeatherMap or mock data for selected destination
- [x] Improve error handling with user-friendly messages for API/network/location errors

## Service Updates
- [x] Create weather_service.dart for OpenWeatherMap integration
- [x] Enhance navigation_service.dart to parse OSRM response for ETA, distance, cost

## Platform/Permissions
- [x] Configure Android manifest for location permissions
- [x] Configure iOS Info.plist for location permissions
- [x] Ensure smooth location permission flows across Android/iOS/Web

## Testing and Followup
- [ ] Run flutter pub get after updating pubspec.yaml
- [ ] Test app on device/emulator for map display and basic navigation
- [ ] Handle any SDK initialization or API errors
- [ ] Critical-path testing: route display, navigation, weather fetching, demo addresses, permission handling, error handling on all platforms
- [ ] Test demo routes: Bengaluru → New Delhi, Chennai → Mysuru, Hyderabad → Mumbai
- [ ] Update README.md with notes on open source APIs and demo data
- [ ] Provide final test checklist with screenshots
