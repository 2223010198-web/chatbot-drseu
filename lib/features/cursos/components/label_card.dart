import 'package:flutter/material.dart';
import '../../../models/course_model.dart';
import 'group_item.dart';

class LabelCard extends StatefulWidget {
  final Etiqueta etiqueta;
  final int labelIndex;
  final bool showVariables; // <--- RECIBE EL ESTADO
  final Function(Etiqueta) onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const LabelCard({
    Key? key,
    required this.etiqueta,
    required this.labelIndex,
    required this.showVariables,
    required this.onDuplicate,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _LabelCardState createState() => _LabelCardState();
}

class _LabelCardState extends State<LabelCard> {
  bool _isExpanded = true;

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Opciones: ${widget.etiqueta.nombre}"),
        content: Text("¿Qué deseas hacer con esta etiqueta?"),
        actions: [
          TextButton.icon(icon: Icon(Icons.copy), label: Text("Duplicar"), onPressed: () { Navigator.pop(ctx); widget.onDuplicate(widget.etiqueta); }),
          TextButton.icon(icon: Icon(Icons.delete, color: Colors.red), label: Text("Eliminar"), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () { Navigator.pop(ctx); _confirmDelete(); }),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("⚠️ Eliminar Etiqueta"),
        content: Text("Se eliminará '${widget.etiqueta.nombre}' y sus grupos."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancelar")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(ctx); widget.onDelete(); }, child: Text("Eliminar", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String varEtiqueta = "{{${widget.labelIndex}etiqueta}}";

    return GestureDetector(
      onLongPress: _showOptionsDialog,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200)),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
              child: Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: Colors.blue, child: Text("${widget.labelIndex}", style: TextStyle(fontSize: 12, color: Colors.white))),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.etiqueta.nombre,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Nombre Etiqueta",
                          // Helper condicional
                          helperText: widget.showVariables ? "Var: $varEtiqueta (+ _MAY, _MIN, _CAP)" : null,
                          helperStyle: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)
                      ),
                      onChanged: (val) => widget.etiqueta.nombre = val,
                    ),
                  ),
                  IconButton(icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more), onPressed: () => setState(() => _isExpanded = !_isExpanded))
                ],
              ),
            ),

            if (_isExpanded)
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    ...widget.etiqueta.grupos.asMap().entries.map((entry) {
                      return GroupItem(
                        grupo: entry.value,
                        labelIndex: widget.labelIndex,
                        groupIndex: entry.key + 1,
                        showVariables: widget.showVariables, // <--- PASAR ESTADO
                        onDelete: () => setState(() => widget.etiqueta.grupos.removeAt(entry.key)),
                        onUpdate: widget.onUpdate,
                      );
                    }).toList(),

                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add, size: 16),
                      label: Text("Agregar Grupo"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100, foregroundColor: Colors.blue.shade900, elevation: 0),
                      onPressed: () {
                        setState(() {
                          widget.etiqueta.grupos.add(Grupo(nombre: 'Grupo ${widget.etiqueta.grupos.length + 1}', dias: [], horaInicio: '', horaFin: '', fechaInicio: '', fechaFin: ''));
                        });
                      },
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}