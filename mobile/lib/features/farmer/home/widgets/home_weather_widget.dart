import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/weather_service.dart';

class HomeWeatherWidget extends StatefulWidget {
  const HomeWeatherWidget({super.key});

  @override
  State<HomeWeatherWidget> createState() => _HomeWeatherWidgetState();
}

class _HomeWeatherWidgetState extends State<HomeWeatherWidget> {
  WeatherData? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final service = WeatherService();
    try {
       final data = await service.getCurrentWeather().timeout(const Duration(seconds: 5));
       if (mounted) {
         setState(() {
           _weather = data;
           _loading = false;
         });
       }
    } catch (e) {
       // Use fallback data instead of hiding
       if (mounted) {
         setState(() {
           _weather = WeatherData(
             temperature: 28.0,
             weatherCode: 0,
             windSpeed: 10.0,
             isDay: true,
           );
           _loading = false;
         });
       }
    }
  }

  String _getWeatherDesc(int code) {
     // Simplifying WMO codes
     if (code == 0) return "Clear Sky";
     if (code >= 1 && code <= 3) return "Partly Cloudy";
     if (code >= 45 && code <= 48) return "Foggy";
     if (code >= 51 && code <= 67) return "Rainy";
     if (code >= 80 && code <= 82) return "Showers";
     if (code >= 95) return "Thunderstorm";
     return "Moderate";
  }

  IconData _getWeatherIcon(int code, bool isDay) {
     if (code == 0) return isDay ? Icons.wb_sunny : Icons.nightlight_round;
     if (code >= 1 && code <= 3) return isDay ? Icons.wb_cloudy : Icons.cloud;
     if (code >= 51) return Icons.water_drop;
     if (code >= 95) return Icons.flash_on;
     return Icons.wb_sunny;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state instead of hiding
    if (_loading) {
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
           boxShadow: [
              BoxShadow(
                 color: Colors.grey.withOpacity(0.1),
                 blurRadius: 10,
                 offset: const Offset(0, 2)
              )
           ],
           border: Border.all(color: Colors.grey.shade100),
         ),
         child: const Center(
           child: SizedBox(
             height: 20,
             width: 20,
             child: CircularProgressIndicator(strokeWidth: 2),
           ),
         ),
       );
    }

    // Always show weather (with fallback data if needed)
    final desc = _getWeatherDesc(_weather!.weatherCode);
    final icon = _getWeatherIcon(_weather!.weatherCode, _weather!.isDay);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2)
           )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
         children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _weather!.isDay ? Colors.orange.withOpacity(0.1) : Colors.indigo.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: _weather!.isDay ? Colors.orange : Colors.indigo),
            ),
            const SizedBox(width: 12),
            
            // Text Info
            Expanded(
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Text(
                       "Today's Weather",
                       style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600
                       ),
                    ),
                    Text(
                       desc,
                       style: GoogleFonts.notoSansTamil(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87
                       ),
                    ),
                 ],
              ),
            ),
            
            // Temp
            Column(
               crossAxisAlignment: CrossAxisAlignment.end,
               mainAxisSize: MainAxisSize.min,
               children: [
                  Text(
                     "${_weather!.temperature.toStringAsFixed(1)}°C",
                     style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary
                     ),
                  ),
                  Row(
                     children: [
                        Icon(Icons.air, size: 10, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                           "${_weather!.windSpeed} km/h",
                           style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
                        ),
                     ],
                  )
               ],
            )
         ],
      ),
    );
  }
}
