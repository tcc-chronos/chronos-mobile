class Validators {
  static String? ip(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe o IP do servidor';
    return null;
  }

  static String? lastN(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe o intervalo de coleta';
    final n = int.tryParse(v);
    if (n == null) return 'Valor inválido';
    if (n < 1 || n > 100) return 'O intervalo de coleta deve ser entre 1 e 100';
    return null;
  }

  static String? isoOrEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = DateTime.tryParse(v);
    if (ok == null) return 'Data/hora ISO 8601 inválida';
    return null;
  }

  static String? bothIsoRequired(String? from, String? to) {
    if ((from?.isEmpty ?? true) ^ (to?.isEmpty ?? true)) {
      return 'Preencha as duas datas (início e fim)';
    }
    return null;
  }
}
