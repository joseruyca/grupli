class AppFailure implements Exception {
  final String message;
  final Object? cause;
  const AppFailure(this.message, [this.cause]);

  @override
  String toString() => message;
}

String humanError(Object error) {
  final raw = error.toString();

  if (raw.contains('over_email_send_rate_limit')) {
    return 'Supabase ha limitado temporalmente el envío de emails. Espera unos segundos y vuelve a intentarlo.';
  }
  if (raw.contains('Invalid login credentials')) return 'Email o contraseña incorrectos.';
  if (raw.contains('Email not confirmed')) return 'Falta confirmar el email antes de entrar.';
  if (raw.contains('User already registered') || raw.contains('already registered')) {
    return 'Ya existe una cuenta con ese email. Prueba a iniciar sesión.';
  }
  if (raw.contains('Password should be at least') || raw.contains('weak_password')) {
    return 'La contraseña es demasiado corta o débil.';
  }
  if (raw.contains('Código de invitación no válido')) return 'Ese código de invitación no existe o ya no sirve.';
  if (raw.contains('No se puede expulsar ni degradar al owner')) {
    return 'No se puede expulsar ni degradar al propietario del grupo.';
  }
  if (raw.contains('Solo admin u owner')) return 'Solo un admin o el propietario puede hacer esta acción.';
  if (raw.contains('JWT') || raw.contains('refresh_token_not_found')) {
    return 'La sesión ha caducado. Vuelve a iniciar sesión.';
  }
  if (raw.toLowerCase().contains('network') || raw.toLowerCase().contains('socket')) {
    return 'No se pudo conectar. Revisa internet.';
  }
  if (raw.contains('Supabase no está configurado')) return raw;

  return raw
      .replaceAll('AuthApiException(message:', '')
      .replaceAll('PostgrestException(message:', '')
      .replaceAll('Exception:', '')
      .replaceAll(')', '')
      .trim();
}
