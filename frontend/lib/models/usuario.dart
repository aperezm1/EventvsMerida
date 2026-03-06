class Usuario {
  final String nombre;
  final String apellidos;
  final DateTime fechaNacimiento;
  final String email;
  final String telefono;
  final String rol;

  Usuario({
    required this.nombre,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.email,
    required this.telefono,
    required this.rol,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'apellidos': apellidos,
    'fechaNacimiento': fechaNacimiento.toIso8601String(),
    'email': email,
    'telefono': telefono,
    'rol': rol,
  };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    nombre: json['nombre'] as String,
    apellidos: json['apellidos'] as String,
    fechaNacimiento: DateTime.parse(json['fechaNacimiento']),
    email: json['email'] as String,
    telefono: json['telefono'] as String,
    rol: json['rol'] as String,
  );
}