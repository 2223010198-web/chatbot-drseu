import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/course_model.dart';
import '../cursos/add_course_screen.dart'; // Importa tu formulario

class CoursesListScreen extends StatefulWidget {
  @override
  _CoursesListScreenState createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  final _dbRef = FirebaseDatabase.instance.ref().child('oferta_educativa');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestión de Cursos"), centerTitle: true),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            // LÓGICA PARA LEER EL NUEVO MODELO 'CURSO'
            Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map;
            List<Curso> cursos = [];

            map.forEach((key, value) {
              // Convertimos el JSON de Firebase a nuestro objeto Curso
              try {
                cursos.add(Curso.fromMap(key, Map<String, dynamic>.from(value)));
              } catch (e) {
                print("Error parseando curso $key: $e");
              }
            });

            // Ordenar por título
            cursos.sort((a, b) => a.titulo.compareTo(b.titulo));

            return ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: cursos.length,
              itemBuilder: (context, index) {
                final curso = cursos[index];

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: curso.activo ? Colors.teal : Colors.grey,
                      child: Icon(Icons.school, color: Colors.white),
                    ),
                    title: Text(curso.titulo, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${curso.modalidad} - ${curso.grupos.length} Grupos"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // AL TOCAR, VAMOS A EDITAR
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddCourseScreen(
                            courseKey: curso.key,
                            cursoExistente: curso,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          return Center(child: Text("No hay cursos. Agrega uno."));
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // AL TOCAR +, VAMOS A CREAR
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCourseScreen()),
          );
        },
      ),
    );
  }
}