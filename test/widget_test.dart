import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/app_database.dart';
import 'package:gestor_tareas_local/main.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    await tester.pumpWidget(GestorTareasApp(database: db));
    await tester.pumpAndSettle();

    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
  });

  testWidgets(
    'P5 / F1: Rechaza títulos vacíos o compuestos solo por espacios',
    (tester) async {
      await tester.pumpWidget(GestorTareasApp(database: db));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '     ');
      await tester.tap(find.text('Agregar tarea'));
      await tester.pumpAndSettle();

      expect(
        find.text('Escribe un título válido (no puede estar vacío).'),
        findsOneWidget,
      );
      expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);

      final registros = await db.obtenerTareas();
      expect(registros, isEmpty);
      expect(() => db.insertarTarea('   '), throwsArgumentError);
    },
  );

  test(
    'P1–P4 / F1–F5: Operaciones CRUD persisten correctamente en SQLite',
    () async {
      final id1 = await db.insertarTarea('Tarea 1: Configurar Drift');
      final id2 = await db.insertarTarea('Tarea 2: Probar WebAssembly');
      final id3 = await db.insertarTarea('Tarea 3: Documentar reporte');

      var tareas = await db.obtenerTareas();
      expect(tareas.length, 3);
      expect(tareas[0].titulo, 'Tarea 1: Configurar Drift');
      expect(tareas[0].completada, isFalse);

      // P2 / F4: Marcar como completada
      final estadoActualizado = await db.actualizarEstadoTarea(id1, true);
      expect(estadoActualizado, isTrue);
      tareas = await db.obtenerTareas();
      expect(tareas.firstWhere((t) => t.id == id1).completada, isTrue);

      // P3 / F3: Editar título existente
      final tituloActualizado = await db.actualizarTituloTarea(
        id2,
        'Tarea 2: Probar sqlite3.wasm en Web',
      );
      expect(tituloActualizado, isTrue);
      tareas = await db.obtenerTareas();
      expect(
        tareas.firstWhere((t) => t.id == id2).titulo,
        'Tarea 2: Probar sqlite3.wasm en Web',
      );

      // P4 / F5: Eliminar por ID
      final filasEliminadas = await db.eliminarTareaPorId(id3);
      expect(filasEliminadas, 1);
      tareas = await db.obtenerTareas();
      expect(tareas.length, 2);
      expect(tareas.any((t) => t.id == id3), isFalse);
    },
  );

  testWidgets(
    'Integración UI + SQLite: agregar, completar y eliminar tarea desde pantalla',
    (tester) async {
      await tester.pumpWidget(GestorTareasApp(database: db));
      await tester.pumpAndSettle();

      // Alta desde interfaz
      await tester.enterText(find.byType(TextField), 'Entregar práctica SQLite');
      await tester.tap(find.text('Agregar tarea'));
      await tester.pumpAndSettle();

      expect(find.text('Entregar práctica SQLite'), findsOneWidget);
      var registros = await db.obtenerTareas();
      expect(registros.length, 1);
      expect(registros.first.completada, isFalse);

      // Cambiar estado con Checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      registros = await db.obtenerTareas();
      expect(registros.first.completada, isTrue);

      // Eliminar con botón de icono
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      registros = await db.obtenerTareas();
      expect(registros, isEmpty);
      expect(find.text('Todavía no hay tareas guardadas'), findsOneWidget);
    },
  );
}
