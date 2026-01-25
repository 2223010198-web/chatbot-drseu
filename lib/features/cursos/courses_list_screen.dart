import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/course_model.dart';
import 'add_course_screen.dart';

class CoursesListScreen extends StatefulWidget {
  @override
  _CoursesListScreenState createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('oferta_educativa');
  List<Curso> _cursos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCursos();
  }

  void _cargarCursos() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      final List<Curso> loaded = [];
      if (data != null && data is Map) {
        data.forEach((key, value) {
          try {
            loaded.add(Curso.fromMap(key, value));
          } catch (e) {
            print("Error cargando curso $key: $e");
          }
        });
      }

      loaded.sort((a, b) {
        if (a.activo != b.activo) {
          return a.activo ? -1 : 1;
        }
        return a.orden.compareTo(b.orden);
      });

      if (mounted) {
        setState(() {
          _cursos = loaded;
          _isLoading = false;
        });
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _cursos[oldIndex];

    setState(() {
      _cursos.removeAt(oldIndex);
      _cursos.insert(newIndex, item);
    });

    for (int i = 0; i < _cursos.length; i++) {
      final curso = _cursos[i];
      if (curso.orden != i + 1) {
        _dbRef.child(curso.key!).update({'orden': i + 1});
      }
    }
  }

  // --- DIÁLOGO DE ELIMINACIÓN PERMANENTE ---
  void _confirmarEliminacionCurso(Curso curso) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("⚠️ Eliminar Curso"),
        content: Text("Estás a punto de eliminar '${curso.titulo}' permanentemente de la base de datos.\n\nEsta acción NO se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              // ELIMINAR DE FIREBASE
              await _dbRef.child(curso.key!).remove();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Curso eliminado")));
            },
            child: Text("ELIMINAR DEFINITIVAMENTE"),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO DE OPCIONES (STATUS / DELETE) ---
  void _showOptionsDialog(Curso curso) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(curso.titulo, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text("Selecciona una acción:"),
          ),

          // OPCIÓN 1: ACTIVAR / DESACTIVAR
          SimpleDialogOption(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Icon(curso.activo ? Icons.visibility_off : Icons.visibility, color: curso.activo ? Colors.orange : Colors.green),
                SizedBox(width: 15),
                Text(curso.activo ? "Desactivar (Ocultar)" : "Activar (Visible)"),
              ],
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _dbRef.child(curso.key!).update({'activo': !curso.activo});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(curso.activo ? "Curso desactivado" : "Curso activado")),
              );
            },
          ),

          // OPCIÓN 2: ELIMINAR
          SimpleDialogOption(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red),
                SizedBox(width: 15),
                Text("Eliminar Curso", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx); // Cierra el menú de opciones
              _confirmarEliminacionCurso(curso); // Abre la alerta de confirmación
            },
          ),

          // OPCIÓN 3: CANCELAR
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Cancelar"),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestionar Cursos"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddCourseScreen()));
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
        padding: EdgeInsets.only(bottom: 80),
        itemCount: _cursos.length,
        buildDefaultDragHandles: false,
        onReorder: _onReorder,
        itemBuilder: (context, index) {
          final curso = _cursos[index];

          return Container(
            key: ValueKey(curso.key),
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: InkWell(
              // Llama al nuevo diálogo de opciones
              onLongPress: () => _showOptionsDialog(curso),
              borderRadius: BorderRadius.circular(10),
              child: Card(
                elevation: 2,
                color: curso.activo ? Colors.white : Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: curso.activo ? Colors.teal : Colors.grey,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    curso.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: curso.activo ? null : TextDecoration.lineThrough,
                      color: curso.activo ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${curso.categoria} • ${curso.modalidadCalculada.toUpperCase()}",
                        style: TextStyle(color: curso.activo ? Colors.grey[700] : Colors.grey[500], fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: curso.activo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: curso.activo ? Colors.green : Colors.red, width: 0.5)
                        ),
                        child: Text(
                          curso.activo ? "🟢 Visible" : "🔴 Oculto",
                          style: TextStyle(
                            color: curso.activo ? Colors.green[700] : Colors.red[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddCourseScreen(
                              courseKey: curso.key,
                              cursoExistente: curso,
                            ),
                          ));
                        },
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Icon(Icons.drag_handle, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}