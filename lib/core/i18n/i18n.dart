part of grupli_app;

Locale resolveAppLocale([Locale? deviceLocale]) {
  final languageCode = (deviceLocale?.languageCode ?? '').toLowerCase();
  if (languageCode == 'en') return const Locale('en');
  return const Locale('es');
}

bool get appIsEnglish => appLocale.languageCode.toLowerCase() == 'en';

String get appDateLocale => appIsEnglish ? 'en_US' : 'es_ES';

String get appIntlLocale => appDateLocale;

String tr(BuildContext context, {required String es, required String en}) {
  final locale = Localizations.maybeLocaleOf(context) ?? appLocale;
  return locale.languageCode.toLowerCase() == 'en' ? en : es;
}

