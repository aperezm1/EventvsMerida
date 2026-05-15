import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Servicio de validación para entradas de texto y tamaños de las imágenes.
///
/// @author: Eva Retamar
/// @author: Adrián Pérez
/// @author: David Muñoz
class DayRangeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d+$').hasMatch(text)) return oldValue;
    if (text.length > 2) return oldValue;
    final value = int.tryParse(text) ?? 0;
    if (value < 1 || value > 31) return oldValue;
    return newValue;
  }
}

class ImageSize {
  static int maxImagenBytes = 1572864; // 1.5 MB

  static Future<bool> validarTamanioImagen(XFile imagen) async {
    final bytes = await imagen.length();
    return bytes <= maxImagenBytes;
  }
}