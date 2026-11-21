import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/tarea.dart';

/// Pantalla principal con persistencia SQLite local y operaciones CRUD completas (F1–F8).
class TareasPage extends StatefulWidget {
  final AppDatabase? database;

  const TareasPage({super.key, this.database});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();
  late final AppDatabase _db;
  late final bool _cerrarBaseAlSalir;

  List<Tarea> _tareas = [];

  @override
  void initState() {
    super.initState();
    _db = widget.database ?? AppDatabase();
    _cerrarBaseAlSalir = widget.database == null;
    _cargarTareas();
  }

  /// F2. Consulta las tareas almacenadas en SQLite fuera de build().
  Future<void> _cargarTareas() async {
    try {
      final tareas = await _db.obtenerTareas();
      if (!mounted) return;
      setState(() {
        _tareas = tareas;
      });
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error al cargar las tareas: $e');
    }
  }

  /// F1. Alta de nueva tarea con validación de entrada vacía o de solo espacios.
  Future<void> _agregarTarea() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      _mostrarMensaje('Escribe un título válido (no puede estar vacío).');
      return;
    }

    try {
      await _db.insertarTarea(titulo);
      _tituloController.clear();
      await _cargarTareas();
    } catch (e) {
      _mostrarMensaje('No se pudo registrar la tarea: $e');
    }
  }

  /// F4. Actualiza el estado (completada / pendiente) de la tarea en SQLite.
  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    try {
      await _db.actualizarEstadoTarea(tarea.id, completada);
      await _cargarTareas();
    } catch (e) {
      _mostrarMensaje('No se pudo actualizar el estado de la tarea: $e');
    }
  }

  /// F3. Abre un diálogo para editar el título de una tarea existente y guarda el cambio en SQLite.
  Future<void> _editarTarea(Tarea tarea) async {
    final editController = TextEditingController(text: tarea.titulo);
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar tarea'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Título de la tarea',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (valor) => Navigator.of(dialogContext).pop(valor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(editController.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    editController.dispose();

    if (nuevoTitulo == null) return;

    final limpio = nuevoTitulo.trim();
    if (limpio.isEmpty) {
      _mostrarMensaje('El título editado no puede estar vacío.');
      return;
    }

    try {
      await _db.actualizarTituloTarea(tarea.id, limpio);
      await _cargarTareas();
    } catch (e) {
      _mostrarMensaje('No se pudo editar la tarea: $e');
    }
  }

  /// F5. Elimina una tarea en SQLite utilizando su identificador único.
  Future<void> _eliminarTarea(Tarea tarea) async {
    try {
      await _db.eliminarTareaPorId(tarea.id);
      await _cargarTareas();
    } catch (e) {
      _mostrarMensaje('No se pudo eliminar la tarea: $e');
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    if (_cerrarBaseAlSalir) {
      _db.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              onSubmitted: (_) => _agregarTarea(),
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: _tareas.isEmpty
                  ? const Center(child: Text('Todavía no hay tareas guardadas'))
                  : ListView.builder(
                      itemCount: _tareas.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareas[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: tarea.completada,
                              onChanged: (valor) {
                                if (valor != null) {
                                  _alternarCompletada(tarea, valor);
                                }
                              },
                            ),
                            title: Text(
                              tarea.titulo,
                              style: TextStyle(
                                decoration: tarea.completada
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text('ID: ${tarea.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editarTarea(tarea),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _eliminarTarea(tarea),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
