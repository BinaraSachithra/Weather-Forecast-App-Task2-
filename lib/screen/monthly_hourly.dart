import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MonthlyHourly extends StatefulWidget {
  const MonthlyHourly({Key? key}) : super(key: key);

  @override
  State<MonthlyHourly> createState() => _MonthlyHourlyState();
}

class _MonthlyHourlyState extends State<MonthlyHourly>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Define the TabController
  Map<String, dynamic>? weatherData;
  String? userLocation;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Initialize with 2 tabs
    fetchLocationAndWeather();
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose of the TabController
    super.dispose();
  }

  Future<void> fetchLocationAndWeather() async {
    try {
      Position position = await _determinePosition();
      double latitude = position.latitude;
      double longitude = position.longitude;

      await fetchUserLocation(latitude, longitude);
      await fetchWeatherData(latitude, longitude);
      await fetchMonthlyForecast(latitude, longitude); // Added monthly forecast
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

  Future<void> fetchMonthlyForecast(double latitude, double longitude) async {
    final String dailyApiUrl =
        "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto";

    try {
      final response = await http.get(Uri.parse(dailyApiUrl));

      if (response.statusCode == 200) {
        final dailyData = jsonDecode(response.body)['daily'];
        if (dailyData != null) {
          setState(() {
            weatherData = weatherData ?? {}; // Initialize if null
            weatherData!['monthly'] = dailyData;
          });
        } else {
          throw Exception("Missing 'daily' data in response");
        }
      } else {
        throw Exception("Failed to fetch monthly forecast data");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching monthly forecast: $e";
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Hourly Forecast"),
            Tab(text: "Monthly Forecast"),
          ],
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
                          Container(
                            width: MediaQuery.of(context).size.width,
                            padding: EdgeInsets.all(12),
                            height: 230,
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
                            ),
                            child: Align(
                                alignment: Alignment.center,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "My Location",
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
                          SizedBox(height: 20),
                          const Divider(height: 3),
                          SizedBox(height: 20),

                          // TabBar View Section
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Hourly Forecast Tab
                                weatherData?['hourly'] == null
                                    ? Center(
                                        child: Text(
                                            "Hourly forecast not available"))
                                    : ListView.builder(
                                        itemCount: weatherData!['hourly']
                                                    ['time']
                                                ?.length ??
                                            0,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text(
                                              "Date & Time: ${weatherData!['hourly']['time'][index].replaceFirst('T', ' | ')}",
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 3, 102, 28),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "Temp: ${weatherData!['hourly']['temperature_2m'][index]}°C, "
                                              "Humidity: ${weatherData!['hourly']['relative_humidity_2m'][index]}%",
                                            ),
                                          );
                                        },
                                      ),

                                // Monthly Forecast Tab
                                weatherData?['monthly'] == null
                                    ? Center(
                                        child: Text(
                                            "Monthly forecast not available"))
                                    : ListView.builder(
                                        itemCount: weatherData!['monthly']
                                                    ['time']
                                                ?.length ??
                                            0,
                                        itemBuilder: (context, index) {
                                          final time = weatherData!['monthly']
                                                  ['time']?[index] ??
                                              "N/A";
                                          final maxTemp =
                                              weatherData!['monthly']
                                                          ['temperature_2m_max']
                                                      ?[index] ??
                                                  "N/A";
                                          final minTemp =
                                              weatherData!['monthly']
                                                          ['temperature_2m_min']
                                                      ?[index] ??
                                                  "N/A";
                                          final precipitation =
                                              weatherData!['monthly']
                                                          ['precipitation_sum']
                                                      ?[index] ??
                                                  "N/A";

                                          return ListTile(
                                            title: Text(
                                              "Date: $time",
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 3, 102, 28),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "Max Temp: $maxTemp°C, Min Temp: $minTemp°C, Precipitation: $precipitation mm",
                                            ),
                                          );
                                        },
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
