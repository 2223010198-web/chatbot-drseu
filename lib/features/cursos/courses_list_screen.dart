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

  // Escucha los cambios en tiempo real
  void _cargarCursos() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      final List<Curso> loaded = [];
      if (data != null && data is Map) {
        data.forEach((key, value) {
          loaded.add(Curso.fromMap(key, value));
        });
      }

      // --- ORDENAMIENTO INTELIGENTE ---
      // 1. Activos arriba, Inactivos abajo.
      // 2. Respetar el 'orden' manual dentro de su grupo.
      loaded.sort((a, b) {
        if (a.activo != b.activo) {
          return a.activo ? -1 : 1; // Si a es activo va antes
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

  // Función para reordenar y actualizar Firebase
  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;

    // Evitar mover un curso inactivo a la zona de activos o viceversa visualmente
    // (Aunque el sort lo corregirá, es mejor evitar la confusión)
    final item = _cursos[oldIndex];

    setState(() {
      _cursos.removeAt(oldIndex);
      _cursos.insert(newIndex, item);
    });

    // Actualizar indices en Firebase
    for (int i = 0; i < _cursos.length; i++) {
      final curso = _cursos[i];
      if (curso.orden != i + 1) {
        _dbRef.child(curso.key!).update({'orden': i + 1});
      }
    }
  }

  // --- LÓGICA DE ACTIVAR / DESACTIVAR ---
  void _showToggleStatusDialog(Curso curso) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(curso.activo ? "🛑 Desactivar Curso" : "✅ Activar Curso"),
        content: Text(curso.activo
            ? "El curso '${curso.titulo}' dejará de ser visible en el Chatbot y se moverá al final de esta lista.\n\n¿Deseas continuar?"
            : "El curso '${curso.titulo}' volverá a ser visible para los usuarios y aparecerá en el listado.\n\n¿Deseas activarlo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: curso.activo ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Actualizamos en Firebase
              // Al cambiar 'activo', el listener _cargarCursos se disparará,
              // detectará el cambio y lo mandará al final de la lista automáticamente por el sort.
              await _dbRef.child(curso.key!).update({'activo': !curso.activo});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(curso.activo ? "Curso desactivado" : "Curso activado")),
              );
            },
            child: Text(curso.activo ? "Desactivar" : "Activar"),
          ),
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
        // Importante: Desactivar el arrastre por defecto para poder usar onLongPress en la tarjeta
        buildDefaultDragHandles: false,
        onReorder: _onReorder,
        itemBuilder: (context, index) {
          final curso = _cursos[index];

          return Container(
            key: ValueKey(curso.key), // Clave única necesaria para reorder
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: InkWell(
              // --- AQUÍ ESTÁ LA MAGIA DEL MANTENER PRESIONADO ---
              onLongPress: () => _showToggleStatusDialog(curso),
              borderRadius: BorderRadius.circular(10),
              child: Card(
                elevation: 2,
                // Si está inactivo, lo ponemos un poco gris para diferenciar
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
                      decoration: curso.activo ? null : TextDecoration.lineThrough, // Tachado si inactivo
                      color: curso.activo ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${curso.categoria} • ${curso.modalidad}",
                        style: TextStyle(color: curso.activo ? Colors.grey[700] : Colors.grey[500]),
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
                          curso.activo ? "🟢 Visible en Chat" : "🔴 Oculto",
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
                      // Usamos ReorderableDragStartListener para que SOLO este icono sirva para arrastrar
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