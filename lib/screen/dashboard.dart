import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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

      await fetchUserLocation(latitude, longitude);
      await fetchWeatherData(latitude, longitude);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  Future<void> fetchUserLocation(double latitude, double longitude) async {
    final String geocodingUrl =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude";

    try {
      final response = await http.get(Uri.parse(geocodingUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userLocation = data['display_name']; // Extract the readable address
        });
      } else {
        throw Exception("Failed to fetch user location");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching location: $e";
      });
    }
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

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    // Check location permissions
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

    // Get the current location
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "Weather Forecast",
          style: TextStyle(
            color: Color.fromARGB(255, 66, 77, 228),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : weatherData == null
                  ? Center(child: Text("Failed to load weather data"))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (userLocation != null) ...[
                            Container(
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.all(12),
                              height: 240,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(0, 4),
                                    blurRadius: 5,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 55, 0, 255),
                                    Color.fromARGB(255, 36, 104, 250),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                // image: DecorationImage(
                                //   image: image,
                                //   fit: BoxFit.cover,
                                //   opacity: 0.1,
                                // ),
                              ),
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Your Location",
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "$userLocation",
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ])),
                            ),
                          ],
                          SizedBox(height: 20),
                          const Divider(height: 3),
                          SizedBox(height: 20),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.all(12),
                            height: 200,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(0, 4),
                                  blurRadius: 5,
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 55, 0, 255),
                                  Color.fromARGB(255, 36, 104, 250),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              // image: DecorationImage(
                              //   image: image,
                              //   fit: BoxFit.cover,
                              //   opacity: 0.1,
                              // ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Current Weather",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Temperature: ${weatherData?['current_weather']['temperature']}°C",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 70, 70),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Condition: ${getWeatherCondition(weatherData?['current_weather']['weathercode'] ?? 0)}",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 141, 255, 96),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Wind Speed: ${weatherData?['current_weather']['windspeed']} m/s",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 231, 255, 97),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
