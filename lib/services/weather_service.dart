import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = "7e46702b9023144ec79c139c543fee85";

  Future<Map<String, dynamic>?> getWeather(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather"
      "?lat=$latitude"
      "&lon=$longitude"
      "&appid=$apiKey"
      "&units=metric",
    );

    print(url);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    print(response.body);
    return null;
  }
}
