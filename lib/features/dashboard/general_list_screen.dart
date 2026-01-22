import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class GeneralListScreen extends StatefulWidget {
  @override
  _GeneralListScreenState createState() => _GeneralListScreenState();
}

class _GeneralListScreenState extends State<GeneralListScreen> {
  final DatabaseReference _statsRef = FirebaseDatabase.instance.ref().child('stats/interes_post_conversacion');

  List<Map<dynamic, dynamic>> _allLogs = [];
  List<Map<dynamic, dynamic>> _filteredLogs = [];
  bool _isLoading = true;

  // --- VARIABLES DE FILTRO ---
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carga de datos y extracción de categorías únicas
  void _loadData() {
    _statsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final Map<dynamic, dynamic> statsMap = data as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> tempList = [];
      final Set<String> catSet = {};

      statsMap.forEach((key, value) {
        // Aseguramos que tenga timestamp
        if (value['timestamp'] == null) value['timestamp'] = 0;

        // Guardamos categoría para el filtro
        if (value['categoria'] != null) {
          catSet.add(value['categoria'].toString());
        }

        tempList.add(value);
      });

      // Ordenar: Más reciente primero
      tempList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      if (mounted) {
        setState(() {
          _allLogs = tempList;
          _filteredLogs = tempList; // Al inicio mostramos todo
          _categories = catSet.toList()..sort();
          _isLoading = false;
        });
      }
    });
  }

  // --- LÓGICA DE FILTRADO ---
  void _applyFilters() {
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        // 1. Filtro de Categoría
        bool passCategory = true;
        if (_selectedCategory != null) {
          passCategory = log['categoria'] == _selectedCategory;
        }

        // 2. Filtro de Fecha
        bool passDate = true;
        if (_selectedDateRange != null) {
          final logDate = DateTime.fromMillisecondsSinceEpoch(log['timestamp']);
          final start = DateUtils.dateOnly(_selectedDateRange!.start);
          final end = DateUtils.dateOnly(_selectedDateRange!.end).add(Duration(days: 1)); // Incluir el día final completo
          passDate = logDate.isAfter(start) && logDate.isBefore(end);
        }

        return passCategory && passDate;
      }).toList();
    });
  }

  // Selector de Rango de Fechas
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.teal,
            colorScheme: ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDateRange = picked;
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedDateRange = null;
      _filteredLogs = List.from(_allLogs);
    });
  }

  // Limpiador de teléfono visual
  String _cleanPhone(String? raw) {
    if (raw == null) return "Desconocido";
    String s = raw.replaceAll('@c.us', '');
    if (s.startsWith('51') && s.length == 11) return s.substring(2);
    return s;
  }

  // Formateador de Fecha y Hora
  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm a').format(date);
  }

  // --- EXPORTACIÓN A EXCEL ---
  Future<void> _exportFilteredToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Reporte'];

    // Encabezados
    sheet.appendRow([
      TextCellValue('Fecha y Hora'),
      TextCellValue('Teléfono'),
      TextCellValue('Curso Interesado'),
      TextCellValue('Categoría')
    ]);

    // Datos Filtrados
    for (var log in _filteredLogs) {
      sheet.appendRow([
        TextCellValue(_formatDateTime(log['timestamp'])),
        TextCellValue(_cleanPhone(log['numero_usuario'])),
        TextCellValue(log['nombre_curso'] ?? 'General'),
        TextCellValue(log['categoria'] ?? 'Sin categoría'),
      ]);
    }

    // Guardar y Compartir
    final directory = await getTemporaryDirectory();
    final String fileName = "Reporte_DRSEU_${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}.xlsx";
    final path = "${directory.path}/$fileName";
    final file = File(path);
    await file.writeAsBytes(excel.save()!);
    await Share.shareXFiles([XFile(path)], text: 'Reporte de Interesados DRSEU');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Listado General", style: TextStyle(fontSize: 18)),
            Text("${_filteredLogs.length} registros encontrados", style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            tooltip: "Exportar Excel Filtrado",
            onPressed: _exportFilteredToExcel,
          )
        ],
      ),
      body: Column(
        children: [
          // --- SECCIÓN DE FILTROS ---
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.teal.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    // Filtro Categoría
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200)
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: Text("Categoría"),
                            value: _selectedCategory,
                            items: _categories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13)),
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategory = val;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    // Filtro Fecha
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade200)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDateRange == null
                                    ? "Fechas"
                                    : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                                style: TextStyle(fontSize: 13, color: _selectedDateRange == null ? Colors.grey[700] : Colors.teal),
                              ),
                              Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Botón Limpiar
                    if (_selectedCategory != null || _selectedDateRange != null)
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: _clearFilters,
                      )
                  ],
                ),
              ],
            ),
          ),

          // --- LISTA DE DATOS ---
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                ? Center(child: Text("No se encontraron registros con estos filtros."))
                : ListView.builder(
              itemCount: _filteredLogs.length,
              padding: EdgeInsets.only(bottom: 80),
              itemBuilder: (context, index) {
                final log = _filteredLogs[index];
                final timestamp = log['timestamp'];

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Ícono
                        CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(Icons.person, color: Colors.teal),
                        ),
                        SizedBox(width: 15),
                        // Datos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Teléfono
                              Text(
                                _cleanPhone(log['numero_usuario']),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              // Curso y Categoría
                              Row(
                                children: [
                                  Icon(Icons.book, size: 14, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "${log['nombre_curso']}",
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                log['categoria'] ?? 'General',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                              ),
                              SizedBox(height: 4),
                              // Fecha y Hora
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.teal),
                                  SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(timestamp),
                                    style: TextStyle(fontSize: 12, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}