import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../models/tarea.dart';

/// Pantalla principal con persistencia SQLite local (Etapa 2: Alta y Consulta).
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

  Future<void> _cargarTareas() async {
    try {
      final tareas = await _db.obtenerTareas();
      if (!mounted) return;
      setState(() {
        _tareas = tareas;
      });
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error al consultar tareas: $e');
    }
  }

  Future<void> _agregarTarea() async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      _mostrarMensaje('Escribe un título válido (no vacío).');
      return;
    }

    try {
      await _db.insertarTarea(titulo);
      _tituloController.clear();
      await _cargarTareas();
    } catch (e) {
      _mostrarMensaje('No se pudo guardar la tarea: $e');
    }
  }

  void _alternarCompletada(Tarea tarea, bool completada) {
    _mostrarMensaje('Implementar actualización de tarea');
  }

  void _editarTarea(Tarea tarea) {
    _mostrarMensaje('Implementar edición de título');
  }

  void _eliminarTarea(Tarea tarea) {
    _mostrarMensaje('Implementar eliminación de tarea');
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
                            title: Text(tarea.titulo),
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
