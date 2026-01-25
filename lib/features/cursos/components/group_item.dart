import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/course_model.dart';

class GroupItem extends StatefulWidget {
  final Grupo grupo;
  final VoidCallback onDelete; // Esta función elimina el grupo de la lista del padre
  final VoidCallback onUpdate;

  const GroupItem({Key? key, required this.grupo, required this.onDelete, required this.onUpdate}) : super(key: key);

  @override
  _GroupItemState createState() => _GroupItemState();
}

class _GroupItemState extends State<GroupItem> {

  // --- ALERTA DE CONFIRMACIÓN PARA ELIMINAR GRUPO ---
  void _confirmarEliminarGrupo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Eliminar Grupo?"),
        content: Text("Se eliminará el '${widget.grupo.nombre}'. Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete(); // Llamamos a la función real de eliminar
            },
            child: Text("Eliminar", style: TextStyle(color: Colors.white)),
          )
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
    final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2024),
        lastDate: DateTime(2030),
        locale: Locale('es', 'ES') // Asegúrate de tener configurado el locale en main.dart
    );
    if (picked != null) {
      setState(() {
        String f = DateFormat('dd/MM/yyyy').format(picked);
        if (isStart) widget.grupo.fechaInicio = f; else widget.grupo.fechaFin = f;
      });
      widget.onUpdate();
    }
  }

  Future<void> _selectTime(bool isStart) async {
    TimeOfDay initial = TimeOfDay(hour: 9, minute: 0);
    // Parseo básico de hora si existe...
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        final t = "${picked.hourOfPeriod}:${picked.minute.toString().padLeft(2,'0')} ${picked.period == DayPeriod.am ? 'am' : 'pm'}";
        if (isStart) widget.grupo.horaInicio = t; else widget.grupo.horaFin = t;
      });
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      color: Colors.grey.shade50,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.grupo.nombre,
                    decoration: InputDecoration(labelText: "Nombre Grupo", isDense: true),
                    onChanged: (val) => widget.grupo.nombre = val,
                  ),
                ),
                // Switch Chatbot
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
                // Botón Eliminar con Alerta
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 24),
                  onPressed: _confirmarEliminarGrupo, // <--- CAMBIO AQUÍ
                ),
              ],
            ),

            SizedBox(height: 8),
            // Resto de campos (Dias, Fechas, Horas)...
            Wrap(
              spacing: 4,
              children: ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"].map((diaFull) {
                return ChoiceChip(
                  label: Text(diaFull.substring(0, 3), style: TextStyle(fontSize: 11)),
                  selected: widget.grupo.dias.contains(diaFull),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) widget.grupo.dias.add(diaFull); else widget.grupo.dias.remove(diaFull);
                    });
                    widget.onUpdate();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _dateInput("Inicio", widget.grupo.fechaInicio, () => _selectDate(true))),
                SizedBox(width: 5),
                Expanded(child: _dateInput("Fin", widget.grupo.fechaFin, () => _selectDate(false))),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _timeInput("Hora Inicio", widget.grupo.horaInicio, () => _selectTime(true))),
                SizedBox(width: 5),
                Expanded(child: _timeInput("Hora Fin", widget.grupo.horaFin, () => _selectTime(false))),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Modalidad: ", style: TextStyle(fontSize: 12)),
                DropdownButton<String>(
                  value: widget.grupo.modalidad,
                  isDense: true,
                  items: ["Virtual", "Presencial"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() { widget.grupo.modalidad = v!; widget.onUpdate(); }),
                )
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