class PqrModel {
  final int? idLocal; // ID interno para SQLite (cuando no hay internet)
  final String? idMongo; // ID real generado por el backend
  final String tipo; // QUEJA, RECLAMO, SUGERENCIA
  final String descripcion;
  final double latitud;
  final double longitud;
  final String estado; // PENDIENTE, EN_PROCESO, RESUELTO
  final String? prediccionTiempo; // Rápido, Muy rápido, Lento (Desde Weka)
  final bool sincronizado; // true si ya subió a la nube, false si está en modo avión

  PqrModel({
    this.idLocal,
    this.idMongo,
    required this.tipo,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    this.estado = 'PENDIENTE',
    this.prediccionTiempo,
    this.sincronizado = true,
  });

  // Convertir a JSON para enviar a Spring Boot o guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'descripcion': descripcion,
      'latitud': latitud,
      'longitud': longitud,
      'estado': estado,
      'prediccionTiempo': prediccionTiempo,
      'sincronizado': sincronizado ? 1 : 0, // SQLite no maneja booleanos nativos
    };
  }

  // Crear objeto desde JSON (Backend) o SQLite
  factory PqrModel.fromMap(Map<String, dynamic> map) {
    return PqrModel(
      idLocal: map['id'], // SQLite usa 'id' por defecto
      idMongo: map['_id'], // MongoDB usa '_id'
      tipo: map['tipo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      latitud: (map['latitud'] ?? 0.0).toDouble(),
      longitud: (map['longitud'] ?? 0.0).toDouble(),
      estado: map['estado'] ?? 'PENDIENTE',
      prediccionTiempo: map['prediccionTiempo'],
      sincronizado: map['sincronizado'] == 1,
    );
  }
}