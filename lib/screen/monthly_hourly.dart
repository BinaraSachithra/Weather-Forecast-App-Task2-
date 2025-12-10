import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class MonthlyHourly extends StatefulWidget {
  const MonthlyHourly({Key? key}) : super(key: key);

  @override
  State<MonthlyHourly> createState() => _MonthlyHourlyState();
}

class _MonthlyHourlyState extends State<MonthlyHourly>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? weeklyData;
  String? userLocation;
  bool isLoading = true;
  String? errorMessage;
  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
    fetchLocationAndWeather();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchLocationAndWeather() async {
    try {
      Position position = await _determinePosition();
      double latitude = position.latitude;
      double longitude = position.longitude;

      await fetchUserLocation(latitude, longitude);
      await fetchWeatherData(latitude, longitude);
      await fetchWeeklyForecast(latitude, longitude); // Added weekly forecast

      setState(() {
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Unable to get weather data. Please check your connection.";
      });
    }
  }

  Future<void> fetchUserLocation(double latitude, double longitude) async {
    String? location = await _fetchFromOpenStreetMap(latitude, longitude);

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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'];
      }
    } catch (e) {
      print("Geocoding failed: $e");
    }
    return null;
  }

  Future<void> fetchWeeklyForecast(double latitude, double longitude) async {
    final String weeklyApiUrl =
        "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode,wind_speed_10m_max,uv_index_max&timezone=auto";

    try {
      final response = await http.get(Uri.parse(weeklyApiUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['daily'] != null) {
          setState(() {
            weeklyData = data['daily'];
          });
        }
      }
    } catch (e) {
      print("Weekly forecast error: $e");
    }
  }

  Future<void> fetchWeatherData(double latitude, double longitude) async {
    final String apiUrl =
        "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,weathercode,precipitation,cloud_cover";

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print("Weather data error: $e");
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

  String getWeatherIcon(int weatherCode) {
    Map<int, String> weatherIcons = {
      0: '☀️',
      1: '🌤️',
      2: '⛅',
      3: '☁️',
      45: '🌫️',
      48: '🌫️',
      51: '🌧️',
      53: '🌧️',
      55: '🌧️',
      56: '🌨️',
      57: '🌨️',
      61: '🌦️',
      63: '🌦️',
      65: '🌧️',
      66: '🌨️',
      67: '🌨️',
      71: '❄️',
      73: '❄️',
      75: '❄️',
      77: '🌨️',
      80: '🌦️',
      81: '🌦️',
      82: '🌧️',
      85: '🌨️',
      86: '🌨️',
      95: '⛈️',
      96: '⛈️',
      99: '⛈️',
    };
    return weatherIcons[weatherCode] ?? '🌍';
  }

  String getWeatherDescription(int weatherCode) {
    Map<int, String> descriptions = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Foggy',
      48: 'Rime fog',
      51: 'Light drizzle',
      53: 'Moderate drizzle',
      55: 'Dense drizzle',
      61: 'Slight rain',
      63: 'Moderate rain',
      65: 'Heavy rain',
      71: 'Slight snow',
      73: 'Moderate snow',
      75: 'Heavy snow',
      77: 'Snow grains',
      80: 'Slight rain showers',
      81: 'Moderate rain showers',
      82: 'Violent rain showers',
      85: 'Slight snow showers',
      86: 'Heavy snow showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm with hail',
      99: 'Heavy thunderstorm with hail',
    };
    return descriptions[weatherCode] ?? 'Unknown';
  }

  String getDayOfWeek(String dateString) {
    final date = DateTime.parse(dateString);
    final today = DateTime.now();

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String getFormattedDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM dd').format(date);
  }

  Widget _buildHourlyItem(int index) {
    final time = weatherData?['hourly']['time']?[index] ?? "N/A";
    final temp = weatherData?['hourly']['temperature_2m']?[index] ?? "N/A";
    final humidity = weatherData?['hourly']['relative_humidity_2m']?[index] ?? "N/A";
    final windSpeed = weatherData?['hourly']['wind_speed_10m']?[index] ?? "N/A";
    final weatherCode = weatherData?['hourly']['weathercode']?[index] ?? 0;
    final precipitation = weatherData?['hourly']['precipitation']?[index] ?? "0";

    DateTime dateTime = DateTime.parse(time);
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A67D8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$hour:$minute',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                getDayOfWeek(time),
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$temp°C',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.water_drop, size: 14, color: Color(0xFF4299E1)),
                        const SizedBox(width: 4),
                        Text(
                          '$humidity%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.water, size: 14, color: Color(0xFF4299E1)),
                        const SizedBox(width: 4),
                        Text(
                          '$precipitation mm',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      getWeatherIcon(weatherCode),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getWeatherDescription(weatherCode),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDayItem(int index) {
    final date = weeklyData?['time']?[index] ?? "N/A";
    final maxTemp = weeklyData?['temperature_2m_max']?[index] ?? "N/A";
    final minTemp = weeklyData?['temperature_2m_min']?[index] ?? "N/A";
    final precipitation = weeklyData?['precipitation_sum']?[index] ?? "0";
    final weatherCode = weeklyData?['weathercode']?[index] ?? 0;
    final windSpeed = weeklyData?['wind_speed_10m_max']?[index] ?? "N/A";
    final uvIndex = weeklyData?['uv_index_max']?[index] ?? "N/A";

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDayIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selectedDayIndex == index
                ? [
              const Color(0xFF667EEA),
              const Color(0xFF764BA2),
            ]
                : [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedDayIndex == index
                ? Colors.white.withOpacity(0.3)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              getDayOfWeek(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: selectedDayIndex == index ? Colors.white : const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              getFormattedDate(date),
              style: TextStyle(
                fontSize: 10,
                color: selectedDayIndex == index ? Colors.white.withOpacity(0.9) : const Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              getWeatherIcon(weatherCode),
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 3),
            Text(
              '$maxTemp°',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selectedDayIndex == index ? Colors.white : const Color(0xFF2D3748),
              ),
            ),
            Text(
              '$minTemp°',
              style: TextStyle(
                fontSize: 12,
                color: selectedDayIndex == index ? Colors.white.withOpacity(0.8) : const Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 12, color: selectedDayIndex == index ? Colors.white : const Color(0xFF4299E1)),
                const SizedBox(width: 4),
                Text(
                  '$precipitation mm',
                  style: TextStyle(
                    fontSize: 10,
                    color: selectedDayIndex == index ? Colors.white : const Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyDetailCard() {
    if (weeklyData == null || weeklyData!['time']?.length <= selectedDayIndex) {
      return Container();
    }

    final date = weeklyData!['time']![selectedDayIndex];
    final maxTemp = weeklyData!['temperature_2m_max']![selectedDayIndex];
    final minTemp = weeklyData!['temperature_2m_min']![selectedDayIndex];
    final precipitation = weeklyData!['precipitation_sum']![selectedDayIndex];
    final weatherCode = weeklyData!['weathercode']![selectedDayIndex];
    final windSpeed = weeklyData!['wind_speed_10m_max']![selectedDayIndex];
    final uvIndex = weeklyData!['uv_index_max']![selectedDayIndex];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getDayOfWeek(date),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                getFormattedDate(date),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  getWeatherIcon(weatherCode),
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  getWeatherDescription(weatherCode),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A5568),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailItem(
                icon: Icons.thermostat,
                label: 'High',
                value: '$maxTemp°C',
                color: Color(0xFFE53E3E),
              ),
              _buildDetailItem(
                icon: Icons.thermostat,
                label: 'Low',
                value: '$minTemp°C',
                color: Color(0xFF4299E1),
              ),
              _buildDetailItem(
                icon: Icons.water_drop,
                label: 'Rain',
                value: '$precipitation mm',
                color: Color(0xFF3182CE),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDetailItem(
                icon: Icons.air,
                label: 'Wind',
                value: '$windSpeed m/s',
                color: Color(0xFF48BB78),
              ),
              _buildDetailItem(
                icon: Icons.wb_sunny,
                label: 'UV Index',
                value: uvIndex.toString(),
                color: Color(0xFFED8936),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
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
                "Loading forecast...",
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
                  "Failed to load data",
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
                    "Retry",
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
            "No weather data available",
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 16,
            ),
          ),
        )
            : Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Weather Forecast",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 40,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_pin,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          userLocation ?? "Unknown Location",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF5A67D8),
                unselectedLabelColor: const Color(0xFF718096),
                indicatorColor: const Color(0xFF5A67D8),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(
                    child: Text(
                      "Hourly",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "Weekly",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "Details",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Hourly Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: weatherData?['hourly'] == null
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            color: Color(0xFF718096),
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Hourly data not available",
                            style: TextStyle(
                              color: Color(0xFF2D3748),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: (weatherData!['hourly']['time']?.length ?? 0).clamp(0, 12),
                      itemBuilder: (context, index) {
                        return _buildHourlyItem(index);
                      },
                    ),
                  ),

                  // Weekly Tab
                  weeklyData == null
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Color(0xFF718096),
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Weekly forecast not available",
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (weeklyData!['time']?.length ?? 0).clamp(0, 7),
                            itemBuilder: (context, index) {
                              return _buildWeeklyDayItem(index);
                            },
                          ),
                        ),
                        _buildWeeklyDetailCard(),
                      ],
                    ),
                  ),

                  // Details Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(
                          title: 'Current Conditions',
                          icon: Icons.info,
                          children: [
                            _buildInfoRow(
                              label: 'Weather',
                              value: getWeatherDescription(weatherData?['current_weather']?['weathercode'] ?? 0),
                            ),
                            _buildInfoRow(
                              label: 'Temperature',
                              value: '${weatherData?['current_weather']?['temperature'] ?? 'N/A'}°C',
                            ),
                            _buildInfoRow(
                              label: 'Wind Speed',
                              value: '${weatherData?['current_weather']?['windspeed'] ?? 'N/A'} m/s',
                            ),
                            _buildInfoRow(
                              label: 'Wind Direction',
                              value: '${weatherData?['current_weather']?['winddirection'] ?? 'N/A'}°',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          title: 'Air Quality',
                          icon: Icons.air,
                          children: [
                            _buildInfoRow(
                              label: 'Humidity',
                              value: '${weatherData?['hourly']?['relative_humidity_2m']?[0] ?? 'N/A'}%',
                            ),
                            _buildInfoRow(
                              label: 'Cloud Cover',
                              value: '${weatherData?['hourly']?['cloud_cover']?[0] ?? 'N/A'}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          title: 'Location Details',
                          icon: Icons.location_on,
                          children: [
                            _buildInfoRow(
                              label: 'Latitude',
                              value: '${weatherData?['latitude'] ?? 'N/A'}°',
                            ),
                            _buildInfoRow(
                              label: 'Longitude',
                              value: '${weatherData?['longitude'] ?? 'N/A'}°',
                            ),
                            _buildInfoRow(
                              label: 'Timezone',
                              value: weatherData?['timezone'] ?? 'N/A',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667EEA).withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5A67D8)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}