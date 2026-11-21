import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/tarea.dart';

part 'app_database.g.dart';

/// Definición de la tabla `tareas` en SQLite mediante Drift.
///
/// - [id]: Identificador único entero autoincremental (`INTEGER PRIMARY KEY AUTOINCREMENT`).
/// - [titulo]: Cadena de texto no nula entre 1 y 200 caracteres (`TEXT NOT NULL`).
/// - [completada]: Booleano representado en SQLite como `0` o `1` (`INTEGER NOT NULL DEFAULT 0`).
@DataClassName('TareaEntity')
class Tareas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text().withLength(min: 1, max: 200)();
  BoolColumn get completada =>
      boolean().withDefault(const Constant(false))();
}

/// Base de datos SQLite local multiplataforma (Android, iOS, Windows, Linux, macOS y Web).
@DriftDatabase(tables: [Tareas])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _abrirConexion());

  @override
  int get schemaVersion => 1;

  /// Configura la apertura persistente para plataformas nativas y navegador Web.
  static QueryExecutor _abrirConexion() {
    return driftDatabase(
      name: 'gestor_tareas_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint(
              'Drift Web: usando ${result.chosenImplementation} '
              'por características ausentes: ${result.missingFeatures}',
            );
          }
        },
      ),
    );
  }

  /// Convierte una fila generada por Drift ([TareaEntity]) al modelo [Tarea].
  Tarea _mapearTarea(TareaEntity fila) {
    return Tarea(
      id: fila.id,
      titulo: fila.titulo,
      completada: fila.completada,
    );
  }

  /// F2. Consulta: obtiene todas las tareas guardadas ordenadas por `id` ascendente.
  Future<List<Tarea>> obtenerTareas() async {
    final query = select(tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    final filas = await query.get();
    return filas.map(_mapearTarea).toList();
  }

  /// F2 / I5. Consulta reactiva mediante [Stream] para escuchar cambios en la tabla `tareas`.
  Stream<List<Tarea>> observarTareas() {
    final query = select(tareas)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.watch().map((filas) => filas.map(_mapearTarea).toList());
  }

  /// F1. Alta: valida y registra una nueva tarea en SQLite (`INSERT INTO tareas`).
  ///
  /// Lanza [ArgumentError] si el título está vacío o solo contiene espacios.
  Future<int> insertarTarea(String titulo) async {
    final tituloLimpio = titulo.trim();
    if (tituloLimpio.isEmpty) {
      throw ArgumentError('El título de la tarea no puede estar vacío.');
    }
    return into(tareas).insert(
      TareasCompanion.insert(titulo: tituloLimpio),
    );
  }
}
