# Weather App - Student Index Weather Lookup

A Flutter application that derives geographic coordinates from a student index number and fetches current weather data from the Open-Meteo API.

## Features

### ✅ Functional Requirements (All Implemented)

1. **Student Index Input**
   - Text field for entering student index (pre-filled with "194174B")
   - Real-time coordinate derivation as you type

2. **Coordinate Derivation**
   - Latitude: 5 + (firstTwoDigits / 10.0) → Range: 5.0 to 15.9
   - Longitude: 79 + (nextTwoDigits / 10.0) → Range: 79.0 to 89.9
   - Displays computed coordinates with 2 decimal precision

3. **Weather Fetching**
   - "Fetch Weather" button to retrieve current weather
   - Calls Open-Meteo API: `https://api.open-meteo.com/v1/forecast?latitude=LAT&longitude=LON&current_weather=true`
   - Displays:
     - Temperature (°C)
     - Wind speed (km/h)
     - Weather code (raw number)
     - Last update time (from device clock)

4. **Request URL Display**
   - Shows the exact API request URL in small text for verification

5. **Loading & Error Handling**
   - Loading indicator (circular progress) while fetching
   - Friendly error messages for:
     - Network failures
     - Timeouts (10 second limit)
     - Invalid index format
     - API errors

6. **Offline Caching**
   - Uses `shared_preferences` to cache last successful weather result
   - Shows "(cached)" tag when displaying offline data
   - Automatically loads cached data on app startup

## How It Works

### Coordinate Calculation Example
For student index "194174B":
- First two digits: **19**
- Next two digits: **41**
- Latitude: 5 + (19 / 10.0) = **6.90°**
- Longitude: 79 + (41 / 10.0) = **83.10°**

### Dependencies Used
```yaml
dependencies:
  flutter: sdk
  http: ^1.1.0              # For API calls
  shared_preferences: ^2.2.2 # For local caching
```

## Installation & Running

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   # For Chrome/Web
   flutter run -d chrome
   
   # For Windows
   flutter run -d windows
   
   # For Android/iOS
   flutter run
   ```

## API Information

**API Provider:** Open-Meteo (https://open-meteo.com/)
- **No API key required**
- **Endpoint:** `https://api.open-meteo.com/v1/forecast`
- **Parameters:**
  - `latitude`: Derived from student index
  - `longitude`: Derived from student index
  - `current_weather`: true

**Response includes:**
- Temperature (°C)
- Wind speed (km/h)
- Weather code (WMO code)

## UI Features

- **Material Design 3** with blue color scheme
- **Card-based layout** for organized information
- **Icons** for weather data visualization:
  - 🌡️ Temperature
  - 💨 Wind speed
  - ☁️ Weather code
  - ⏰ Last update time
- **Responsive error messages** with red background
- **Cached data indicator** with orange badge

## Error Handling

The app handles various error scenarios:
1. Invalid index format (non-numeric first 4 characters)
2. Index too short (less than 4 characters)
3. Network connection failures
4. Request timeouts
5. API response errors

## Offline Support

- Last successful weather data is automatically cached
- Cached data persists across app restarts
- Clear visual indicator when showing cached data
- App remains functional offline with cached information

## Testing

1. Enter a valid student index (e.g., 194174B)
2. Verify coordinates are calculated correctly
3. Click "Fetch Weather" to retrieve current weather
4. Check the request URL displayed at the bottom
5. Turn off internet and restart app to verify cached data

## Screenshots

The app displays:
- Student index input card
- Derived coordinates card
- Current weather card with all data
- Request URL for verification
- Loading states and error messages

---

**Built with Flutter** | **API: Open-Meteo** | **No API Key Required**
