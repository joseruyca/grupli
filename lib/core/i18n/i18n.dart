part of 'package:grupli/main.dart';

const String _appLocaleOverrideKey = 'app_locale_override';
final ValueNotifier<Locale?> appLocaleOverride = ValueNotifier<Locale?>(null);

Locale resolveAppLocale([Locale? deviceLocale]) {
  final languageCode = (deviceLocale?.languageCode ?? '').toLowerCase();
  if (languageCode == 'en') return const Locale('en');
  return const Locale('es');
}

bool get appIsEnglish => appLocale.languageCode.toLowerCase() == 'en';

String get appDateLocale => appIsEnglish ? 'en_US' : 'es_ES';

String get appIntlLocale => appDateLocale;

Locale resolveActiveAppLocale([Locale? deviceLocale]) {
  return resolveAppLocale(appLocaleOverride.value ?? deviceLocale);
}

Future<void> loadStoredAppLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_appLocaleOverrideKey);
  switch (raw) {
    case 'en':
      appLocaleOverride.value = const Locale('en');
      return;
    case 'es':
      appLocaleOverride.value = const Locale('es');
      return;
    default:
      appLocaleOverride.value = null;
  }
}

Future<void> saveStoredAppLocale(Locale? locale) async {
  final prefs = await SharedPreferences.getInstance();
  if (locale == null) {
    await prefs.remove(_appLocaleOverrideKey);
  } else {
    await prefs.setString(_appLocaleOverrideKey, locale.languageCode.toLowerCase());
  }
  appLocaleOverride.value = locale == null ? null : resolveAppLocale(locale);
}

String tr(BuildContext context, {required String es, required String en}) {
  final locale = Localizations.maybeLocaleOf(context) ?? appLocale;
  return locale.languageCode.toLowerCase() == 'en' ? en : es;
}
