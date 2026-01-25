import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/course_model.dart';
import 'components/general_info_card.dart';
import 'components/label_card.dart';

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

  // Controladores básicos
  late TextEditingController _tituloCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _linkCtrl;
  late TextEditingController _formIdCtrl;
  late TextEditingController _slideIdCtrl;

  // --- GESTIÓN DE CATEGORÍAS ---
  String _categoria = 'Cursos de Extensión';
  List<String> _categoriasOptions = ['Cursos de Extensión', 'Talleres Culturales', 'Otros'];

  // Modelos de datos complejos
  late GeneralInfo _generalInfo;
  late List<Etiqueta> _etiquetas;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cursoExistente;

    _tituloCtrl = TextEditingController(text: c?.titulo ?? '');
    _descCtrl = TextEditingController(text: c?.descripcion ?? '');
    _linkCtrl = TextEditingController(text: c?.linkInscripcion ?? '');
    _formIdCtrl = TextEditingController(text: c?.idsGoogle?['formId'] ?? '');
    _slideIdCtrl = TextEditingController(text: c?.idsGoogle?['slideTemplateId'] ?? '');

    if (c != null) {
      _categoria = c.categoria;
      // Aseguramos que la categoría del curso exista en la lista
      if (!_categoriasOptions.contains(_categoria)) {
        _categoriasOptions.add(_categoria);
      }

      _generalInfo = c.generalInfo;
      _etiquetas = List.from(c.etiquetas);
    } else {
      _generalInfo = GeneralInfo();
      _etiquetas = [
        Etiqueta(nombre: "General", grupos: [
          Grupo(nombre: "Grupo 1", dias: [], horaInicio: '', horaFin: '', fechaInicio: '', fechaFin: '')
        ])
      ];
    }
  }

  // --- LÓGICA DE CATEGORÍAS ---
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
    if (_categoriasOptions.length <= 1) return; // No dejar vacío
    setState(() {
      _categoriasOptions.remove(_categoria);
      _categoria = _categoriasOptions.first; // Seleccionar la primera disponible
    });
  }

  // Utilidad ID
  String? extraerGoogleId(String input) {
    if (input.isEmpty) return null;
    if (!input.contains("http")) return input.trim();
    final regex = RegExp(r'/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(input);
    return match != null ? match.group(1) : input;
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      int ordenFinal = 9999;
      if (widget.courseKey == null) {
        final snap = await _dbRef.orderByChild('orden').limitToLast(1).get();
        if (snap.exists) {
          final map = snap.value as Map;
          final ultimo = map.values.first as Map;
          ordenFinal = (ultimo['orden'] ?? 0) + 1;
        } else {
          ordenFinal = 1;
        }
      } else {
        ordenFinal = widget.cursoExistente?.orden ?? 9999;
      }

      final nuevoCurso = Curso(
        titulo: _tituloCtrl.text,
        descripcion: _descCtrl.text,
        categoria: _categoria,
        linkInscripcion: _linkCtrl.text,
        activo: widget.cursoExistente?.activo ?? true,
        brochureUrl: widget.cursoExistente?.brochureUrl,
        driveFileId: widget.cursoExistente?.driveFileId,
        orden: ordenFinal,
        idsGoogle: {
          'formId': extraerGoogleId(_formIdCtrl.text) ?? '',
          'slideTemplateId': extraerGoogleId(_slideIdCtrl.text) ?? '',
        },
        generalInfo: _generalInfo,
        etiquetas: _etiquetas,
      );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseKey == null ? "Nuevo Curso" : "Editar Curso"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isUploading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // 1. INFO BÁSICA
            TextFormField(controller: _tituloCtrl, decoration: InputDecoration(labelText: "Título", border: OutlineInputBorder())),
            SizedBox(height: 15),

            // --- SELECCIÓN DE CATEGORÍA RESTAURADA ---
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

            SizedBox(height: 20),

            // 2. DATOS GENERALES
            GeneralInfoCard(
              info: _generalInfo,
              onUpdate: () => setState((){}),
            ),

            SizedBox(height: 20),
            Divider(thickness: 2, color: Colors.teal),

            // 3. GRUPOS Y ETIQUETAS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Grupos y Horarios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Nueva Etiqueta"),
                  onPressed: () {
                    setState(() {
                      _etiquetas.add(Etiqueta(nombre: "Nueva Etiqueta", grupos: []));
                    });
                  },
                )
              ],
            ),

            ..._etiquetas.asMap().entries.map((entry) {
              return LabelCard(
                labelIndex: entry.key + 1,
                etiqueta: entry.value,
                onDuplicate: (orig) => setState(() => _etiquetas.add(orig.clone())),
                onDelete: () => setState(() => _etiquetas.removeAt(entry.key)),
                onUpdate: () => setState((){}),
              );
            }).toList(),

            SizedBox(height: 20),

            // 4. AUTOMATIZACIÓN GOOGLE
            ExpansionTile(
              title: Text("🤖 Automatización (Google)", style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      TextFormField(controller: _formIdCtrl, decoration: InputDecoration(labelText: "ID Google Form", prefixIcon: Icon(Icons.list_alt))),
                      TextFormField(controller: _slideIdCtrl, decoration: InputDecoration(labelText: "ID Google Slide", prefixIcon: Icon(Icons.slideshow))),
                    ],
                  ),
                )
              ],
            ),

            SizedBox(height: 30),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: EdgeInsets.symmetric(vertical: 15)),
                onPressed: _saveCourse,
                child: Text("GUARDAR CURSO", style: TextStyle(fontSize: 18, color: Colors.white))
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}