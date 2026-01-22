class Curso {
  String? key;
  String titulo;
  String descripcion;
  String categoria; // NUEVO: "Extension", "Taller", "Charla"
  int costoUntels;
  int costoPublico;
  int costoConadis;
  String linkInscripcion;
  String modalidad;
  bool activo;
  String? brochureUrl;
  String? driveFileId;
  List<Grupo> grupos;
  int orden;

  Curso({
    this.key,
    required this.titulo,
    required this.descripcion,
    required this.categoria, // Requerido
    required this.costoUntels,
    required this.costoPublico,
    required this.costoConadis,
    required this.linkInscripcion,
    required this.modalidad,
    required this.activo,
    this.brochureUrl,
    this.driveFileId,
    required this.grupos,
    this.orden = 9999,
  });

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'contenido': descripcion,
      'categoria': categoria, // Guardamos la categoría
      'costo_untels': costoUntels,
      'costo_publico': costoPublico,
      'costo_conadis': costoConadis,
      'link': linkInscripcion,
      'modalidad': modalidad,
      'activo': activo,
      'brochure_url': brochureUrl,
      'drive_file_id': driveFileId,
      'grupos': grupos.map((g) => g.toJson()).toList(),
      // Horario texto inteligente para el bot
      'horario': _generarHorarioTexto(),
      'fileName': titulo.toLowerCase().replaceAll(' ', '_'),
      'orden': orden,
    };
  }

  String _generarHorarioTexto() {
    if (grupos.isEmpty) return "Por definir";
    // Ahora incluye fechas en el resumen para el bot
    return grupos.map((g) => "${g.nombre} (${g.fechaInicio} al ${g.fechaFin}): ${g.dias.join('-')} ${g.horaInicio}-${g.horaFin}").join(" | ");
  }

  factory Curso.fromMap(String key, Map<dynamic, dynamic> map) {
    var listaGrupos = <Grupo>[];
    if (map['grupos'] != null) {
      final rawList = map['grupos'] as List<dynamic>;
      listaGrupos = rawList.map((item) => Grupo.fromMap(Map<String, dynamic>.from(item))).toList();
    }

    return Curso(
      key: key,
      titulo: map['titulo'] ?? '',
      descripcion: map['contenido'] ?? '',
      categoria: map['categoria'] ?? 'Cursos de Extensión', // Default
      costoUntels: map['costo_untels'] ?? 0,
      costoPublico: map['costo_publico'] ?? 0,
      costoConadis: map['costo_conadis'] ?? 0,
      linkInscripcion: map['link'] ?? '',
      modalidad: map['modalidad'] ?? 'Virtual',
      activo: map['activo'] ?? false,
      brochureUrl: map['brochure_url'],
      driveFileId: map['drive_file_id'],
      grupos: listaGrupos,
      orden: map['orden'] ?? 9999,
    );
  }
}

class Grupo {
  String nombre;
  List<String> dias;
  String horaInicio;
  String horaFin;
  String fechaInicio; // NUEVO
  String fechaFin;    // NUEVO
  String modalidad;

  Grupo({
    required this.nombre,
    required this.dias,
    required this.horaInicio,
    required this.horaFin,
    required this.fechaInicio,
    required this.fechaFin,
    this.modalidad = 'Virtual',
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'dias': dias,
    'hora_inicio': horaInicio,
    'hora_fin': horaFin,
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    'modalidad': modalidad,
  };

  factory Grupo.fromMap(Map<String, dynamic> map) {
    return Grupo(
      nombre: map['nombre'] ?? '',
      dias: List<String>.from(map['dias'] ?? []),
      horaInicio: map['hora_inicio'] ?? '',
      horaFin: map['hora_fin'] ?? '',
      fechaInicio: map['fecha_inicio'] ?? '',
      fechaFin: map['fecha_fin'] ?? '',
      modalidad: map['modalidad'] ?? 'Virtual',
    );
  }
}