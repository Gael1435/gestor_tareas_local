/// Modelo de dominio de una tarea persistida en SQLite.
///
/// Representa un registro de la tabla `tareas`:
/// - [id]: Clave primaria autoincremental en SQLite (`INTEGER PRIMARY KEY AUTOINCREMENT`).
/// - [titulo]: Descripción de la tarea (`TEXT NOT NULL`).
/// - [completada]: Estado booleano almacenado como `0` o `1` en SQLite (`INTEGER NOT NULL DEFAULT 0`).
class Tarea {
  final int id;
  final String titulo;
  final bool completada;

  const Tarea({
    required this.id,
    required this.titulo,
    required this.completada,
  });

  Tarea copyWith({
    int? id,
    String? titulo,
    bool? completada,
  }) {
    return Tarea(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      completada: completada ?? this.completada,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tarea &&
          other.id == id &&
          other.titulo == titulo &&
          other.completada == completada);

  @override
  int get hashCode => Object.hash(id, titulo, completada);

  @override
  String toString() =>
      'Tarea(id: $id, titulo: $titulo, completada: $completada)';
}
