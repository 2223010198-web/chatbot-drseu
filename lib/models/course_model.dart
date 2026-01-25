import 'package:intl/intl.dart';

class Curso {
  String? key;
  String titulo;
  String descripcion;
  String categoria;
  String linkInscripcion;
  bool activo;
  String? brochureUrl;
  String? driveFileId;
  Map<String, String>? idsGoogle;
  int orden;

  // Nuevas Estructuras
  GeneralInfo generalInfo;
  List<Etiqueta> etiquetas; // Reemplaza a la lista plana de grupos

  Curso({
    this.key,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.linkInscripcion,
    required this.activo,
    this.brochureUrl,
    this.driveFileId,
    this.idsGoogle,
    this.orden = 9999,
    required this.generalInfo,
    required this.etiquetas,
  });

  // Lógica para calcular la modalidad global
  String get modalidadCalculada {
    bool hasVirtual = false;
    bool hasPresencial = false;

    for (var et in etiquetas) {
      for (var gr in et.grupos) {
        if (gr.modalidad == 'Virtual') hasVirtual = true;
        if (gr.modalidad == 'Presencial') hasPresencial = true;
      }
    }

    if (hasVirtual && hasPresencial) return "presencial y virtual";
    if (hasPresencial) return "presencial";
    return "virtual"; // Default
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'contenido': descripcion,
      'categoria': categoria,
      'link': linkInscripcion,
      'activo': activo,
      'brochure_url': brochureUrl,
      'drive_file_id': driveFileId,
      'ids_google': idsGoogle,
      'orden': orden,
      'general_info': generalInfo.toJson(),
      'etiquetas': etiquetas.map((e) => e.toJson()).toList(),
      // Guardamos la modalidad calculada para facilitar al script
      'modalidad_calculada': modalidadCalculada,
      'fileName': titulo.toLowerCase().replaceAll(' ', '_'),
    };
  }

  factory Curso.fromMap(String key, Map<dynamic, dynamic> map) {
    // Mapeo de Etiquetas y Grupos
    var listaEtiquetas = <Etiqueta>[];
    if (map['etiquetas'] != null) {
      final rawList = map['etiquetas'] as List<dynamic>;
      listaEtiquetas = rawList.map((e) => Etiqueta.fromMap(Map<String, dynamic>.from(e))).toList();
    } else if (map['grupos'] != null) {
      // Migración temporal: si existen grupos antiguos sin etiqueta, creamos una etiqueta "General"
      final rawGrupos = map['grupos'] as List<dynamic>;
      var gruposAntiguos = rawGrupos.map((g) => Grupo.fromMap(Map<String, dynamic>.from(g))).toList();
      listaEtiquetas.add(Etiqueta(nombre: "General", grupos: gruposAntiguos));
    }

    return Curso(
      key: key,
      titulo: map['titulo'] ?? '',
      descripcion: map['contenido'] ?? '',
      categoria: map['categoria'] ?? 'Cursos de Extensión',
      linkInscripcion: map['link'] ?? '',
      activo: map['activo'] ?? false,
      brochureUrl: map['brochure_url'],
      driveFileId: map['drive_file_id'],
      idsGoogle: map['ids_google'] != null ? Map<String, String>.from(map['ids_google']) : null,
      orden: map['orden'] ?? 9999,
      generalInfo: map['general_info'] != null
          ? GeneralInfo.fromMap(Map<String, dynamic>.from(map['general_info']))
          : GeneralInfo(), // Valores por defecto
      etiquetas: listaEtiquetas,
    );
  }
}

class GeneralInfo {
  String fechaInicioGeneral; // Guardar como string fecha ISO o cruda
  double costoUntels;
  double costoPublico;
  double costoConadis;
  String certPdfForms;
  String certChatbot;

  GeneralInfo({
    this.fechaInicioGeneral = '',
    this.costoUntels = 0.0,
    this.costoPublico = 0.0,
    this.costoConadis = 0.0,
    this.certPdfForms = '',
    this.certChatbot = '',
  });

  // Formato para Google Slides "17 de enero"
  String get fechaFormateada {
    if (fechaInicioGeneral.isEmpty) return "";
    try {
      DateTime dt = DateFormat('dd/MM/yyyy').parse(fechaInicioGeneral);
      return DateFormat("d 'de' MMMM", 'es_ES').format(dt);
    } catch (e) {
      return fechaInicioGeneral;
    }
  }

  Map<String, dynamic> toJson() => {
    'fecha_inicio_gen': fechaInicioGeneral,
    'costo_untels': costoUntels,
    'costo_publico': costoPublico,
    'costo_conadis': costoConadis,
    'cert_pdf_forms': certPdfForms,
    'cert_chatbot': certChatbot,
    // Variables pre-formateadas para el script
    'var_fec_ini_gen': fechaFormateada,
    'var_costo1': "S/${costoUntels.toStringAsFixed(2)}",
    'var_costo2': "S/${costoPublico.toStringAsFixed(2)}",
    'var_costo3': "S/${costoConadis.toStringAsFixed(2)}",
  };

  factory GeneralInfo.fromMap(Map<String, dynamic> map) {
    return GeneralInfo(
      fechaInicioGeneral: map['fecha_inicio_gen'] ?? '',
      costoUntels: (map['costo_untels'] ?? 0).toDouble(),
      costoPublico: (map['costo_publico'] ?? 0).toDouble(),
      costoConadis: (map['costo_conadis'] ?? 0).toDouble(),
      certPdfForms: map['cert_pdf_forms'] ?? '',
      certChatbot: map['cert_chatbot'] ?? '',
    );
  }
}

class Etiqueta {
  String nombre;
  List<Grupo> grupos;

  Etiqueta({required this.nombre, required this.grupos});

  Etiqueta clone() {
    return Etiqueta(
      nombre: "$nombre (Copia)",
      grupos: grupos.map((g) => g.clone()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'grupos': grupos.map((g) => g.toJson()).toList(),
  };

  factory Etiqueta.fromMap(Map<String, dynamic> map) {
    var list = <Grupo>[];
    if (map['grupos'] != null) {
      list = (map['grupos'] as List).map((e) => Grupo.fromMap(Map<String, dynamic>.from(e))).toList();
    }
    return Etiqueta(
      nombre: map['nombre'] ?? '',
      grupos: list,
    );
  }
}

class Grupo {
  String nombre;
  List<String> dias;
  String horaInicio;
  String horaFin;
  String fechaInicio;
  String fechaFin;
  String modalidad;
  bool visibleChatbot;

  Grupo({
    required this.nombre,
    required this.dias,
    required this.horaInicio,
    required this.horaFin,
    required this.fechaInicio,
    required this.fechaFin,
    this.modalidad = 'Virtual',
    this.visibleChatbot = true,
  });

  Grupo clone() {
    return Grupo(
      nombre: nombre,
      dias: List.from(dias),
      horaInicio: horaInicio,
      horaFin: horaFin,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      modalidad: modalidad,
      visibleChatbot: visibleChatbot,
    );
  }

  // Formato: "martes y jueves"
  String get diasFormateados {
    if (dias.isEmpty) return "";
    if (dias.length == 1) return dias.first.toLowerCase();
    String ultimo = dias.last.toLowerCase();
    String resto = dias.sublist(0, dias.length - 1).map((e) => e.toLowerCase()).join(", ");
    return "$resto y $ultimo";
  }

  // Formato: "8:00 am – 1:00 pm"
  String get horarioFormateado => "$horaInicio – $horaFin";

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'dias': dias,
    'hora_inicio': horaInicio,
    'hora_fin': horaFin,
    'fecha_inicio': fechaInicio,
    'fecha_fin': fechaFin,
    'modalidad': modalidad,
    'visible_chatbot': visibleChatbot,
    // Variables pre-formateadas
    'var_dias': diasFormateados,
    'var_horario': horarioFormateado,
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
      visibleChatbot: map['visible_chatbot'] ?? true,
    );
  }
}