import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  GeocodingService._();

  static Future<LatLng?> buscarCoordenadas(String localizacion) async {
    final texto = localizacion.trim();

    if (texto.isEmpty) {
      return null;
    }

    final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'q': '$texto, Mérida, Badajoz, España',
        'format': 'json',
        'limit': '1',
      },
    );

    try {
      final respuesta = await http.get(
        uri,
        headers: {
          'User-Agent': 'EventvsMerida/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (respuesta.statusCode != 200) {
        return null;
      }

      final lista = jsonDecode(respuesta.body) as List<dynamic>;

      if (lista.isEmpty) {
        return null;
      }

      final item = lista.first as Map<String, dynamic>;

      final lat = double.tryParse(item['lat'].toString());
      final lon = double.tryParse(item['lon'].toString());

      if (lat == null || lon == null) {
        return null;
      }

      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }
}