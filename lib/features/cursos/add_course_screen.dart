import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/course_model.dart'; // Asegúrate de que la ruta sea correcta

class AddCourseScreen extends StatefulWidget {
  final String? courseKey; // Si es null, es nuevo. Si viene, es edición.
  final Curso? cursoExistente;

  const AddCourseScreen({Key? key, this.courseKey, this.cursoExistente}) : super(key: key);

  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('oferta_educativa');

  // Controladores Básicos
  late TextEditingController _tituloCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _costoUCtrl;
  late TextEditingController _costoPCtrl;
  late TextEditingController _costoCCtrl;
  late TextEditingController _linkCtrl;
  String _modalidad = 'Virtual';

  // Archivo
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  // Lógica de Grupos Dinámicos
  List<Grupo> _grupos = [];

  @override
  void initState() {
    super.initState();
    // Inicializar con datos existentes o vacíos
    final c = widget.cursoExistente;
    _tituloCtrl = TextEditingController(text: c?.titulo ?? '');
    _descCtrl = TextEditingController(text: c?.descripcion ?? '');
    _costoUCtrl = TextEditingController(text: c?.costoUntels.toString() ?? '80');
    _costoPCtrl = TextEditingController(text: c?.costoPublico.toString() ?? '100');
    _costoCCtrl = TextEditingController(text: c?.costoConadis.toString() ?? '80');
    _linkCtrl = TextEditingController(text: c?.linkInscripcion ?? '');
    _modalidad = c?.modalidad ?? 'Virtual';

    if (c != null && c.grupos.isNotEmpty) {
      _grupos = List.from(c.grupos); // Copia para editar
    } else {
      // Por defecto un grupo vacío
      _grupos.add(Grupo(nombre: 'Grupo 1', dias: [], horaInicio: '18:00', horaFin: '20:00'));
    }
  }

  // --- MÉTODOS DE UI ---

  // Seleccionar PDF
  Future<void> _pickBrochure() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  // Guardar Todo
  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_grupos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Debe haber al menos 1 grupo")));
      return;
    }

    setState(() => _isUploading = true);

    String? brochureUrl = widget.cursoExistente?.brochureUrl;
    String? driveId = widget.cursoExistente?.driveFileId;

    // 1. Si hay archivo nuevo, subir a Drive (Simulado por ahora)
    if (_pickedFile != null) {
      // AQUÍ LLAMAREMOS LUEGO A: DriveService().uploadFile(_pickedFile!)
      // Por ahora simulamos un delay
      await Future.delayed(Duration(seconds: 2));
      print("Simulando subida de archivo: ${_pickedFile!.name}");
      brochureUrl = "https://drive.google.com/fake_link_pdf"; // Placeholder
    }

    // 2. Construir Objeto
    final nuevoCurso = Curso(
      titulo: _tituloCtrl.text,
      descripcion: _descCtrl.text,
      costoUntels: int.parse(_costoUCtrl.text),
      costoPublico: int.parse(_costoPCtrl.text),
      costoConadis: int.parse(_costoCCtrl.text),
      linkInscripcion: _linkCtrl.text,
      modalidad: _modalidad,
      activo: true,
      brochureUrl: brochureUrl,
      driveFileId: driveId,
      grupos: _grupos,
    );

    // 3. Enviar a Firebase
    try {
      if (widget.courseKey == null) {
        await _dbRef.push().set(nuevoCurso.toJson());
      } else {
        await _dbRef.child(widget.courseKey!).update(nuevoCurso.toJson());
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Widget para seleccionar hora
  Future<void> _selectTime(BuildContext context, int index, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() {
        final timeStr = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        if (isStart) {
          _grupos[index].horaInicio = timeStr;
        } else {
          _grupos[index].horaFin = timeStr;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseKey == null ? "Nuevo Curso" : "Editar Curso"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isUploading
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text("Guardando curso y subiendo PDF...")]))
          : Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // --- DATOS GENERALES ---
            Text("Información General", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            SizedBox(height: 10),
            TextFormField(controller: _tituloCtrl, decoration: InputDecoration(labelText: "Título del Curso", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
            SizedBox(height: 10),
            TextFormField(controller: _descCtrl, decoration: InputDecoration(labelText: "Descripción corta", border: OutlineInputBorder()), maxLines: 2),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _costoUCtrl, decoration: InputDecoration(labelText: "Costo UNTELS", prefixText: "S/ "), keyboardType: TextInputType.number)),
                SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _costoPCtrl, decoration: InputDecoration(labelText: "Costo Público", prefixText: "S/ "), keyboardType: TextInputType.number)),
              ],
            ),
            TextFormField(controller: _costoCCtrl, decoration: InputDecoration(labelText: "Costo CONADIS", prefixText: "S/ "), keyboardType: TextInputType.number),
            SizedBox(height: 10),
            TextFormField(controller: _linkCtrl, decoration: InputDecoration(labelText: "Link Forms", prefixIcon: Icon(Icons.link))),

            SizedBox(height: 20),
            // --- BROCHURE ---
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(_pickedFile != null
                        ? "Seleccionado: ${_pickedFile!.name}"
                        : (widget.cursoExistente?.brochureUrl != null ? "PDF ya subido (Mantener)" : "Ningún PDF seleccionado")),
                  ),
                  TextButton(onPressed: _pickBrochure, child: Text("SUBIR"))
                ],
              ),
            ),

            SizedBox(height: 20),
            Divider(thickness: 2),

            // --- GRUPOS DINÁMICOS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Grupos y Horarios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.teal, size: 30),
                  onPressed: () {
                    setState(() {
                      _grupos.add(Grupo(nombre: 'Grupo ${_grupos.length + 1}', dias: [], horaInicio: '18:00', horaFin: '20:00'));
                    });
                  },
                )
              ],
            ),

            // LISTA DE TARJETAS DE GRUPOS
            ..._grupos.asMap().entries.map((entry) {
              int idx = entry.key;
              Grupo grupo = entry.value;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: grupo.nombre,
                              decoration: InputDecoration(labelText: "Nombre del Grupo"),
                              onChanged: (val) => grupo.nombre = val,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              if (_grupos.length > 1) {
                                setState(() => _grupos.removeAt(idx));
                              }
                            },
                          )
                        ],
                      ),
                      SizedBox(height: 10),
                      Text("Días de clase:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 5,
                        children: ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"].map((dia) {
                          final isSelected = grupo.dias.contains(dia);
                          return FilterChip(
                            label: Text(dia.substring(0, 3)), // Lun, Mar, Mie
                            selected: isSelected,
                            selectedColor: Colors.teal.shade100,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) grupo.dias.add(dia);
                                else grupo.dias.remove(dia);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.access_time),
                          SizedBox(width: 5),
                          TextButton(
                            onPressed: () => _selectTime(context, idx, true),
                            child: Text("Inicio: ${grupo.horaInicio}", style: TextStyle(fontSize: 16)),
                          ),
                          Text("-"),
                          TextButton(
                            onPressed: () => _selectTime(context, idx, false),
                            child: Text("Fin: ${grupo.horaFin}", style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: EdgeInsets.symmetric(vertical: 15)),
              onPressed: _saveCourse,
              child: Text("GUARDAR CURSO COMPLETO", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}