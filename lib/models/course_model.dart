import 'package:flutter/material.dart';

class Curso {
  String? key; // ID de Firebase
  String titulo;
  String descripcion;
  int costoUntels;
  int costoPublico;
  int costoConadis;
  String linkInscripcion;
  String modalidad; // Virtual, Presencial, Híbrido
  bool activo;
  String? brochureUrl; // Link de Drive
  String? driveFileId; // ID para borrarlo luego
  List<Grupo> grupos; // <--- AQUÍ ESTÁ LA LISTA DE GRUPOS

  Curso({
    this.key,
    required this.titulo,
    required this.descripcion,
    required this.costoUntels,
    required this.costoPublico,
    required this.costoConadis,
    required this.linkInscripcion,
    required this.modalidad,
    required this.activo,
    this.brochureUrl,
    this.driveFileId,
    required this.grupos,
  });

  // Convertir a JSON para guardar en Firebase
  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'contenido': descripcion, // Mantenemos compatibilidad con tu bot de Node
      'costo_untels': costoUntels,
      'costo_publico': costoPublico,
      'costo_conadis': costoConadis,
      'link': linkInscripcion,
      'modalidad': modalidad,
      'activo': activo,
      'brochure_url': brochureUrl,
      'drive_file_id': driveFileId,
      // Convertimos la lista de objetos Grupo a una lista de mapas
      'grupos': grupos.map((g) => g.toJson()).toList(),
      // Generamos un horario texto simple para que el bot de Node lo lea rápido
      'horario': _generarHorarioTexto(),
      'fileName': titulo.toLowerCase().replaceAll(' ', '_'),
    };
  }

  // Genera el texto resumen para el Bot de Node.js (ej: "G1: Lun-Mie 8pm / G2: Sab 9am")
  String _generarHorarioTexto() {
    if (grupos.isEmpty) return "Por definir";
    return grupos.map((g) => "${g.nombre}: ${g.dias.join('-')} ${g.horaInicio}-${g.horaFin}").join(" | ");
  }

  // Crear objeto desde Firebase
  factory Curso.fromMap(String key, Map<dynamic, dynamic> map) {
    var listaGrupos = <Grupo>[];
    if (map['grupos'] != null) {
      // Manejo seguro de la lista dinámica
      final rawList = map['grupos'] as List<dynamic>;
      listaGrupos = rawList.map((item) => Grupo.fromMap(Map<String, dynamic>.from(item))).toList();
    }

    return Curso(
      key: key,
      titulo: map['titulo'] ?? '',
      descripcion: map['contenido'] ?? '',
      costoUntels: map['costo_untels'] ?? 0,
      costoPublico: map['costo_publico'] ?? 0,
      costoConadis: map['costo_conadis'] ?? 0,
      linkInscripcion: map['link'] ?? '',
      modalidad: map['modalidad'] ?? 'Virtual',
      activo: map['activo'] ?? false,
      brochureUrl: map['brochure_url'],
      driveFileId: map['drive_file_id'],
      grupos: listaGrupos,
    );
  }
}

class Grupo {
  String nombre; // "Grupo 1", "Grupo 2"
  List<String> dias; // ["Lunes", "Miércoles"]
  String horaInicio; // "18:00"
  String horaFin; // "20:00"

  Grupo({
    required this.nombre,
    required this.dias,
    required this.horaInicio,
    required this.horaFin,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'dias': dias,
    'hora_inicio': horaInicio,
    'hora_fin': horaFin,
  };

  factory Grupo.fromMap(Map<String, dynamic> map) {
    return Grupo(
      nombre: map['nombre'] ?? '',
      dias: List<String>.from(map['dias'] ?? []),
      horaInicio: map['hora_inicio'] ?? '',
      horaFin: map['hora_fin'] ?? '',
    );
  }
}