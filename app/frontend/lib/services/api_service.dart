import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eventvsmerida/services/secure_storage_service.dart';
import 'package:eventvsmerida/services/shared_preferences_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/api_response.dart';
import '../models/evento.dart';
import '../models/usuario.dart';
import '../models/categoria.dart';

class ApiService {
  // ============================================================================
  // VARIABLES
  // ============================================================================

  static const String baseUrl = 'https://eventvsmerida-x2t1.onrender.com/api';
  static const Duration _tiempoLimite = Duration(seconds: 10);

  static const Map<String, String> _cabecerasJson = {
    'Content-Type': 'application/json',
  };

  static const String _mensajeSinConexion = 'No hay conexión. Intenta de nuevo más tarde.';
  static const String _refreshTokenHeader = 'x-refresh-token';

  // ============================================================================
  // USUARIOS
  // ============================================================================

  /// POST /api/usuarios/add
  static Future<ApiResponse<Usuario>> registrarUsuario(
      Map<String, dynamic> datosUsuario,
      XFile? imagen,
      ) async {
    try {
      final uri = Uri.parse('$baseUrl/usuarios/add');
      final request = http.MultipartRequest('POST', uri);

      request.fields['usuario'] = jsonEncode(datosUsuario);

      if (imagen != null) {
        final extension = p.extension(imagen.path).toLowerCase();

        late MediaType mediaType;

        if (extension == '.png') {
          mediaType = MediaType('image', 'png');
        } else if (extension == '.jpg' || extension == '.jpeg') {
          mediaType = MediaType('image', 'jpeg');
        } else {
          return ApiResponse<Usuario>.error(
            mensaje: 'Formato de imagen no soportado. Usa PNG, JPG o JPEG.',
            codigoEstado: 400,
          );
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            imagen.path,
            contentType: mediaType,
            filename: p.basename(imagen.path),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(_tiempoLimite);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        try {
          final mapa = jsonDecode(response.body) as Map<String, dynamic>;
          final usuario = Usuario.fromJson(mapa);

          await _guardarCookieDesdeRespuesta(response);

          final email = datosUsuario['email']?.toString();
          final password = datosUsuario['password']?.toString();

          if (email != null &&
              email.isNotEmpty &&
              password != null &&
              password.isNotEmpty) {
            final respuestaLogin = await iniciarSesion(email, password, rememberMe: false);
            if (!respuestaLogin.exito) {
              return ApiResponse<Usuario>.error(
                mensaje: 'Usuario registrado, pero no se pudo iniciar sesión automáticamente.',
                codigoEstado: 201,
              );
            }
          }

          return ApiResponse<Usuario>.exito(
            datos: usuario,
            mensaje: 'Registro exitoso',
            codigoEstado: 201,
          );
        } catch (_) {
          return ApiResponse<Usuario>.error(
            mensaje: 'No se pudo leer la respuesta del servidor.',
            codigoEstado: 201,
          );
        }
      }

      final mensaje = _leerMensajeError(response.body);

      switch (response.statusCode) {
        case 400:
          return ApiResponse<Usuario>.error(
            mensaje:
            mensaje.isEmpty ? 'Los datos del registro no son válidos.' : mensaje,
            codigoEstado: 400,
          );

        case 409:
          return ApiResponse<Usuario>.error(
            mensaje: mensaje.isEmpty
                ? 'Ya existe una cuenta con ese correo electrónico.'
                : mensaje,
            codigoEstado: 409,
          );

        case 500:
          return ApiResponse<Usuario>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          return ApiResponse<Usuario>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudo completar el registro (${response.statusCode}).'
                : mensaje,
            codigoEstado: response.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<Usuario>.error(
        mensaje: 'Error inesperado al registrar el usuario: $e',
        codigoEstado: 500,
      );
    }
  }

  /// POST /api/auth/login
  static Future<ApiResponse<Usuario>> iniciarSesion(String email, String password, {bool rememberMe = false}) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login').replace(
        queryParameters: {
          'rememberMe': rememberMe.toString(),
        },
      );

      final respuesta = await _solicitud(() {
        return http.post(
          uri,
          headers: _cabecerasJson,
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        );
      });

      switch (respuesta.statusCode) {
        case 200:
          try {
            final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
            final usuario = Usuario.fromJson(mapa);

            await _guardarCookieDesdeRespuesta(respuesta);
            await _guardarRefreshTokenDesdeRespuesta(respuesta, rememberMe: rememberMe);

            return ApiResponse<Usuario>.exito(
              datos: usuario,
              mensaje: 'Login exitoso',
              codigoEstado: 200,
            );
          } catch (_) {
            return ApiResponse<Usuario>.error(
              mensaje: 'No se pudo leer la respuesta del servidor.',
              codigoEstado: 200,
            );
          }

        case 400:
        case 401:
        case 404:
          return ApiResponse<Usuario>.error(
            mensaje: 'Credenciales inválidas.',
            codigoEstado: respuesta.statusCode,
          );

        case 500:
          return ApiResponse<Usuario>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<Usuario>.error(
            mensaje: mensaje.isEmpty
                ? 'Error desconocido (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<Usuario>.error(
        mensaje: 'Error inesperado al iniciar sesión: $e',
        codigoEstado: 500,
      );
    }
  }

  /// PUT /api/usuarios/update/{id}
  static Future<ApiResponse<Usuario>> editarUsuario({
    required int idUsuario,
    required Map<String, dynamic>? datosUsuario,
    XFile? imagen,
  }) async {
    try {
      if ((datosUsuario == null || datosUsuario.isEmpty) && imagen == null) {
        return ApiResponse<Usuario>.error(
          mensaje: 'No hay datos ni imagen para actualizar.',
          codigoEstado: 400,
        );
      }

      final uri = Uri.parse('$baseUrl/usuarios/update/$idUsuario');
      final request = http.MultipartRequest('PUT', uri);

      final cabeceras = await _cabecerasConSesion();
      request.headers.addAll(cabeceras);

      request.fields['usuario'] = jsonEncode(datosUsuario);

      if (imagen != null) {
        final extension = p.extension(imagen.path).toLowerCase();

        late MediaType mediaType;

        if (extension == '.png') {
          mediaType = MediaType('image', 'png');
        } else if (extension == '.jpg' || extension == '.jpeg') {
          mediaType = MediaType('image', 'jpeg');
        } else {
          return ApiResponse<Usuario>.error(
            mensaje: 'Formato de imagen no soportado. Usa PNG, JPG o JPEG.',
            codigoEstado: 400,
          );
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            imagen.path,
            contentType: mediaType,
            filename: p.basename(imagen.path),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(_tiempoLimite);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          final mapa = jsonDecode(response.body) as Map<String, dynamic>;
          final usuario = Usuario.fromJson(mapa);

          return ApiResponse<Usuario>.exito(
            datos: usuario,
            mensaje: 'Usuario actualizado correctamente',
            codigoEstado: 200,
          );
        } catch (_) {
          return ApiResponse<Usuario>.error(
            mensaje: 'No se pudo leer la respuesta del servidor.',
            codigoEstado: 200,
          );
        }
      }

      final mensaje = _leerMensajeError(response.body);

      switch (response.statusCode) {
        case 400:
          return ApiResponse<Usuario>.error(
            mensaje: mensaje.isEmpty ? 'Los datos enviados no son válidos.' : mensaje,
            codigoEstado: 400,
          );

        case 404:
          return ApiResponse<Usuario>.error(
            mensaje: mensaje.isEmpty ? 'Usuario no encontrado.' : mensaje,
            codigoEstado: 404,
          );

        case 409:
          return ApiResponse<Usuario>.error(
            mensaje:
            mensaje.isEmpty ? 'Ya existe otro usuario con esos datos.' : mensaje,
            codigoEstado: 409,
          );

        case 500:
          return ApiResponse<Usuario>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          return ApiResponse<Usuario>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudo actualizar el usuario (${response.statusCode}).'
                : mensaje,
            codigoEstado: response.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<Usuario>.error(
        mensaje: 'Error inesperado al actualizar el usuario: $e',
        codigoEstado: 500,
      );
    }
  }

  static Future<ApiResponse<Usuario>> recuperarPassword(String email) async {
    try {
      final respuesta = await _post('/auth/forgot-password?email=$email', {});

      switch (respuesta.statusCode) {
        case 200:
          try {
            return ApiResponse<Usuario>.exito(
              datos: null,
              mensaje: 'Correo enviado',
              codigoEstado: 200,
            );
          } catch (_) {
            return ApiResponse<Usuario>.error(
              mensaje: 'No se pudo leer la respuesta del servidor.',
              codigoEstado: 200,
            );
          }

        case 400:
        case 401:
        case 404:
          return ApiResponse<Usuario>.error(
            mensaje: 'No ha sido posible enviar el correo.',
            codigoEstado: respuesta.statusCode,
          );

        case 500:
          return ApiResponse<Usuario>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<Usuario>.error(
            mensaje: mensaje.isEmpty
                ? 'Error desconocido (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<Usuario>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<Usuario>.error(
        mensaje: 'Error inesperado al enviar el correo: $e',
        codigoEstado: 500,
      );
    }
  }

  // ============================================================================
  // EVENTOS
  // ============================================================================

  /// GET /api/eventos/all
  static Future<ApiResponse<List<Evento>>> obtenerEventos() async {
    try {
      final respuesta = await _get('/eventos/all');

      switch (respuesta.statusCode) {
        case 200:
          try {
            final lista = jsonDecode(respuesta.body) as List<dynamic>;
            final eventos = lista
                .map((item) => Evento.fromJson(item as Map<String, dynamic>))
                .toList();

            return ApiResponse<List<Evento>>.exito(
              datos: eventos,
              mensaje: 'Eventos cargados correctamente',
              codigoEstado: 200,
            );
          } catch (_) {
            return ApiResponse<List<Evento>>.error(
              mensaje: 'No se pudieron leer los eventos.',
              codigoEstado: 200,
            );
          }

        case 404:
          return ApiResponse<List<Evento>>.exito(
            datos: const [],
            mensaje: 'No hay eventos disponibles.',
            codigoEstado: 404,
          );

        case 500:
          return ApiResponse<List<Evento>>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<List<Evento>>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudieron cargar los eventos (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } on SocketException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } catch (e) {
      return ApiResponse<List<Evento>>.error(
        mensaje: 'Error inesperado al cargar los eventos: $e',
        codigoEstado: 500,
      );
    }
  }

  /// GET /api/eventos/search?q="Query"&limit="Límite"
  static Future<ApiResponse<List<Evento>>> buscarEventos(String query) async {
    if (query.trim().isEmpty) {
      return ApiResponse<List<Evento>>.exito(
        datos: const [],
        mensaje: 'Introduce un término de búsqueda para encontrar eventos.',
        codigoEstado: 200,
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/eventos/search').replace(
        queryParameters: {
          'q': query,
          'limit': '10',
        },
      );

      final respuesta = await _getUri(uri);

      switch (respuesta.statusCode) {
        case 200:
          try {
            final lista = jsonDecode(respuesta.body) as List<dynamic>;
            final eventos = lista
                .map((item) => Evento.fromJson(item as Map<String, dynamic>))
                .toList();

            return ApiResponse<List<Evento>>.exito(
              datos: eventos,
              mensaje: 'Eventos encontrados cargados correctamente',
              codigoEstado: 200,
            );
          } catch (_) {
            return ApiResponse<List<Evento>>.error(
              mensaje: 'No se pudieron leer los eventos encontrados.',
              codigoEstado: 200,
            );
          }

        case 400:
          return ApiResponse<List<Evento>>.error(
            mensaje: 'La búsqueda no es válida.',
            codigoEstado: 400,
          );

        case 404:
          return ApiResponse<List<Evento>>.exito(
            datos: const [],
            mensaje: 'No se encontraron eventos para la búsqueda indicada.',
            codigoEstado: 404,
          );

        case 500:
          return ApiResponse<List<Evento>>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<List<Evento>>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudo realizar la búsqueda (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } on SocketException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } catch (e) {
      return ApiResponse<List<Evento>>.error(
        mensaje: 'Error inesperado al buscar eventos: $e',
        codigoEstado: 500,
      );
    }
  }

  /// GET /api/eventos/filter-by-categories?categorias=1&categorias=2...
  static Future<ApiResponse<List<Evento>>> obtenerEventosFiltradosPorCategorias(
      List<int> categorias,
      ) async {
    if (categorias.isEmpty) {
      return ApiResponse<List<Evento>>.exito(
        datos: const [],
        mensaje: 'No hay categorías seleccionadas.',
        codigoEstado: 200,
      );
    }

    try {
      final queryString = categorias.map((c) => 'categorias=$c').join('&');
      final uri = Uri.parse('$baseUrl/eventos/filter-by-categories?$queryString');

      final respuesta = await _getUri(uri);

      switch (respuesta.statusCode) {
        case 200:
          try {
            final lista = jsonDecode(respuesta.body) as List<dynamic>;
            final eventos = lista
                .map((item) => Evento.fromJson(item as Map<String, dynamic>))
                .toList();

            return ApiResponse<List<Evento>>.exito(
              datos: eventos,
              mensaje: 'Eventos filtrados cargados correctamente',
              codigoEstado: 200,
            );
          } catch (e) {
            return ApiResponse<List<Evento>>.error(
              mensaje: 'No se pudieron leer los eventos filtrados: $e',
              codigoEstado: 200,
            );
          }

        case 400:
          return ApiResponse<List<Evento>>.error(
            mensaje: 'Las categorías seleccionadas no son válidas.',
            codigoEstado: 400,
          );

        case 404:
          return ApiResponse<List<Evento>>.exito(
            datos: const [],
            mensaje: 'No hay eventos para las categorías seleccionadas.',
            codigoEstado: 404,
          );

        case 500:
          return ApiResponse<List<Evento>>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<List<Evento>>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudieron cargar los eventos filtrados (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } on SocketException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } catch (e) {
      return ApiResponse<List<Evento>>.error(
        mensaje: 'Error inesperado al filtrar eventos: $e',
        codigoEstado: 500,
      );
    }
  }

  /// GET /api/eventos/paginated?page=0&size=20&sort=fechaInicio,asc&fechaFinDesde=2024-01-01T00:00:00Z
  static Future<Map<String, dynamic>?> obtenerEventosPaginados({
    int page = 0,
    int size = 15,
    DateTime? fechaFinDesde,
  }) async {
    try {
      final queryParameters = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (fechaFinDesde != null) {
        final fechaLocal = fechaFinDesde.toLocal();
        final offset = fechaLocal.timeZoneOffset;
        final sign = offset.isNegative ? '-' : '+';
        final offsetAbs = offset.abs();
        final offHours = offsetAbs.inHours.toString().padLeft(2, '0');
        final offMinutes =
        (offsetAbs.inMinutes % 60).toString().padLeft(2, '0');

        final fechaFormateada =
            '${fechaLocal.year.toString().padLeft(4, '0')}-'
            '${fechaLocal.month.toString().padLeft(2, '0')}-'
            '${fechaLocal.day.toString().padLeft(2, '0')}T'
            '${fechaLocal.hour.toString().padLeft(2, '0')}:'
            '${fechaLocal.minute.toString().padLeft(2, '0')}:'
            '${fechaLocal.second.toString().padLeft(2, '0')}'
            '$sign$offHours:$offMinutes';

        queryParameters['fechaFinDesde'] = fechaFormateada;
      }

      final uri = Uri.parse('$baseUrl/eventos/paginated').replace(
        queryParameters: queryParameters,
      );

      final respuesta = await _getUri(uri);

      if (respuesta.statusCode == 200) {
        try {
          final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
          final listaRaw = (mapa['content'] as List<dynamic>?) ?? [];

          final eventos = listaRaw
              .map((e) => Evento.fromJson(e as Map<String, dynamic>))
              .toList();

          return {
            'items': eventos,
            'last': mapa['last'] as bool? ?? (eventos.length < size),
            'totalPages': mapa['totalPages'],
            'number': mapa['number'],
            'size': mapa['size'],
          };
        } catch (e) {
          return {
            'items': <Evento>[],
            'last': true,
            'error': 'No se pudieron leer los eventos paginados: $e',
          };
        }
      }

      final mensaje = _leerMensajeError(respuesta.body);

      switch (respuesta.statusCode) {
        case 400:
          return {
            'items': <Evento>[],
            'last': true,
            'error': mensaje.isEmpty
                ? 'Los parámetros de paginación no son válidos.'
                : mensaje,
          };

        case 500:
          return {
            'items': <Evento>[],
            'last': true,
            'error': 'Error interno del servidor. Intenta más tarde.',
          };

        default:
          return {
            'items': <Evento>[],
            'last': true,
            'error': mensaje.isEmpty
                ? 'No se pudieron cargar los eventos paginados (${respuesta.statusCode}).'
                : mensaje,
          };
      }
    } on TimeoutException {
      return {
        'items': <Evento>[],
        'last': true,
        'error': _mensajeSinConexion,
      };
    } on SocketException {
      return {
        'items': <Evento>[],
        'last': true,
        'error': _mensajeSinConexion,
      };
    } catch (e) {
      return {
        'items': <Evento>[],
        'last': true,
        'error': 'Error inesperado al cargar eventos paginados: $e',
      };
    }
  }

  /// POST /api/eventos/add
  static Future<ApiResponse<Evento>> crearEventoConImagen(Map<String, dynamic> datosEvento, XFile imagen,) async {
    try {
      final extension = p.extension(imagen.path).toLowerCase();

      late MediaType mediaType;

      if (extension == '.png') {
        mediaType = MediaType('image', 'png');
      } else if (extension == '.jpg' || extension == '.jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else {
        return ApiResponse<Evento>.error(
          mensaje: 'Formato de imagen no soportado. Usa PNG, JPG o JPEG.',
          codigoEstado: 400,
        );
      }

      Future<http.Response> enviar() async {
        final uri = Uri.parse('$baseUrl/eventos/add');
        final request = http.MultipartRequest('POST', uri);

        final cabeceras = await _cabecerasConSesion();
        request.headers.addAll(cabeceras);

        request.fields['evento'] = jsonEncode(datosEvento);

        request.files.add(
          await http.MultipartFile.fromPath(
            'imagen',
            imagen.path,
            contentType: mediaType,
            filename: p.basename(imagen.path),
          ),
        );

        final streamedResponse = await request.send();
        return http.Response.fromStream(streamedResponse);
      }

      final response = await _solicitudConRefresh(enviar);

      if (response.statusCode == 201) {
        try {
          final mapa = jsonDecode(response.body) as Map<String, dynamic>;
          final evento = Evento.fromJson(mapa);

          return ApiResponse<Evento>.exito(
            datos: evento,
            mensaje: 'Evento creado correctamente',
            codigoEstado: 201,
          );
        } catch (_) {
          return ApiResponse<Evento>.error(
            mensaje: 'No se pudo leer el evento creado.',
            codigoEstado: 201,
          );
        }
      }

      final mensaje = _leerMensajeError(response.body);

      switch (response.statusCode) {
        case 400:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'Los datos del evento no son válidos.' : mensaje,
            codigoEstado: 400,
          );

        case 403:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'No tienes permisos para crear eventos.' : mensaje,
            codigoEstado: 403,
          );

        case 404:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'No se encontró el usuario o la categoría indicada.' : mensaje,
            codigoEstado: 404,
          );

        case 409:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'Ya existe un evento con el mismo título y fechas.' : mensaje,
            codigoEstado: 409,
          );

        case 500:
          return ApiResponse<Evento>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudo crear el evento (${response.statusCode}).'
                : mensaje,
            codigoEstado: response.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<Evento>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<Evento>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<Evento>.error(
        mensaje: 'Error inesperado al crear el evento: $e',
        codigoEstado: 500,
      );
    }
  }

  ///GET /api/eventos/organizador/{idUsuario}
  static Future<ApiResponse<List<Evento>>> obtenerEventosPorOrganizador(int idUsuario) async {
    try {
      final respuesta = await _getConSesion('/eventos/organizador/$idUsuario');

      if (respuesta.statusCode == 200) {
        try {
          final lista = jsonDecode(respuesta.body) as List<dynamic>;
          final eventos = lista
              .map((item) => Evento.fromJson(item as Map<String, dynamic>))
              .toList();

          return ApiResponse<List<Evento>>.exito(
            datos: eventos,
            mensaje: 'Eventos del organizador cargados correctamente',
            codigoEstado: 200,
          );
        } catch (_) {
          return ApiResponse<List<Evento>>.error(
            mensaje: 'No se pudieron leer los eventos del organizador.',
            codigoEstado: 200,
          );
        }
      }

      final mensaje = _leerMensajeError(respuesta.body);

      switch (respuesta.statusCode) {
        case 403:
          return ApiResponse<List<Evento>>.error(
            mensaje: mensaje.isEmpty
                ? 'No tienes permisos para consultar estos eventos.'
                : mensaje,
            codigoEstado: 403,
          );

        case 404:
          return ApiResponse<List<Evento>>.error(
            mensaje: mensaje.isEmpty
                ? 'Usuario organizador no encontrado.'
                : mensaje,
            codigoEstado: 404,
          );

        case 500:
          return ApiResponse<List<Evento>>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          return ApiResponse<List<Evento>>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudieron cargar los eventos del organizador (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } on SocketException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } catch (e) {
      return ApiResponse<List<Evento>>.error(
        mensaje: 'Error inesperado al cargar eventos del organizador: $e',
        codigoEstado: 500,
      );
    }
  }

  /// DELETE /api/eventos/delete/{id}
  static Future<ApiResponse<void>> eliminarEvento(int idEvento) async {
    try {
      final respuesta = await _deleteSinBodyConSesion('/eventos/delete/$idEvento');

      switch (respuesta.statusCode) {
        case 204:
          return ApiResponse<void>.exito(
            datos: null,
            mensaje: 'Evento eliminado correctamente',
            codigoEstado: 204,
          );

        case 403:
          return ApiResponse<void>.error(
            mensaje: 'No tienes permisos para eliminar eventos.',
            codigoEstado: 403,
          );

        case 404:
          return ApiResponse<void>.error(
            mensaje: 'Evento no encontrado.',
            codigoEstado: 404,
          );

        case 500:
          return ApiResponse<void>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<void>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudo eliminar el evento (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<void>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<void>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<void>.error(
        mensaje: 'Error inesperado al eliminar el evento: $e',
        codigoEstado: 500,
      );
    }
  }

  /// UPDATE /api/eventos/update/{id}
  static Future<ApiResponse<Evento>> actualizarEventoConImagen(int idEvento, Map<String, dynamic> datosEvento, XFile? imagen) async {
    try {
      MediaType? mediaType;

      if (imagen != null) {
        final extension = p.extension(imagen.path).toLowerCase();

        if (extension == '.png') {
          mediaType = MediaType('image', 'png');
        } else if (extension == '.jpg' || extension == '.jpeg') {
          mediaType = MediaType('image', 'jpeg');
        } else {
          return ApiResponse<Evento>.error(
            mensaje: 'Formato de imagen no soportado. Usa PNG, JPG o JPEG.',
            codigoEstado: 400,
          );
        }
      }

      Future<http.Response> enviar() async {
        final uri = Uri.parse('$baseUrl/eventos/update/$idEvento');
        final request = http.MultipartRequest('PUT', uri);

        final cabeceras = await _cabecerasConSesion();
        request.headers.addAll(cabeceras);

        request.fields['evento'] = jsonEncode(datosEvento);

        if (imagen != null && mediaType != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'imagen',
              imagen.path,
              contentType: mediaType,
              filename: p.basename(imagen.path),
            ),
          );
        }

        final streamedResponse = await request.send();
        return http.Response.fromStream(streamedResponse);
      }

      final response = await _solicitudConRefresh(enviar);

      if (response.statusCode == 200) {
        try {
          final mapa = jsonDecode(response.body) as Map<String, dynamic>;
          final evento = Evento.fromJson(mapa);

          return ApiResponse<Evento>.exito(
            datos: evento,
            mensaje: 'Evento actualizado correctamente',
            codigoEstado: 200,
          );
        } catch (_) {
          return ApiResponse<Evento>.error(
            mensaje: 'El evento se actualizó, pero no se pudo leer la respuesta del servidor.',
            codigoEstado: 200,
          );
        }
      }

      final mensaje = _leerMensajeError(response.body);

      switch (response.statusCode) {
        case 400:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'Los datos del evento no son válidos.' : mensaje,
            codigoEstado: 400,
          );

        case 403:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'No tienes permisos para actualizar eventos.' : mensaje,
            codigoEstado: 403,
          );

        case 404:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'Evento, usuario o categoría no encontrada.' : mensaje,
            codigoEstado: 404,
          );

        case 409:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'Existe un conflicto con los datos enviados.' : mensaje,
            codigoEstado: 409,
          );

        case 500:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty ? 'Error interno del servidor. Intenta más tarde.' : mensaje,
            codigoEstado: 500,
          );

        default:
          return ApiResponse<Evento>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudo actualizar el evento (${response.statusCode}).'
                : mensaje,
            codigoEstado: response.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<Evento>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<Evento>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<Evento>.error(
        mensaje: 'Error inesperado al actualizar el evento: $e',
        codigoEstado: 500,
      );
    }
  }

  // ============================================================================
  // USUARIO-EVENTOS
  // ============================================================================

  /// GET /api/usuario-eventos/guardados?emailUsuario=
  static Future<ApiResponse<List<Evento>>> obtenerEventosGuardados(
      String emailUsuario,
      ) async {
    try {
      final uri = Uri.parse('$baseUrl/usuario-eventos/guardados').replace(
        queryParameters: {'emailUsuario': emailUsuario},
      );

      final respuesta = await _getUri(uri);

      switch (respuesta.statusCode) {
        case 200:
          try {
            final lista = jsonDecode(respuesta.body) as List<dynamic>;
            final eventos = lista
                .map((item) => Evento.fromJson(item as Map<String, dynamic>))
                .toList();

            return ApiResponse<List<Evento>>.exito(
              datos: eventos,
              mensaje: 'Eventos guardados cargados correctamente',
              codigoEstado: 200,
            );
          } catch (_) {
            return ApiResponse<List<Evento>>.error(
              mensaje: 'No se pudieron leer los eventos guardados.',
              codigoEstado: 200,
            );
          }

        case 404:
          return ApiResponse<List<Evento>>.exito(
            datos: const [],
            mensaje: 'No tienes eventos guardados.',
            codigoEstado: 404,
          );

        case 500:
          return ApiResponse<List<Evento>>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<List<Evento>>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudieron cargar los eventos guardados (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } on SocketException {
      return ApiResponse<List<Evento>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } catch (e) {
      return ApiResponse<List<Evento>>.error(
        mensaje: 'Error inesperado al cargar eventos guardados: $e',
        codigoEstado: 500,
      );
    }
  }

  /// POST /api/usuario-eventos/guardar
  static Future<ApiResponse<void>> guardarEventoUsuario(
      String emailUsuario,
      String tituloEvento,
      DateTime fechaInicio,
      DateTime fechaFin,
      ) async {
    try {
      final respuesta = await _post('/usuario-eventos/guardar', {
        'emailUsuario': emailUsuario,
        'tituloEvento': tituloEvento,
        'fechaInicioEvento': fechaInicio.toIso8601String(),
        'fechaFinEvento': fechaFin.toIso8601String(),
      });

      switch (respuesta.statusCode) {
        case 201:
          return ApiResponse<void>.exito(
            datos: null,
            mensaje: 'Evento guardado correctamente',
            codigoEstado: 201,
          );

        case 400:
          return ApiResponse<void>.error(
            mensaje: 'No se pudo guardar el evento. Datos inválidos.',
            codigoEstado: 400,
          );

        case 404:
          return ApiResponse<void>.error(
            mensaje: 'No se encontró el usuario o el evento.',
            codigoEstado: 404,
          );

        case 409:
          return ApiResponse<void>.error(
            mensaje: 'Este evento ya está guardado.',
            codigoEstado: 409,
          );

        case 500:
          return ApiResponse<void>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<void>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudo guardar el evento (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<void>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<void>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<void>.error(
        mensaje: 'Error inesperado al guardar el evento: $e',
        codigoEstado: 500,
      );
    }
  }

  /// DELETE /api/usuario-eventos/eliminar
  static Future<ApiResponse<void>> eliminarEventoUsuario(
      String emailUsuario,
      String tituloEvento,
      DateTime fechaInicio,
      DateTime fechaFin,
      ) async {
    try {
      final respuesta = await _delete('/usuario-eventos/eliminar', {
        'emailUsuario': emailUsuario,
        'tituloEvento': tituloEvento,
        'fechaInicioEvento': fechaInicio.toIso8601String(),
        'fechaFinEvento': fechaFin.toIso8601String(),
      });

      switch (respuesta.statusCode) {
        case 204:
          return ApiResponse<void>.exito(
            datos: null,
            mensaje: 'Evento eliminado correctamente',
            codigoEstado: 204,
          );

        case 400:
          return ApiResponse<void>.error(
            mensaje: 'No se pudo eliminar el evento. Datos inválidos.',
            codigoEstado: 400,
          );

        case 404:
          return ApiResponse<void>.error(
            mensaje: 'El evento guardado no existe.',
            codigoEstado: 404,
          );

        case 500:
          return ApiResponse<void>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<void>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudo eliminar el evento (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<void>.sinConexion(mensaje: _mensajeSinConexion);
    } on SocketException {
      return ApiResponse<void>.sinConexion(mensaje: _mensajeSinConexion);
    } catch (e) {
      return ApiResponse<void>.error(
        mensaje: 'Error inesperado al eliminar el evento: $e',
        codigoEstado: 500,
      );
    }
  }

  // ============================================================================
  // CATEGORÍAS
  // ============================================================================

  /// GET /api/categorias/all
  static Future<ApiResponse<List<Categoria>>> obtenerCategorias() async {
    try {
      final respuesta = await _get('/categorias/all');

      switch (respuesta.statusCode) {
        case 200:
          try {
            final lista = jsonDecode(respuesta.body) as List<dynamic>;
            final categorias = lista
                .map((item) => Categoria.fromJson(item as Map<String, dynamic>))
                .toList();

            return ApiResponse<List<Categoria>>.exito(
              datos: categorias,
              mensaje: 'Categorías cargadas correctamente',
              codigoEstado: 200,
            );
          } catch (e) {
            return ApiResponse<List<Categoria>>.error(
              mensaje: 'No se pudieron leer las categorías: $e',
              codigoEstado: 200,
            );
          }

        case 404:
          return ApiResponse<List<Categoria>>.exito(
            datos: const [],
            mensaje: 'No hay categorías disponibles.',
            codigoEstado: 404,
          );

        case 500:
          return ApiResponse<List<Categoria>>.error(
            mensaje: 'Error interno del servidor. Intenta más tarde.',
            codigoEstado: 500,
          );

        default:
          final mensaje = _leerMensajeError(respuesta.body);

          return ApiResponse<List<Categoria>>.error(
            mensaje: mensaje.isEmpty
                ? 'No se pudieron cargar las categorías (${respuesta.statusCode}).'
                : mensaje,
            codigoEstado: respuesta.statusCode,
          );
      }
    } on TimeoutException {
      return ApiResponse<List<Categoria>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } on SocketException {
      return ApiResponse<List<Categoria>>.sinConexion(
        mensaje: _mensajeSinConexion,
      );
    } catch (e) {
      return ApiResponse<List<Categoria>>.error(
        mensaje: 'Error inesperado al cargar las categorías: $e',
        codigoEstado: 500,
      );
    }
  }

  // ============================================================================
  // PETICIONES HTTP
  // ============================================================================

  static Future<http.Response> _get(String ruta) {
    return _solicitud(() => http.get(Uri.parse('$baseUrl$ruta')));
  }

  static Future<http.Response> _getUri(Uri uri) {
    return _solicitud(() => http.get(uri));
  }

  static Future<http.Response> _post(String ruta, Object cuerpo) {
    return _solicitud(() {
      return http.post(
        Uri.parse('$baseUrl$ruta'),
        headers: _cabecerasJson,
        body: jsonEncode(cuerpo),
      );
    });
  }

  static Future<http.Response> _delete(String ruta, Object cuerpo) {
    return _solicitud(() {
      return http.delete(
        Uri.parse('$baseUrl$ruta'),
        headers: _cabecerasJson,
        body: jsonEncode(cuerpo),
      );
    });
  }

  static Future<http.Response> _solicitud(
      Future<http.Response> Function() accion,
      ) async {
    return await accion().timeout(_tiempoLimite);
  }

  static Future<http.Response> _getConSesion(String ruta) {
    return _solicitudConRefresh(() async {
      final cabeceras = await _cabecerasConSesion();
      return http.get(
        Uri.parse('$baseUrl$ruta'),
        headers: cabeceras,
      );
    });
  }

  static Future<http.Response> _deleteSinBodyConSesion(String ruta) async {
    return _solicitudConRefresh(() async {
      final cabeceras = await _cabecerasConSesion();
      return http.delete(
        Uri.parse('$baseUrl$ruta'),
        headers: cabeceras,
      );
    });
  }

  static Future<void> cerrarSesionRemota() async {
    final cabeceras = await _cabecerasConSesion();
    await _solicitud(() {
      return http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: cabeceras,
      );
    });
  }

  static Future<http.Response> _solicitudConRefresh(
      Future<http.Response> Function() accion,
      ) async {
    final response = await _solicitud(accion);

    if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 302) {
      final refreshed = await _refrescarSesion();
      if (refreshed) {
        return _solicitud(accion);
      }
    }

    return response;
  }

  static Future<bool> _refrescarSesion() async {
    final refreshToken = await SecureStorageService.cargarRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final respuesta = await _solicitud(() {
      return http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: _cabecerasJson,
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    });

    if (respuesta.statusCode == 200) {
      await _guardarCookieDesdeRespuesta(respuesta);
      await _guardarRefreshTokenDesdeRespuesta(respuesta, rememberMe: true);
      return true;
    }

    if (respuesta.statusCode == 401 || respuesta.statusCode == 403 || respuesta.statusCode == 302) {
      await SecureStorageService.borrarRefreshToken();
    }

    return false;
  }

  static Future<void> _guardarRefreshTokenDesdeRespuesta(
      http.Response respuesta, {
        required bool rememberMe,
      }) async {
    if (!rememberMe) return;

    final refreshToken = respuesta.headers[_refreshTokenHeader];

    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    await SecureStorageService.guardarRefreshToken(refreshToken);
  }

  static Future<void> _guardarCookieDesdeRespuesta(http.Response respuesta) async {
    final setCookie = respuesta.headers['set-cookie'];

    if (setCookie == null || setCookie.isEmpty) {
      return;
    }

    final sessionCookie = setCookie.split(';').first;

    if (sessionCookie.isNotEmpty) {
      await SharedPreferencesService.guardarSessionCookie(sessionCookie);
    }
  }

  static Future<Map<String, String>> _cabecerasConSesion() async {
    final cookie = await SharedPreferencesService.cargarSessionCookie();

    if (cookie == null || cookie.isEmpty) {
      return {};
    }

    return {
      'Cookie': cookie,
    };
  }

  static String _leerMensajeError(String body) {
    if (body.trim().isEmpty) return '';
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final mensaje = data['mensaje'] ?? data['message'] ?? data['error'];
        return mensaje?.toString().trim() ?? '';
      }
    } catch (_) {
      // Ignora parseo inválido y devuelve vacío
    }
    return '';
  }
}