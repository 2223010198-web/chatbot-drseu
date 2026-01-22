import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:excel/excel.dart' hide Border; // Ocultamos Border para evitar conflicto con Flutter
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'general_list_screen.dart'; // Asegúrate de que este archivo exista

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- REFERENCIAS A FIREBASE ---
  final DatabaseReference _statsRef = FirebaseDatabase.instance.ref().child('stats/interes_post_conversacion');
  final DatabaseReference _configRef = FirebaseDatabase.instance.ref().child('config/bot_active'); // <--- FALTABA ESTA DEFINICIÓN

  // --- ESTADO ---
  bool _isLoading = true;
  bool _isBotActive = true; // Estado del bot (On/Off)

  // --- DATOS ---
  List<Map<dynamic, dynamic>> _allLogs = [];
  List<Map<dynamic, dynamic>> _filteredLogs = [];

  // --- FILTROS ---
  String _filterTime = 'Todo';
  DateTimeRange? _customDateRange;
  String? _filterCategory;
  String? _filterCourse;

  // Listas para Dropdowns
  List<String> _availableCategories = [];
  List<String> _availableCourses = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _listenToBotStatus(); // Iniciar escucha del interruptor
  }

  // --- 1. LÓGICA DE CONTROL DEL BOT (ON/OFF) ---
  void _listenToBotStatus() {
    _configRef.onValue.listen((event) {
      final val = event.snapshot.value;
      if (mounted) {
        setState(() {
          // Si es null (primera vez), asumimos true, si no, tomamos el valor de Firebase
          _isBotActive = val == null ? true : (val as bool);
        });
      }
    });
  }

  void _toggleBot(bool value) {
    // Guardar el nuevo estado en Firebase
    _configRef.set(value);

    // Feedback visual al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? "🟢 Bot ENCENDIDO" : "🔴 Bot APAGADO"),
        backgroundColor: value ? Colors.green : Colors.red,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // --- 2. CARGA DE ESTADÍSTICAS ---
  void _loadStats() {
    _statsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final Map<dynamic, dynamic> statsMap = data as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> tempList = [];
      final Set<String> categoriesSet = {};
      final Set<String> coursesSet = {};

      statsMap.forEach((key, value) {
        if (value['timestamp'] == null) value['timestamp'] = 0;

        // Llenar listas para filtros
        if (value['categoria'] != null) categoriesSet.add(value['categoria'].toString());
        if (value['nombre_curso'] != null) coursesSet.add(value['nombre_curso'].toString());

        tempList.add(value);
      });

      // Ordenar por fecha (más reciente primero)
      tempList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      if (mounted) {
        setState(() {
          _allLogs = tempList;
          _availableCategories = categoriesSet.toList()..sort();
          _availableCourses = coursesSet.toList()..sort();
          _applyFilters();
          _isLoading = false;
        });
      }
    });
  }

  // --- 3. LÓGICA DE FILTROS ---
  void _applyFilters() {
    final now = DateTime.now();

    setState(() {
      _filteredLogs = _allLogs.where((log) {
        bool passTime = true;
        bool passCat = true;
        bool passCourse = true;

        // Filtro de Tiempo
        if (_filterTime != 'Todo') {
          final logDate = DateTime.fromMillisecondsSinceEpoch(log['timestamp']);

          if (_filterTime == 'Semana') {
            passTime = now.difference(logDate).inDays <= 7;
          } else if (_filterTime == 'Mes') {
            passTime = logDate.month == now.month && logDate.year == now.year;
          } else if (_filterTime == 'Año') {
            passTime = logDate.year == now.year;
          } else if (_filterTime == 'Personalizado' && _customDateRange != null) {
            DateTime start = DateUtils.dateOnly(_customDateRange!.start);
            DateTime end = DateUtils.dateOnly(_customDateRange!.end).add(Duration(days: 1));
            passTime = logDate.isAfter(start) && logDate.isBefore(end);
          }
        }

        // Filtros de Categoría y Curso
        if (_filterCategory != null) passCat = log['categoria'] == _filterCategory;
        if (_filterCourse != null) passCourse = log['nombre_curso'] == _filterCourse;

        return passTime && passCat && passCourse;
      }).toList();
    });
  }

  // Modal para seleccionar rango de fechas
  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _filterTime = 'Personalizado';
        _applyFilters();
      });
    } else {
      // Si cancela y estaba en personalizado sin rango, volver a Todo
      if (_customDateRange == null) {
        setState(() {
          _filterTime = 'Todo';
          _applyFilters();
        });
      }
    }
  }

  // Limpiar formato del teléfono (quitar @c.us y 51)
  String _cleanPhone(String? raw) {
    if (raw == null) return "Desconocido";
    String s = raw.replaceAll('@c.us', '');
    if (s.startsWith('51') && s.length == 11) return s.substring(2);
    return s;
  }

  // --- 4. EXPORTAR A EXCEL ---
  Future<void> _exportToExcel(String courseName, List<Map> logs) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Cabeceras
    sheet.appendRow([TextCellValue('Fecha'), TextCellValue('Teléfono'), TextCellValue('Curso')]);

    // Datos
    for (var log in logs) {
      sheet.appendRow([
        TextCellValue(log['fecha'] ?? ''),
        TextCellValue(_cleanPhone(log['numero_usuario'])),
        TextCellValue(log['nombre_curso'] ?? ''),
      ]);
    }

    // Guardar y Compartir
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/reporte_${courseName.replaceAll(' ', '_')}.xlsx";
    final file = File(path);
    await file.writeAsBytes(excel.save()!);
    await Share.shareXFiles([XFile(path)], text: 'Reporte $courseName');
  }

  // --- 5. INTERFAZ GRÁFICA (BUILD) ---
  @override
  Widget build(BuildContext context) {
    // Preparar datos para el gráfico
    Map<String, int> courseCounts = {};
    for (var log in _filteredLogs) {
      String curso = log['nombre_curso'] ?? 'Otros';
      courseCounts[curso] = (courseCounts[curso] ?? 0) + 1;
    }
    var sortedCourses = courseCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text("Analítica"),
        backgroundColor: _isBotActive ? Colors.teal : Colors.grey, // Cambia color si está apagado
        foregroundColor: Colors.white,
        actions: [
          // --- SWITCH ON/OFF ---
          Row(
            children: [
              Text(_isBotActive ? "ON" : "OFF", style: TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: _isBotActive,
                activeColor: Colors.white,
                activeTrackColor: Colors.greenAccent,
                inactiveThumbColor: Colors.black,
                inactiveTrackColor: Colors.red[200],
                onChanged: _toggleBot,
              ),
            ],
          ),
          SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // --- AVISO DE BOT APAGADO ---
          if (!_isBotActive)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: EdgeInsets.all(5),
              child: Text(
                "⚠️ EL BOT ESTÁ APAGADO. NO RESPONDERÁ MENSAJES.",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // --- FILTROS ---
          _buildFilters(),

          // --- CONTENIDO PRINCIPAL ---
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta Resumen
                  _buildSummaryCard(_filteredLogs.length),
                  SizedBox(height: 20),

                  // Gráfico Horizontal
                  Text("📊 Demanda por Curso (Filtrado)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  _buildHorizontalChart(sortedCourses),

                  SizedBox(height: 30),
                  Divider(),

                  // Botón a Listado General
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GeneralListScreen()));
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📝 Listado General y Exportación", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[900])),
                              Text("Búsqueda avanzada y Excel masivo", style: TextStyle(fontSize: 12, color: Colors.teal[700])),
                            ],
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.teal),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildFilters() {
    return Container(
      color: Colors.teal.shade50,
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          // Fila 1: Tiempo y Categoría
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterTime,
                  decoration: InputDecoration(labelText: 'Periodo', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0), border: OutlineInputBorder()),
                  items: ['Todo', 'Semana', 'Mes', 'Año', 'Personalizado'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) {
                    if (v == 'Personalizado') {
                      _pickCustomRange();
                    } else {
                      setState(() { _filterTime = v!; _customDateRange = null; _applyFilters(); });
                    }
                  },
                ),
              ),
              // Chip de fecha si es personalizado
              if (_filterTime == 'Personalizado' && _customDateRange != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Chip(
                    label: Text("${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}"),
                    onDeleted: _pickCustomRange,
                    deleteIcon: Icon(Icons.edit, size: 14),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          // Fila 2: Categoría y Curso
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _filterCategory,
                  decoration: InputDecoration(labelText: 'Categoría', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0), border: OutlineInputBorder()),
                  items: [DropdownMenuItem(value: null, child: Text("Todas")), ..._availableCategories.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))],
                  onChanged: (v) { setState(() { _filterCategory = v; _applyFilters(); }); },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _filterCourse,
                  decoration: InputDecoration(labelText: 'Curso', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0), border: OutlineInputBorder()),
                  items: [DropdownMenuItem(value: null, child: Text("Todos")), ..._availableCourses.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))],
                  onChanged: (v) { setState(() { _filterCourse = v; _applyFilters(); }); },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int total) {
    return Card(
      elevation: 4,
      color: _isBotActive ? Colors.teal : Colors.grey, // Color gris si está apagado
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Interacciones", style: TextStyle(color: Colors.white70)),
                  Text("$total", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))
                ]
            ),
            Icon(Icons.bar_chart, color: Colors.white54, size: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalChart(List<MapEntry<String, int>> data) {
    if (data.isEmpty) return Text("No hay datos.");
    int maxValue = data.first.value;

    return Column(children: data.map((entry) {
      double percentage = entry.value / maxValue;
      return InkWell(
        onTap: () => _showCourseDetails(entry.key),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold))),
                    Icon(Icons.chevron_right, color: Colors.grey, size: 16)
                  ]
              ),
              SizedBox(height: 5),
              Stack(children: [
                Container(height: 30, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5))),
                FractionallySizedBox(widthFactor: percentage, child: Container(height: 30, decoration: BoxDecoration(color: Colors.teal.shade400, borderRadius: BorderRadius.circular(5)))),
                Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Align(alignment: Alignment.centerLeft, child: Text("${entry.value} interesados", style: TextStyle(color: percentage > 0.5 ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12))))),
              ])
            ],
          ),
        ),
      );
    }).toList());
  }

  void _showCourseDetails(String courseName) {
    final details = _filteredLogs.where((l) => l['nombre_curso'] == courseName).toList();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            builder: (_, controller) => Column(children: [
              AppBar(
                  title: Text(courseName),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(icon: Icon(Icons.file_download), onPressed: () => _exportToExcel(courseName, details))
                  ]
              ),
              Expanded(
                  child: ListView.builder(
                      controller: controller,
                      itemCount: details.length,
                      itemBuilder: (_, index) {
                        final log = details[index];
                        return ListTile(
                            leading: Icon(Icons.chat, color: Colors.green),
                            title: Text(_cleanPhone(log['numero_usuario'])),
                            subtitle: Text(log['fecha'] ?? '')
                        );
                      }
                  )
              ),
            ])
        )
    );
  }
}