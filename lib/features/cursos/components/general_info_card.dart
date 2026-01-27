import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/course_model.dart';

class GeneralInfoCard extends StatefulWidget {
  final GeneralInfo info;
  final bool showVariables; // <--- RECIBE EL ESTADO
  final VoidCallback onUpdate;

  const GeneralInfoCard({Key? key, required this.info, required this.showVariables, required this.onUpdate}) : super(key: key);

  @override
  _GeneralInfoCardState createState() => _GeneralInfoCardState();
}

class _GeneralInfoCardState extends State<GeneralInfoCard> {
  bool _isExpanded = false;

  final TextStyle _varStyle = TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic);
  final String _suffixHint = " (+ _MAY, _MIN, _CAP)";

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    if (widget.info.fechaInicioGeneral.isNotEmpty) {
      try { initial = DateFormat('dd/MM/yyyy').parse(widget.info.fechaInicioGeneral); } catch (_) {}
    }
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2024), lastDate: DateTime(2030), locale: const Locale('es', 'ES'));
    if (picked != null) {
      setState(() { widget.info.fechaInicioGeneral = DateFormat('dd/MM/yyyy').format(picked); });
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.settings_applications, color: Colors.teal),
            title: Text("Datos Generales y Configuración"),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- LEYENDA (Solo si showVariables es TRUE) ---
                  if (widget.showVariables)
                    Container(
                      margin: EdgeInsets.only(bottom: 15),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("🎨 Guía de Formatos Google:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange.shade900)),
                          SizedBox(height: 5),
                          _buildLegendRow("{{var}}", "Normal"),
                          _buildLegendRow("{{var_MAY}}", "MAYÚSCULAS"),
                          _buildLegendRow("{{var_CAP}}", "Capital"),
                        ],
                      ),
                    ),

                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                          labelText: "Fecha Inicio General",
                          border: OutlineInputBorder(),
                          // Helper condicional
                          helperText: widget.showVariables ? "Var: {{fec_ini_gen}}$_suffixHint" : null,
                          helperStyle: _varStyle
                      ),
                      child: Text(widget.info.fechaInicioGeneral.isEmpty ? "Seleccionar" : widget.info.fechaInicioGeneral),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildNumField("Costo UNTELS", (val) => widget.info.costoUntels = val, widget.info.costoUntels, "{{costo1}}")),
                      SizedBox(width: 10),
                      Expanded(child: _buildNumField("Costo Público", (val) => widget.info.costoPublico = val, widget.info.costoPublico, "{{costo2}}")),
                    ],
                  ),
                  SizedBox(height: 10),
                  _buildNumField("Costo Conadis", (val) => widget.info.costoConadis = val, widget.info.costoConadis, "{{costo3}}"),
                  SizedBox(height: 15),
                  TextFormField(
                    initialValue: widget.info.certPdfForms,
                    decoration: InputDecoration(
                        labelText: "Certificado PDF (Forms)",
                        border: OutlineInputBorder(),
                        helperText: widget.showVariables ? "Var: {{certificado_pf}}$_suffixHint" : null,
                        helperStyle: _varStyle
                    ),
                    maxLines: 2,
                    onChanged: (val) => widget.info.certPdfForms = val,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: widget.info.certChatbot,
                    decoration: InputDecoration(
                      labelText: "Certificado Chatbot",
                      border: OutlineInputBorder(),
                      helperText: widget.showVariables ? "Solo para el Chatbot (No va al Slide)" : null,
                    ),
                    maxLines: 2,
                    onChanged: (val) => widget.info.certChatbot = val,
                  ),

                  if (widget.showVariables) ...[
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text("Var Auto: {{modalidad}}$_suffixHint (Calculada)", style: TextStyle(fontSize: 11, color: Colors.purple.shade900)),
                    )
                  ]
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String code, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(children: [Container(width: 80, child: Text(code, style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold))), Text(desc, style: TextStyle(fontSize: 10))]),
    );
  }

  Widget _buildNumField(String label, Function(double) onChanged, double initial, String variableName) {
    return TextFormField(
      initialValue: initial == 0 ? '' : initial.toString(),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
          labelText: label,
          prefixText: "S/ ",
          border: OutlineInputBorder(),
          helperText: widget.showVariables ? "Var: $variableName$_suffixHint" : null,
          helperStyle: _varStyle
      ),
      onChanged: (val) {
        onChanged(double.tryParse(val) ?? 0.0);
        widget.onUpdate();
      },
    );
  }
}