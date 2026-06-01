class Validators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio.';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'El email es obligatorio.';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(text)) return 'Introduce un email válido.';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    return null;
  }
}
