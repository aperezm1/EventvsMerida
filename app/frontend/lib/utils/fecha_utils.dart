import 'package:intl/intl.dart';

class FechaUtils {
  bool esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool esHoraCero(DateTime fecha) {
    return fecha.hour == 0 && fecha.minute == 0;
  }

  String formatearHora(DateTime fecha) {
    return DateFormat('HH:mm').format(fecha);
  }

  String formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  DateTime normalizarFecha(DateTime fecha) {
    final f = fecha.toLocal();
    return DateTime(f.year, f.month, f.day);
  }

  int minutosDelDia(DateTime fecha) {
    return fecha.hour * 60 + fecha.minute;
  }

  String formatearFechaNacimiento(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }
}