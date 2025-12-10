import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic>? weatherData;
  String? userLocation;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchLocationAndWeather();
  }

  Future<void> fetchLocationAndWeather() async {
    try {
      Position position = await _determinePosition();
      double latitude = position.latitude;
      double longitude = position.longitude;

      // Fetch location (don't throw if this fails)
      await fetchUserLocation(latitude, longitude);

      // Fetch weather data
      await fetchWeatherData(latitude, longitude);

      // Only set loading to false after weather data is loaded
      setState(() {
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Unable to get weather data. Please check your connection.";
      });
      print("Error in fetchLocationAndWeather: $e");
    }
  }

  Future<void> fetchUserLocation(double latitude, double longitude) async {
    // Try OpenStreetMap first
    String? location = await _fetchFromOpenStreetMap(latitude, longitude);

    // If failed, use coordinates
    if (location == null) {
      location = '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°';
    }

    setState(() {
      userLocation = location;
    });
  }

  Future<String?> _fetchFromOpenStreetMap(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude"),
        headers: {'User-Agent': 'WeatherApp/1.0'},
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'];
      }
    } catch (e) {
      print("OpenStreetMap geocoding failed: $e");
    }
    return null;
  }

  Future<void> fetchWeatherData(double latitude, double longitude) async {
    final String apiUrl =
        "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch weather data");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    return await Geolocator.getCurrentPosition();
  }

  String getWeatherCondition(int weatherCode) {
    Map<int, String> weatherConditions = {
      0: "☀️ Clear Sky",
      1: "🌤️ Mainly Clear",
      2: "⛅ Partly Cloudy",
      3: "☁️ Overcast",
      45: "🌫️ Fog",
      48: "🌫️ Depositing Rime Fog",
      51: "🌧️ Light Drizzle",
      53: "🌧️ Moderate Drizzle",
      55: "🌧️ Dense Drizzle",
      56: "❄️ Light Freezing Drizzle",
      57: "❄️ Dense Freezing Drizzle",
      61: "🌦️ Slight Rain",
      63: "🌦️ Moderate Rain",
      65: "🌧️ Heavy Rain",
      66: "❄️ Light Freezing Rain",
      67: "❄️ Heavy Freezing Rain",
      71: "❄️ Slight Snowfall",
      73: "❄️ Moderate Snowfall",
      75: "❄️ Heavy Snowfall",
      77: "🌨️ Snow Grains",
      80: "🌦️ Slight Rain Showers",
      81: "🌦️ Moderate Rain Showers",
      82: "🌧️ Violent Rain Showers",
      85: "🌨️ Slight Snow Showers",
      86: "🌨️ Heavy Snow Showers",
      95: "⛈️ Thunderstorm",
      96: "⛈️ Thunderstorm with Slight Hail",
      99: "⛈️ Thunderstorm with Heavy Hail"
    };

    return weatherConditions[weatherCode] ?? "🌍 Unknown Weather";
  }

  Widget _buildWeatherCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF5A67D8),
              ),
              SizedBox(height: 20),
              Text(
                "Fetching your weather...",
                style: TextStyle(
                  color: Color(0xFF4A5568),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : errorMessage != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFE53E3E),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Oops! Something went wrong",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: fetchLocationAndWeather,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A67D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "Try Again",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            : weatherData == null
            ? const Center(
          child: Text(
            "Failed to load weather data",
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 16,
            ),
          ),
        )
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Weather",
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Live Forecast",
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFF5A67D8),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Location Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Current Location",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userLocation ?? "Unknown Location",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      Divider(
                        color: Colors.white.withOpacity(0.2),
                        height: 1,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Temperature",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${weatherData?['current_weather']['temperature']}°C",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              Text(
                                getWeatherCondition(
                                    weatherData?['current_weather']
                                    ['weathercode'] ??
                                        0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Updated Just Now",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Weather Details Grid
                const Text(
                  "Weather Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),

                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  children: [
                    _buildWeatherCard(
                      "Wind Speed",
                      "${weatherData?['current_weather']['windspeed']} m/s",
                      Icons.air,
                      const Color(0xFF4299E1),
                    ),
                    _buildWeatherCard(
                      "Wind Direction",
                      "${weatherData?['current_weather']['winddirection']}°",
                      Icons.navigation,
                      const Color(0xFF48BB78),
                    ),
                    _buildWeatherCard(
                      "Temperature",
                      "${weatherData?['current_weather']['temperature']}°C",
                      Icons.thermostat,
                      const Color(0xFFED8936),
                    ),
                    _buildWeatherCard(
                      "Weather",
                      getWeatherCondition(
                          weatherData?['current_weather']
                          ['weathercode'] ??
                              0)
                          .replaceAll(RegExp(r'[^\x00-\x7F]+'), ''),
                      Icons.cloud,
                      const Color(0xFF9F7AEA),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Hourly Forecast Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Color(0xFF5A67D8),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Next 12 Hours",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${index + 1}h",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF718096),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Icon(
                                    Icons.wb_sunny,
                                    color: Color(0xFFED8936),
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${(weatherData?['current_weather']['temperature'] ?? 0) + index}°",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchLocationAndWeather,
        backgroundColor: const Color(0xFF5A67D8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.refresh,
          color: Colors.white,
        ),
      ),
    );
  }
}