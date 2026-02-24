class Evento {
  final int id;
  final String nombre;
  final String descripcion;
  final DateTime fechaHora;
  final String localizacion;
  final String urlImagen;
  final int usuarioId;
  final int categoriaId;

  Evento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaHora,
    required this.localizacion,
    required this.urlImagen,
    required this.usuarioId,
    required this.categoriaId
  });

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] as int,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaHora: json['fechaHora'] ?? '',
      localizacion: json['localizacion'] ?? '',
      urlImagen: json['urlImagen'] ?? '',
      usuarioId: json['usuarioId'] as int,
      categoriaId: json['categoriaId'] as int
    );
  }
}