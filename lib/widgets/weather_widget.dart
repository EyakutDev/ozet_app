import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  // === BURAYA KENDİ OpenWeatherMap API ANAHTARINI YAPIŞTIR ===
  final String _apiKey = "1d52e9bf853dca3fbbf8895c54b334dd";
  // ==========================================================

  String _temperature = "...";
  String _condition = "Yükleniyor...";
  String _locationName = "...";
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _getWeatherByLocation();
  }

  Future<void> _getWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    // 1. Konum İzni İste
    var status = await Permission.location.request();

    if (status.isGranted) {
      try {
        // 2. Konumu (GPS) Al
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );

        String lang = "tr"; // Türkçe
        String units = "metric"; // Celcius

        // === HATA BURADA DÜZELTİLDİ (https://) ===
        Uri uri = Uri.parse(
          'https://api.openweathermap.org/data/2.5/onecall?lat=${position.latitude}&lon=${position.longitude}&exclude=minutely,hourly,alerts&appid=$_apiKey&units=$units&lang=$lang',
        );
        // === HATA DÜZELTİLDİ ===

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          setState(() {
            _locationName = data['timezone']
                .split('/')
                .last
                .replaceAll('_', ' ');
            var todayTemp = data['current']['temp'] as num;
            _temperature = todayTemp.round().toString(); // "15"
            var tomorrowCondition =
                data['daily'][1]['weather'][0]['description'] as String;
            _condition = tomorrowCondition.replaceFirst(
              tomorrowCondition[0],
              tomorrowCondition[0].toUpperCase(),
            ); // "Bulutlu"

            _isLoading = false;
          });
        } else {
          throw Exception(
            'Hava durumu verisi çekilemedi (API Hatası: ${response.statusCode})',
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _condition = "Hata oluştu";
          print("Hava Durumu Hatası: $e");
        });
      }
    } else {
      // Kullanıcı konum iznini reddetti
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
    }
  }

  // Kartın stili (Senin kodunla aynı)
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: _buildContent(),
    );
  }

  // Kartın içini duruma göre doldur
  Widget _buildContent() {
    // 1. Yükleniyorsa...
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Konum alınıyor...",
            style: GoogleFonts.kadwa(fontSize: 14, color: Colors.grey[600]),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: const Color(0xFF9EC8ED)),
            ),
          ),
          SizedBox(height: 20),
        ],
      );
    }

    // 2. Kullanıcı izni reddettiyse...
    if (_permissionDenied) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hava Durumu",
            style: GoogleFonts.kadwa(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            "Konum izni reddedildi.",
            style: GoogleFonts.kadwa(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Elle konum girmek için Ayarlar'a gidin.",
            style: GoogleFonts.kadwa(fontSize: 12),
          ),
        ],
      );
    }

    // 3. Veri geldiyse (Başarılı)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _locationName, // "Istanbul"
          style: GoogleFonts.kadwa(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          "${_temperature}°C", // "15°C" (Bugünün sıcaklığı)
          style: GoogleFonts.kadwa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          "Yarın", // "Yarının durumu"
          style: GoogleFonts.kadwa(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          _condition, // "Bulutlu" (Yarının durumu)
          style: GoogleFonts.kadwa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
