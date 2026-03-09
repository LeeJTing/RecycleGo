// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localization.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Recycle Go';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get hello_world => 'Hello World!';
}
