import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _indexController = TextEditingController(
    text: '194174B',
  );

  double? _latitude;
  double? _longitude;
  String? _requestUrl;
  String? _lastUpdateTime;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCached = false;

  // Weather data
  double? _temperature;
  double? _windSpeed;
  int? _weatherCode;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }

  // Load cached weather data
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('last_weather_data');

      if (cachedData != null) {
        final data = json.decode(cachedData);
        setState(() {
          _temperature = data['temperature'];
          _windSpeed = data['windspeed'];
          _weatherCode = data['weathercode'];
          _latitude = data['latitude'];
          _longitude = data['longitude'];
          _requestUrl = data['request_url'];
          _lastUpdateTime = data['last_update'];
          _isCached = true;
        });
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Save weather data to cache
  Future<void> _cacheWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'temperature': _temperature,
        'windspeed': _windSpeed,
        'weathercode': _weatherCode,
        'latitude': _latitude,
        'longitude': _longitude,
        'request_url': _requestUrl,
        'last_update': _lastUpdateTime,
      };
      await prefs.setString('last_weather_data', json.encode(data));
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Derive coordinates from student index
  void _deriveCoordinates(String index) {
    if (index.length < 4) {
      setState(() {
        _errorMessage = 'Index must be at least 4 characters long';
        _latitude = null;
        _longitude = null;
      });
      return;
    }

    try {
      final firstTwo = int.parse(index.substring(0, 2));
      final nextTwo = int.parse(index.substring(2, 4));

      setState(() {
        _latitude = 5 + (firstTwo / 10.0);
        _longitude = 79 + (nextTwo / 10.0);
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Invalid index format. First 4 characters must be digits.';
        _latitude = null;
        _longitude = null;
      });
    }
  }

  // Fetch weather data from Open-Meteo API
  Future<void> _fetchWeather() async {
    final index = _indexController.text.trim();
    if (index.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a student index';
      });
      return;
    }

    _deriveCoordinates(index);

    if (_latitude == null || _longitude == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isCached = false;
    });

    try {
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=${_latitude!.toStringAsFixed(2)}&longitude=${_longitude!.toStringAsFixed(2)}&current_weather=true';

      setState(() {
        _requestUrl = url;
      });

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentWeather = data['current_weather'];

        final now = DateTime.now();
        final formattedTime =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

        setState(() {
          _temperature = currentWeather['temperature']?.toDouble();
          _windSpeed = currentWeather['windspeed']?.toDouble();
          _weatherCode = currentWeather['weathercode'];
          _lastUpdateTime = formattedTime;
          _isLoading = false;
        });

        // Cache the successful result
        await _cacheWeatherData();
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch weather data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage =
            'Request timed out. Please check your internet connection.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50), // Dark blue-grey top
              Color(0xFF34495E), // Blue-grey middle
              Color.fromARGB(255, 48, 76, 119), // Blue (button color)
              Color(0xFF1A1A2E), // Dark blue-black bottom
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Weather Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Real-time weather from your location',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // Main weather card
                  if (_temperature != null)
                    Center(
                      child: Column(
                        children: [
                          // Weather icon
                          Container(
                            height: 180,
                            child: _buildWeatherIcon(_weatherCode ?? 0),
                          ),

                          SizedBox(height: 20),

                          // Temperature
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_temperature!.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 120,
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                  height: 0.9,
                                ),
                              ),
                              Text(
                                '°C',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          // Weather description
                          Text(
                            _getWeatherDescription(_weatherCode ?? 0),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                            ),
                          ),

                          SizedBox(height: 8),

                          // Date and time
                          Text(
                            _lastUpdateTime ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),

                          SizedBox(height: 20),

                          // Cached indicator
                          if (_isCached)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.offline_bolt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Cached Data',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  SizedBox(height: 8),
                  // Weather details row
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: _buildInfoItem(
                        Icons.air,
                        'Wind Speed',
                        '${_windSpeed?.toStringAsFixed(1) ?? '0'} km/h',
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Student Index Input
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Index',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _indexController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g., 194174B',
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.length >= 4) {
                              _deriveCoordinates(value);
                            }
                          },
                        ),

                        if (_latitude != null && _longitude != null) ...[
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lat: ${_latitude!.toStringAsFixed(2)}°',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Lon: ${_longitude!.toStringAsFixed(2)}°',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Fetch Weather Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchWeather,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          31,
                          105,
                          216,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Fetch Weather',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(int weatherCode) {
    // Weather icons based on WMO codes
    IconData iconData;
    Color iconColor;

    if (weatherCode == 0) {
      iconData = Icons.wb_sunny;
      iconColor = Colors.amber.shade300;
    } else if (weatherCode <= 3) {
      iconData = Icons.wb_cloudy;
      iconColor = Colors.white70;
    } else if (weatherCode <= 67 || weatherCode <= 77) {
      iconData = Icons.grain;
      iconColor = Colors.lightBlue.shade200;
    } else if (weatherCode >= 80) {
      iconData = Icons.thunderstorm;
      iconColor = Colors.yellow.shade300;
    } else {
      iconData = Icons.cloud;
      iconColor = Colors.white70;
    }

    return Icon(
      iconData,
      size: 160,
      color: iconColor,
      shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
    );
  }

  String _getWeatherDescription(int weatherCode) {
    if (weatherCode == 0) return 'CLEAR SKY';
    if (weatherCode <= 3) return 'CLOUDY';
    if (weatherCode <= 67 || weatherCode <= 77) return 'RAINY';
    if (weatherCode >= 80) return 'THUNDERSTORM';
    return 'PARTLY CLOUDY';
  }
}
