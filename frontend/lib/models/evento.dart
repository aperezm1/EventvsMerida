class Evento {
  final String titulo;
  final String descripcion;
  final DateTime fechaHora;
  final String localizacion;
  final String foto;
  final String emailUsuario;
  final String nombreCategoria;

  Evento({
    required this.titulo,
    required this.descripcion,
    required this.fechaHora,
    required this.localizacion,
    required this.foto,
    required this.emailUsuario,
    required this.nombreCategoria,
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaHora: DateTime.parse(json['fechaHora'].toString()),
      localizacion: json['localizacion'] ?? '',
      foto: json['foto'] ?? '',
      emailUsuario: json['emailUsuario'] ?? '',
      nombreCategoria: json['nombreCategoria'] ?? '',
    );
  }
}