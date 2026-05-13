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

  static Future<String?> buscarDireccionDesdeCoordenadas(
    double latitud,
    double longitud,
  ) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
      queryParameters: {
        'lat': latitud.toString(),
        'lon': longitud.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'namedetails': '1',
        'extratags': '1',
        'zoom': '18',
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

      final datos = jsonDecode(respuesta.body);

      if (datos is! Map<String, dynamic>) {
        return null;
      }

      final nombreSitio = _extraerNombreSitio(datos);
      if (nombreSitio != null) {
        return nombreSitio;
      }

      final direccion = datos['address'];
      if (direccion is Map<String, dynamic>) {
        final partes = <String>[
          _extraerParte(direccion, 'amenity'),
          _extraerParte(direccion, 'tourism'),
          _extraerParte(direccion, 'shop'),
          _extraerParte(direccion, 'leisure'),
          _extraerParte(direccion, 'building'),
          _extraerParte(direccion, 'historic'),
          _extraerParte(direccion, 'man_made'),
          _extraerParte(direccion, 'office'),
          _extraerParte(direccion, 'road'),
          _extraerParte(direccion, 'pedestrian'),
          _extraerParte(direccion, 'footway'),
          _extraerParte(direccion, 'path'),
          _extraerParte(direccion, 'house_number'),
          _extraerParte(direccion, 'suburb'),
          _extraerParte(direccion, 'neighbourhood'),
          _extraerParte(direccion, 'city'),
          _extraerParte(direccion, 'town'),
          _extraerParte(direccion, 'village'),
          _extraerParte(direccion, 'municipality'),
        ].where((parte) => parte.isNotEmpty).toList();

        if (partes.isNotEmpty) {
          return partes.take(3).join(', ');
        }
      }

      final lugarCercano = await _buscarLugarCercano(latitud, longitud);
      if (lugarCercano != null) {
        return lugarCercano;
      }

      final displayName = datos['display_name']?.toString().trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static String _extraerParte(Map<String, dynamic> datos, String clave) {
    final valor = datos[clave]?.toString().trim();

    if (valor == null || valor.isEmpty) {
      return '';
    }

    return valor;
  }

  static String? _extraerNombreSitio(Map<String, dynamic> datos) {
    final name = datos['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final namedetails = datos['namedetails'];
    if (namedetails is Map<String, dynamic>) {
      final named = namedetails['name']?.toString().trim();
      if (named != null && named.isNotEmpty) {
        return named;
      }
    }

    final extratags = datos['extratags'];
    if (extratags is Map<String, dynamic>) {
      final tagged = extratags['name']?.toString().trim();
      if (tagged != null && tagged.isNotEmpty) {
        return tagged;
      }
    }

    return null;
  }

  static Future<String?> _buscarLugarCercano(
    double latitud,
    double longitud,
  ) async {
    final margen = 0.002; // ~200m aprox
    final viewbox = [
      (longitud - margen).toString(),
      (latitud - margen).toString(),
      (longitud + margen).toString(),
      (latitud + margen).toString(),
    ].join(',');

    final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'format': 'jsonv2',
        'limit': '1',
        'viewbox': viewbox,
        'bounded': '1',
        'extratags': '1',
        'namedetails': '1',
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
      final nombre = item['name']?.toString().trim();
      if (nombre != null && nombre.isNotEmpty) {
        return nombre;
      }

      final namedetails = item['namedetails'];
      if (namedetails is Map<String, dynamic>) {
        final named = namedetails['name']?.toString().trim();
        if (named != null && named.isNotEmpty) {
          return named;
        }
      }

      final displayName = item['display_name']?.toString().trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}