import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/course_model.dart';

class GeneralInfoCard extends StatefulWidget {
  final GeneralInfo info;
  final VoidCallback onUpdate; // Para notificar cambios al padre

  const GeneralInfoCard({Key? key, required this.info, required this.onUpdate}) : super(key: key);

  @override
  _GeneralInfoCardState createState() => _GeneralInfoCardState();
}

class _GeneralInfoCardState extends State<GeneralInfoCard> {
  bool _isExpanded = false;

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    if (widget.info.fechaInicioGeneral.isNotEmpty) {
      try { initial = DateFormat('dd/MM/yyyy').parse(widget.info.fechaInicioGeneral); } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        widget.info.fechaInicioGeneral = DateFormat('dd/MM/yyyy').format(picked);
      });
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
            title: Text("Datos Generales (Costos, Certificados)"),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: "Fecha Inicio General", border: OutlineInputBorder()),
                      child: Text(widget.info.fechaInicioGeneral.isEmpty ? "Seleccionar" : widget.info.fechaInicioGeneral),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildNumField("Costo UNTELS", (val) => widget.info.costoUntels = val, widget.info.costoUntels)),
                      SizedBox(width: 10),
                      Expanded(child: _buildNumField("Costo Público", (val) => widget.info.costoPublico = val, widget.info.costoPublico)),
                    ],
                  ),
                  SizedBox(height: 10),
                  _buildNumField("Costo Conadis", (val) => widget.info.costoConadis = val, widget.info.costoConadis),
                  SizedBox(height: 15),
                  TextFormField(
                    initialValue: widget.info.certPdfForms,
                    decoration: InputDecoration(labelText: "Certificado PDF (Forms)", border: OutlineInputBorder()),
                    maxLines: 2,
                    onChanged: (val) => widget.info.certPdfForms = val,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: widget.info.certChatbot,
                    decoration: InputDecoration(labelText: "Certificado Chatbot", border: OutlineInputBorder()),
                    maxLines: 2,
                    onChanged: (val) => widget.info.certChatbot = val,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNumField(String label, Function(double) onChanged, double initial) {
    return TextFormField(
      initialValue: initial == 0 ? '' : initial.toString(),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, prefixText: "S/ ", border: OutlineInputBorder()),
      onChanged: (val) {
        onChanged(double.tryParse(val) ?? 0.0);
        widget.onUpdate();
      },
    );
  }
}