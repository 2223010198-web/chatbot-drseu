import 'dart:convert'; // Para jsonEncode
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http; // Para conectar con el Script
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

  final String _googleScriptUrl = "https://script.google.com/a/macros/untels.edu.pe/s/AKfycby9--246QZtElfQmkyNT-0g5kSIdsxmXMSPoa4NJk-j89WOthOF2d027rE9--wQcF7McQ/exec";

  // Controladores básicos
  late TextEditingController _tituloCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _linkCtrl;
  late TextEditingController _formIdCtrl;
//  late TextEditingController _slideIdCtrl;

  // --- NUEVOS CONTROLADORES ---
  // Para la Imagen (Cloudinary)
  late TextEditingController _imgSlideIdCtrl;   // ID del archivo Slide para imagen
  late TextEditingController _imgSlidePageCtrl; // Número de diapositiva (ej: 1)

  // Para el PDF (Brochure)
  late TextEditingController _pdfSlideIdCtrl;    // ID del archivo Slide para PDF
  late TextEditingController _pdfSlideRangeCtrl; // Rango (ej: "1-3" o "1")

  late TextEditingController _urlImagenResultCtrl;
  late TextEditingController _urlPdfResultCtrl;

  // --- GESTIÓN DE CATEGORÍAS ---
  String _categoria = 'Cursos de Extensión';
  List<String> _categoriasOptions = ['Cursos de Extensión', 'Talleres Culturales', 'Otros'];

  // Modelos de datos complejos
  late GeneralInfo _generalInfo;
  late List<Etiqueta> _etiquetas;
  bool _isUploading = false;

  // --- ESTADO DE VISIBILIDAD DE VARIABLES ---
  bool _showVariables = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cursoExistente;

    _tituloCtrl = TextEditingController(text: c?.titulo ?? '');
    _descCtrl = TextEditingController(text: c?.descripcion ?? '');
    _linkCtrl = TextEditingController(text: c?.linkInscripcion ?? '');
    _formIdCtrl = TextEditingController(text: c?.idsGoogle?['formId'] ?? '');

    _imgSlideIdCtrl = TextEditingController(text: c?.idsGoogle?['imgSlideId'] ?? '');
    _imgSlidePageCtrl = TextEditingController(text: c?.idsGoogle?['imgPage'] ?? '1'); // Por defecto pág 1

    // PDF
    _pdfSlideIdCtrl = TextEditingController(text: c?.idsGoogle?['pdfSlideId'] ?? c?.idsGoogle?['slideTemplateId'] ?? ''); // Migración compatible
    _pdfSlideRangeCtrl = TextEditingController(text: c?.idsGoogle?['pdfRange'] ?? '1');

    _urlImagenResultCtrl = TextEditingController(text: c?.brochureUrl ?? '');
    _urlPdfResultCtrl = TextEditingController(text: c?.pdfUrl ?? '');
    if (c != null) {
      _categoria = c.categoria;
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
    if (_categoriasOptions.length <= 1) return;
    setState(() {
      _categoriasOptions.remove(_categoria);
      _categoria = _categoriasOptions.first;
    });
  }

  String? extraerGoogleId(String input) {
    if (input.isEmpty) return null;
    if (!input.contains("http")) return input.trim();
    final regex = RegExp(r'/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(input);
    return match != null ? match.group(1) : input;
  }

  // --- 🔥 NUEVA FUNCIÓN: DISPARADOR WEBHOOK ---
  Future<void> _triggerGoogleSync(String courseKey) async {
    if (_googleScriptUrl.contains("TU_URL")) {
      print("⚠️ URL de script no configurada.");
      return;
    }
    try {
      print("🚀 Solicitando sincronización para: $courseKey");
      final response = await http.post(
        Uri.parse(_googleScriptUrl),
        body: jsonEncode({'courseId': courseKey}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        print("✅ Sincronización OK");
      } else {
        print("⚠️ Error Server Script: ${response.body}");
      }
    } catch (e) {
      print("❌ Error de red al sincronizar: $e");
    }
  }
  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);

    try {
      // 1. Calcular Orden (Solo si es nuevo)
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

      // 2. Crear Objeto Curso
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
//          'slideTemplateId': extraerGoogleId(_slideIdCtrl.text) ?? '',
          // --- NUEVOS CAMPOS GUARDADOS ---
          'imgSlideId': extraerGoogleId(_imgSlideIdCtrl.text) ?? '',
          'imgPage': _imgSlidePageCtrl.text.trim().isEmpty ? '1' : _imgSlidePageCtrl.text.trim(),

          'pdfSlideId': extraerGoogleId(_pdfSlideIdCtrl.text) ?? '',
          'pdfRange': _pdfSlideRangeCtrl.text.trim().isEmpty ? '1' : _pdfSlideRangeCtrl.text.trim(),
        },
        generalInfo: _generalInfo,
        etiquetas: _etiquetas,
      );

      // 3. Guardar en Firebase
      String keyFinal = widget.courseKey ?? '';

      if (widget.courseKey == null) {
        // Guardar Nuevo
        final newRef = await _dbRef.push();
        await newRef.set(nuevoCurso.toJson());
        keyFinal = newRef.key!;
      } else {
        // Actualizar Existente
        await _dbRef.child(widget.courseKey!).update(nuevoCurso.toJson());
      }

      // 4. 🔥 DISPARAR SINCRONIZACIÓN (Segundo plano)
      // No usamos 'await' bloqueante para que la UI responda rápido
      _triggerGoogleSync(keyFinal).then((_) {
        // Opcional: Mostrar confirmación extra en consola
        print("Sincronización terminada para $keyFinal");
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Curso guardado. Actualizando Google Forms/Slides..."),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          )
      );

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
        actions: [
          // 🔥 NUEVO BOTÓN EN LA ESQUINA SUPERIOR DERECHA
          // Deshabilitamos el botón si ya se está subiendo (_isUploading)
          _isUploading
              ? Padding(padding: EdgeInsets.all(14.0), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : TextButton.icon(
            onPressed: _saveCourse,
            icon: Icon(Icons.save, color: Colors.white),
            label: Text("GUARDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 10),
        ],
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
            // --- 1. INFO BÁSICA ---
            TextFormField(
                controller: _tituloCtrl,
                decoration: InputDecoration(labelText: "Título", border: OutlineInputBorder())
            ),

            SizedBox(height: 15),

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
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.teal),
                  onPressed: _mostrarDialogoNuevaCategoria,
                ),
                if (_categoriasOptions.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _eliminarCategoriaActual,
                  ),
              ],
            ),

            SizedBox(height: 20),

            // --- 2. DATOS GENERALES ---
            GeneralInfoCard(
              info: _generalInfo,
              linkController: _linkCtrl,
              showVariables: _showVariables, // Pasamos estado del switch
              onUpdate: () => setState((){}),
            ),

            SizedBox(height: 20),
            Divider(thickness: 2, color: Colors.teal),

            // --- 3. GRUPOS Y ETIQUETAS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Grupos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),

                // Switch "Vars" y Botón Agregar Etiqueta
                Row(
                  children: [
                    Text("Vars", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Switch(
                      value: _showVariables,
                      activeColor: Colors.purple,
                      onChanged: (val) {
                        setState(() {
                          _showVariables = val;
                        });
                      },
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add, size: 18),
                      label: Text("Etiqueta"),
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 10)),
                      onPressed: () {
                        setState(() {
                          _etiquetas.add(Etiqueta(nombre: "Nueva Etiqueta", grupos: []));
                        });
                      },
                    ),
                  ],
                )
              ],
            ),

            // Renderizar Etiquetas
            ..._etiquetas.asMap().entries.map((entry) {
              return LabelCard(
                labelIndex: entry.key + 1,
                etiqueta: entry.value,
                showVariables: _showVariables, // Pasamos estado
                onDuplicate: (orig) => setState(() => _etiquetas.add(orig.clone())),
                onDelete: () => setState(() => _etiquetas.removeAt(entry.key)),
                onUpdate: () => setState((){}),
              );
            }).toList(),

            SizedBox(height: 20),

            // --- 4. AUTOMATIZACIÓN GOOGLE ---
            ExpansionTile(
              title: Text("🤖 Automatización (Google)", style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECCIÓN 1: FORMS
                      Text("📝 Inscripciones", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      TextFormField(
                          controller: _formIdCtrl,
                          decoration: InputDecoration(labelText: "ID Google Form", prefixIcon: Icon(Icons.list_alt), isDense: true)
                      ),
                      Divider(height: 30),

                      // SECCIÓN 2: IMAGEN PROMOCIONAL (CLOUDINARY)
                      Text("🖼️ Generación de Imagen (PNG)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      TextFormField(
                          controller: _imgSlideIdCtrl,
                          decoration: InputDecoration(
                              labelText: "ID Google Slide (Para Imagen)",
                              hintText: "ID del archivo de diseño",
                              prefixIcon: Icon(Icons.image),
                              isDense: true
                          )
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                          controller: _imgSlidePageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: "Número de Diapositiva",
                              hintText: "Ej: 1 (La primera), 2 (La segunda)...",
                              prefixIcon: Icon(Icons.pages),
                              border: OutlineInputBorder(),
                              isDense: true
                          )
                      ),
                      Divider(height: 30),

                      // SECCIÓN 3: BROCHURE (PDF)
                      Text("📄 Generación de Brochure (PDF)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      TextFormField(
                          controller: _pdfSlideIdCtrl,
                          decoration: InputDecoration(
                              labelText: "ID Google Slide (Para PDF)",
                              hintText: "Puede ser el mismo ID de arriba u otro",
                              prefixIcon: Icon(Icons.picture_as_pdf),
                              isDense: true
                          )
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                          controller: _pdfSlideRangeCtrl,
                          decoration: InputDecoration(
                              labelText: "Rango de Diapositivas",
                              hintText: "Ej: '1' (Solo una) o '1-3' (De la 1 a la 3)",
                              prefixIcon: Icon(Icons.format_list_numbered),
                              border: OutlineInputBorder(),
                              isDense: true
                          )
                      ),
                    ],
                  ),
                )
              ],
            ),

            SizedBox(height: 20),
            Divider(thickness: 2, color: Colors.blue),

            // --- 6. RESULTADOS DE SINCRONIZACIÓN ---
            Text("📂 Archivos Generados (Nube)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 10),

            // CAMPO IMAGEN CLOUDINARY
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _urlImagenResultCtrl,
                    readOnly: true, // No editable por usuario
                    decoration: InputDecoration(
                        labelText: "URL Imagen (Cloudinary)",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100]
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    // Lógica simple de copiado (requiere import 'package:flutter/services.dart';)
                    // Si no quieres importar nada, el usuario puede seleccionar y copiar manualmente.
                  },
                )
              ],
            ),
            SizedBox(height: 10),

            // CAMPO PDF DRIVE
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _urlPdfResultCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                        labelText: "URL Brochure (PDF Drive)",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100]
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.download),
                  label: Text("Abrir/Descargar"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () {
                    final url = _urlPdfResultCtrl.text;
                    if (url.isNotEmpty) {
                      // Aquí podrías usar url_launcher si lo tienes instalado
                      // O simplemente mostrar un diálogo con el link
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Link copiado: $url")));
                    }
                  },
                )
              ],
            ),

            SizedBox(height: 40),

          ],
        ),
      ),
    );
  }
}
