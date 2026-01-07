import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../models/course_model.dart';

class AddCourseScreen extends StatefulWidget {
  final String? courseKey;
  final Curso? cursoExistente;

  const AddCourseScreen({Key? key, this.courseKey, this.cursoExistente}) : super(key: key);

  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('oferta_educativa');

  // --- CONTROLADORES ---
  late TextEditingController _tituloCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _costoUCtrl;
  late TextEditingController _costoPCtrl;
  late TextEditingController _costoCCtrl; // Recuperado: Costo Conadis
  late TextEditingController _linkCtrl;   // Recuperado: Link

  String _modalidad = 'Virtual';
  String _categoria = 'Cursos de Extensión';

  // Lista dinámica de categorías
  List<String> _categoriasOptions = [
    'Cursos de Extensión',
    'Talleres Culturales',
    'Webinars Gratuitos',
    'Diplomados',
    'Otros'
  ];

  PlatformFile? _pickedFile; // Para el Brochure
  bool _isUploading = false;
  List<Grupo> _grupos = [];

  @override
  void initState() {
    super.initState();
    final c = widget.cursoExistente;
    _tituloCtrl = TextEditingController(text: c?.titulo ?? '');
    _descCtrl = TextEditingController(text: c?.descripcion ?? '');
    _costoUCtrl = TextEditingController(text: c?.costoUntels.toString() ?? '80');
    _costoPCtrl = TextEditingController(text: c?.costoPublico.toString() ?? '100');
    _costoCCtrl = TextEditingController(text: c?.costoConadis.toString() ?? '80');
    _linkCtrl = TextEditingController(text: c?.linkInscripcion ?? '');
    _modalidad = c?.modalidad ?? 'Virtual';

    // Si la categoría del curso no está en la lista, la agregamos
    if (c != null && c.categoria.isNotEmpty) {
      _categoria = c.categoria;
      if (!_categoriasOptions.contains(_categoria)) {
        _categoriasOptions.add(_categoria);
      }
    }

    if (c != null && c.grupos.isNotEmpty) {
      _grupos = List.from(c.grupos);
    } else {
      _grupos.add(Grupo(
          nombre: 'Grupo 1', dias: [],
          horaInicio: '18:00', horaFin: '20:00',
          fechaInicio: '', fechaFin: ''
      ));
    }
  }

  // --- LÓGICA DE NEGOCIO ---

  void _mostrarDialogoNuevaCategoria() {
    final TextEditingController _nuevaCatCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nueva Categoría"),
        content: TextField(
          controller: _nuevaCatCtrl,
          decoration: InputDecoration(hintText: "Ej: Seminarios"),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (_nuevaCatCtrl.text.trim().isNotEmpty) {
                setState(() {
                  String nueva = _nuevaCatCtrl.text.trim();
                  if (!_categoriasOptions.contains(nueva)) _categoriasOptions.add(nueva);
                  _categoria = nueva;
                });
                Navigator.pop(ctx);
              }
            },
            child: Text("Agregar"),
          )
        ],
      ),
    );
  }

  void _eliminarCategoriaActual() {
    if (_categoriasOptions.length <= 1) return; // No borrar la última
    setState(() {
      _categoriasOptions.remove(_categoria);
      _categoria = _categoriasOptions.first; // Volver a la primera
    });
  }

  Future<void> _pickBrochure() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _deleteCourse() async {
    // Confirmación antes de borrar
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Eliminar Curso?"),
        content: Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && widget.courseKey != null) {
      await _dbRef.child(widget.courseKey!).remove();
      Navigator.pop(context); // Volver a la lista
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación de fechas
    for (var g in _grupos) {
      if (g.fechaInicio.isEmpty || g.fechaFin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Faltan fechas en ${g.nombre}")));
        return;
      }
    }

    setState(() => _isUploading = true);

    String? brochureUrl = widget.cursoExistente?.brochureUrl;
    String? driveId = widget.cursoExistente?.driveFileId;

    // LÓGICA DE SUBIDA A DRIVE (Aquí conectaríamos el DriveService)
    if (_pickedFile != null) {
      // await DriveService().upload(_pickedFile!);
      print("Simulando subida a Drive de: ${_pickedFile!.name}");
      // brochureUrl = ...
    }

    final nuevoCurso = Curso(
      titulo: _tituloCtrl.text,
      descripcion: _descCtrl.text,
      categoria: _categoria,
      costoUntels: int.tryParse(_costoUCtrl.text) ?? 0,
      costoPublico: int.tryParse(_costoPCtrl.text) ?? 0,
      costoConadis: int.tryParse(_costoCCtrl.text) ?? 0, // RECUPERADO
      linkInscripcion: _linkCtrl.text, // RECUPERADO
      modalidad: _modalidad,
      activo: true,
      brochureUrl: brochureUrl,
      driveFileId: driveId,
      grupos: _grupos,
    );

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

  // Funciones auxiliares de fecha y hora
  Future<void> _selectDate(int groupIndex, bool isStart) async {
    DateTime? picked = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (picked != null) {
      setState(() {
        String f = DateFormat('dd/MM/yyyy').format(picked);
        if (isStart) _grupos[groupIndex].fechaInicio = f; else _grupos[groupIndex].fechaFin = f;
      });
    }
  }

  Future<void> _selectTime(int index, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: 18, minute: 0));
    if (picked != null) {
      setState(() {
        final t = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        if (isStart) _grupos[index].horaInicio = t; else _grupos[index].horaFin = t;
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
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Guardando cambios..."),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // --- SECCIÓN 1: CATEGORÍA ---
            Text("Clasificación", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _categoriasOptions.contains(_categoria) ? _categoria : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: _categoriasOptions.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _categoria = val!),
                  ),
                ),
                // Botón Agregar Categoría
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.teal),
                  tooltip: "Crear nueva categoría",
                  onPressed: _mostrarDialogoNuevaCategoria,
                ),
                // Botón Eliminar Categoría (Solo si hay más de 1)
                if (_categoriasOptions.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: "Eliminar esta categoría",
                    onPressed: _eliminarCategoriaActual,
                  ),
              ],
            ),
            SizedBox(height: 15),

            // --- SECCIÓN 2: DATOS GENERALES ---
            Text("Información Básica", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            SizedBox(height: 5),
            TextFormField(
              controller: _tituloCtrl,
              decoration: InputDecoration(labelText: "Título del Curso", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: "Descripción", border: OutlineInputBorder()),
              maxLines: 2,
            ),
            SizedBox(height: 10),

            // --- COSTOS (3 Columnas o 2 filas) ---
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costoUCtrl,
                    decoration: InputDecoration(labelText: "UNTELS", prefixText: "S/ "),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _costoPCtrl,
                    decoration: InputDecoration(labelText: "Público", prefixText: "S/ "),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _costoCCtrl, // CAMPO RECUPERADO
                    decoration: InputDecoration(labelText: "CONADIS", prefixText: "S/ "),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // --- LINK INCRIPCIÓN (RECUPERADO) ---
            TextFormField(
              controller: _linkCtrl,
              decoration: InputDecoration(
                labelText: "Link de Inscripción (Forms)",
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            // --- BROCHURE PDF (RECUPERADO) ---
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pickedFile != null
                          ? "Nuevo: ${_pickedFile!.name}"
                          : (widget.cursoExistente?.brochureUrl != null
                          ? "PDF ya cargado (Mantener)"
                          : "Sin Brochure PDF"),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _pickBrochure,
                    child: Text("SUBIR"),
                  )
                ],
              ),
            ),

            SizedBox(height: 20),
            Divider(thickness: 2),

            // --- SECCIÓN 3: GRUPOS DINÁMICOS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Grupos y Horarios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                ElevatedButton.icon(
                  icon: Icon(Icons.add, size: 18, color: Colors.white),
                  label: Text("Grupo", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () {
                    setState(() {
                      _grupos.add(Grupo(
                        nombre: 'Grupo ${_grupos.length + 1}',
                        dias: [],
                        horaInicio: '18:00', horaFin: '20:00',
                        fechaInicio: '', fechaFin: '',
                      ));
                    });
                  },
                )
              ],
            ),

            // LISTA DE TARJETAS DE GRUPO
            ..._grupos.asMap().entries.map((entry) {
              int idx = entry.key;
              Grupo grupo = entry.value;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Nombre y Eliminar
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: grupo.nombre,
                              decoration: InputDecoration(labelText: "Nombre del Grupo", contentPadding: EdgeInsets.zero),
                              onChanged: (val) => grupo.nombre = val,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              if (_grupos.length > 1) setState(() => _grupos.removeAt(idx));
                            },
                          )
                        ],
                      ),
                      SizedBox(height: 10),

                      // 2. Fechas (Inicio / Fin)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(idx, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Inicio",
                                  prefixIcon: Icon(Icons.date_range, size: 16),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: Text(grupo.fechaInicio.isEmpty ? "-" : grupo.fechaInicio, style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(idx, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Fin",
                                  prefixIcon: Icon(Icons.event_busy, size: 16),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: Text(grupo.fechaFin.isEmpty ? "-" : grupo.fechaFin, style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      // 3. Días (Chips)
                      Text("Días:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 4,
                        children: ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"].map((dia) {
                          final isSelected = grupo.dias.contains(dia);
                          return ChoiceChip(
                            label: Text(dia, style: TextStyle(fontSize: 11)),
                            selected: isSelected,
                            selectedColor: Colors.teal.shade100,
                            onSelected: (selected) {
                              setState(() {
                                selected ? grupo.dias.add(dia) : grupo.dias.remove(dia);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      // 4. Horas
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(idx, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Hora Inicio",
                                  prefixIcon: Icon(Icons.access_time, size: 18),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                ),
                                child: Text(grupo.horaInicio, style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(idx, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: "Hora Fin",
                                  prefixIcon: Icon(Icons.access_time_filled, size: 18),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                ),
                                child: Text(grupo.horaFin, style: TextStyle(fontSize: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 30),

            // --- BOTÓN GUARDAR ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _saveCourse,
              child: Text("GUARDAR CURSO", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),

            SizedBox(height: 20),

            // --- BOTÓN ELIMINAR CURSO (Solo si editamos) ---
            if (widget.courseKey != null)
              TextButton.icon(
                icon: Icon(Icons.delete_forever),
                label: Text("ELIMINAR CURSO PERMANENTEMENTE"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: _deleteCourse,
              ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}