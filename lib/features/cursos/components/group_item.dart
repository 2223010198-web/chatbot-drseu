import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/course_model.dart';

class GroupItem extends StatefulWidget {
  final Grupo grupo;
  final int labelIndex;
  final int groupIndex;
  final bool showVariables; // <--- RECIBE EL ESTADO
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const GroupItem({
    Key? key,
    required this.grupo,
    required this.labelIndex,
    required this.groupIndex,
    required this.showVariables,
    required this.onDelete,
    required this.onUpdate
  }) : super(key: key);

  @override
  _GroupItemState createState() => _GroupItemState();
}

class _GroupItemState extends State<GroupItem> {

  final TextStyle _varStyle = TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic);
  final String _suffixHint = " (+ _MAY, _MIN, _CAP)";

  void _confirmarEliminarGrupo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Eliminar Grupo?"),
        content: Text("Se eliminará el '${widget.grupo.nombre}'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancelar")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(ctx); widget.onDelete(); }, child: Text("Eliminar", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    DateTime initial = DateTime.now();
    String current = isStart ? widget.grupo.fechaInicio : widget.grupo.fechaFin;
    if (current.isNotEmpty) {
      try { initial = DateFormat('dd/MM/yyyy').parse(current); } catch (_) {}
    }
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2024), lastDate: DateTime(2030), locale: Locale('es', 'ES'));
    if (picked != null) {
      setState(() { String f = DateFormat('dd/MM/yyyy').format(picked); if (isStart) widget.grupo.fechaInicio = f; else widget.grupo.fechaFin = f; });
      widget.onUpdate();
    }
  }

  Future<void> _selectTime(bool isStart) async {
    TimeOfDay initial = TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        final t = "${picked.hourOfPeriod}:${picked.minute.toString().padLeft(2,'0')} ${picked.period == DayPeriod.am ? 'a.m.' : 'p.m.'}";
        if (isStart) widget.grupo.horaInicio = t; else widget.grupo.horaFin = t;
      });
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String prefix = "{{${widget.labelIndex}";
    final String suffix = "${widget.groupIndex}}}";

    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      color: Colors.grey.shade50,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.grupo.nombre,
                    decoration: InputDecoration(
                        labelText: "Nombre Grupo",
                        isDense: true,
                        // Helper condicional
                        helperText: widget.showVariables ? "Var: ${prefix}grupo$suffix$_suffixHint" : null,
                        helperStyle: _varStyle
                    ),
                    onChanged: (val) => widget.grupo.nombre = val,
                  ),
                ),
                Column(
                  children: [
                    Text("Chatbot", style: TextStyle(fontSize: 10)),
                    Switch(
                      value: widget.grupo.visibleChatbot,
                      activeColor: Colors.teal,
                      onChanged: (v) => setState(() { widget.grupo.visibleChatbot = v; widget.onUpdate(); }),
                    ),
                  ],
                ),
                IconButton(icon: Icon(Icons.delete, color: Colors.red, size: 24), onPressed: _confirmarEliminarGrupo),
              ],
            ),

            SizedBox(height: 10),

            Text("Días de clase:", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            Wrap(
              spacing: 4,
              children: ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"].map((diaFull) {
                return ChoiceChip(
                  label: Text(diaFull.substring(0, 3), style: TextStyle(fontSize: 11)),
                  selected: widget.grupo.dias.contains(diaFull),
                  onSelected: (selected) {
                    setState(() { if (selected) widget.grupo.dias.add(diaFull); else widget.grupo.dias.remove(diaFull); });
                    widget.onUpdate();
                  },
                );
              }).toList(),
            ),

            if (widget.showVariables)
              Padding(padding: const EdgeInsets.only(bottom: 5), child: Text("Var: ${prefix}dia_g$suffix$_suffixHint", style: _varStyle)),

            TextFormField(
              initialValue: widget.grupo.duracion,
              decoration: InputDecoration(
                  labelText: "Duración (Ej: 4 semanas / 20 horas)",
                  isDense: true,
                  border: OutlineInputBorder(),
                  // Lógica de variable: {{1duracion_g1}}
                  helperText: widget.showVariables ? "Var: ${prefix}duracion_g$suffix$_suffixHint" : null,
                  helperStyle: _varStyle
              ),
              onChanged: (val) => widget.grupo.duracion = val,
            ),
            SizedBox(height: 15), // Espacio

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _dateInput("Inicio", widget.grupo.fechaInicio, () => _selectDate(true))),
                SizedBox(width: 5),
                Expanded(child: _dateInput("Fin", widget.grupo.fechaFin, () => _selectDate(false))),
              ],
            ),
            if (widget.showVariables)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text("Var Inicio: ${prefix}fec_ini_g$suffix$_suffixHint", style: _varStyle)),

            SizedBox(height: 15),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _timeInput("Hora Inicio", widget.grupo.horaInicio, () => _selectTime(true))),
                SizedBox(width: 5),
                Expanded(child: _timeInput("Hora Fin", widget.grupo.horaFin, () => _selectTime(false))),
              ],
            ),
            if (widget.showVariables)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text("Var Hora: ${prefix}hora_g$suffix$_suffixHint", style: _varStyle)),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Modalidad: ", style: TextStyle(fontSize: 12)),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: widget.grupo.modalidad,
                      isDense: true,
                      items: ["Virtual", "Presencial"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setState(() { widget.grupo.modalidad = v!; widget.onUpdate(); }),
                    )
                  ],
                ),
                if (widget.showVariables)
                  Text("Var Global: {{modalidad}}$_suffixHint", style: _varStyle),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _dateInput(String label, String value, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: InputDecorator(decoration: InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder()), child: Text(value.isEmpty ? "-" : value, style: TextStyle(fontSize: 12))));
  }

  Widget _timeInput(String label, String value, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: InputDecorator(decoration: InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder()), child: Text(value.isEmpty ? "--:--" : value, style: TextStyle(fontSize: 12))));
  }
}