import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'pl': {
      // OGÓLNE
      'app_title': 'Work Study Timer',
      'language': 'Język',
      'range': 'Zakres',
      'today': 'Dzisiaj',
      'this_week': 'Ten tydzień',
      'this_month': 'Ten miesiąc',
      'all': 'Wszystko',
      'search_hint': 'Szukaj po opisie (np. Margarita, Finca)',

      // TYPY
      'learning': 'Nauka',
      'paid_work': 'Praca płatna',
      'unpaid_work': 'Praca niepłatna',
      'sport': 'Sport',
      'free_time': 'Czas wolny',
      'type': 'Typ',

      // SZYBKI TIMER
      'quick_timer': 'Szybki timer',
      'description_hint': 'Opis (opcjonalnie)',
      'start_btn': 'Start',
      'stop_btn': 'Stop',
      'no_active': 'Brak aktywnej sesji.',
      'add_custom_type_title': 'Dodaj nowy typ aktywności',
      'custom_type_hint': 'Nazwa nowej aktywności (np. Gitara)',
      'manage_custom_types': 'Zarządzaj typami',
      'no_custom_types': 'Brak własnych typów.',
      'close': 'Zamknij',
      'close_btn': 'Zamknij',

      // START/STOP SECTION
      'start_stop_section': 'Start / Stop',
      'running_since': 'Trwa od',

      // PODSUMOWANIA
      'summary_title': 'Podsumowanie',
      'summary_total': 'Suma',
      'no_data': 'Brak danych',
      'date_label': 'Data: ',
      'choose_date': 'Wybierz datę',

      // MANUALNE DODAWANIE
      'add_manual': 'Dodaj sesję manualnie',
      'description_label': 'Opis',
      'start_time_label': 'Start (HH:MM)',
      'end_time_label': 'Koniec (HH:MM)',
      'start_time_hint': 'np. 08:30',
      'end_time_hint': 'np. 10:15',
      'add_session_btn': 'Dodaj sesję',
      'no_description': 'Brak opisu',
      'error_time_format': 'Sprawdź godziny (format HH:MM, koniec po starcie).',
      'fill_all_fields': 'Wypełnij wszystkie pola',
      'invalid_time_format': 'Nieprawidłowy format czasu (użyj HH:MM)',
      'session_added': 'Sesja dodana',

      // HISTORIA
      'history_title': 'Historia sesji',
      'history_empty': 'Brak sesji w wybranym zakresie.',
      'mode_manual': 'Manualnie',
      'mode_auto': 'Start/Stop',
      'edit': 'Edytuj',
      'delete': 'Usuń',
      'export': 'Eksportuj',
      'import': 'Importuj',
      'edit_session': 'Edytuj sesję',
      'edit_session_title': 'Edytuj sesję',
      'cancel': 'Anuluj',
      'cancel_btn': 'Anuluj',
      'save': 'Zapisz',
      'save_btn': 'Zapisz',
      'add_btn': 'Dodaj',
      'error_edit_time': 'Błędne godziny (format HH:MM, koniec po starcie).',
      'session_running_from': 'Trwa sesja od: ',
      'field_type': 'Typ: ',
      'field_mode': 'Tryb: ',
      'session_deleted': 'Sesja usunięta',
      'session_updated': 'Sesja zaktualizowana',

      // TYPY WŁASNE
      'type_name_label': 'Nazwa typu',
      'type_exists': 'Ten typ już istnieje',
      'type_added': 'Typ dodany',
      'type_deleted': 'Typ usunięty',

      // BACKUP/IMPORT/EXPORT
      'export_ok': 'Eksport OK: ',
      'export_error': 'Błąd eksportu: ',
      'export_success': 'Wyeksportowano do',
      'backup_missing': 'Brak pliku backup!',
      'import_ok': 'Zaimportowano sesji: ',
      'import_error': 'Błąd importu: ',
      'import_success': 'Import zakończony sukcesem',
      'no_files_to_import': 'Brak plików do importu',
      'choose_file_to_import': 'Wybierz plik do importu',

      // TŁO I USTAWIENIA
      'change_background': 'Zmień tło',
      'remove_background': 'Usuń tło',
      'icon_color_picker': 'Kolor ikon',
      'slide_to_change_color': 'Przesuń suwak aby zmienić kolor',

      // NOWE - CELE 🎯
      'goals_title': 'Moje Cele',
      'add_goal': 'Dodaj cel',
      'no_goals': 'Brak celów. Dodaj pierwszy cel!',
      'goal_name': 'Nazwa celu',
      'goal_name_hint': 'np. Nauka angielskiego',
      'goal_hours': 'Cel w godzinach',
      'goal_hours_hint': 'np. 10',
      'goal_period': 'Okres',
      'goal_week': 'Tydzień',
      'goal_month': 'Miesiąc',
      'goal_type': 'Typ',
      'goal_all_types': 'Wszystkie',
      'goal_added': 'Cel dodany!',
      'goal_deleted': 'Cel usunięty',
      'goal_completed': 'Cel osiągnięty! Świetna robota!',
      'goal_remaining': 'Jeszcze {hours}h do celu',
      'goal_progress': '{current}h / {target}h',
      'goal_invalid_hours': 'Podaj prawidłową liczbę godzin',
    },

    'es': {
      // OGÓLNE
      'app_title': 'Work Study Timer',
      'language': 'Idioma',
      'range': 'Rango',
      'today': 'Hoy',
      'this_week': 'Esta semana',
      'this_month': 'Este mes',
      'all': 'Todo',
      'search_hint': 'Buscar por descripción (p. ej. Margarita, Finca)',

      // TYPY
      'learning': 'Aprendizaje',
      'paid_work': 'Trabajo pagado',
      'unpaid_work': 'Trabajo no pagado',
      'sport': 'Deporte',
      'free_time': 'Tiempo libre',
      'type': 'Tipo',

      // SZYBKI TIMER
      'quick_timer': 'Temporizador rápido',
      'description_hint': 'Descripción (opcional)',
      'start_btn': 'Iniciar',
      'stop_btn': 'Detener',
      'no_active': 'Sin sesión activa.',
      'add_custom_type_title': 'Añadir nuevo tipo de actividad',
      'custom_type_hint': 'Nombre de la nueva actividad (p. ej. Guitarra)',
      'manage_custom_types': 'Gestionar tipos',
      'no_custom_types': 'Sin tipos personalizados.',
      'close': 'Cerrar',
      'close_btn': 'Cerrar',

      // START/STOP SECTION
      'start_stop_section': 'Iniciar / Detener',
      'running_since': 'Ejecutando desde',

      // PODSUMOWANIA
      'summary_title': 'Resumen',
      'summary_total': 'Total',
      'no_data': 'Sin datos',
      'date_label': 'Fecha: ',
      'choose_date': 'Elegir fecha',

      // MANUALNE DODAWANIE
      'add_manual': 'Añadir sesión manualmente',
      'description_label': 'Descripción',
      'start_time_label': 'Inicio (HH:MM)',
      'end_time_label': 'Fin (HH:MM)',
      'start_time_hint': 'ej. 08:30',
      'end_time_hint': 'ej. 10:15',
      'add_session_btn': 'Añadir sesión',
      'no_description': 'Sin descripción',
      'error_time_format': 'Revisa las horas (formato HH:MM, fin después del inicio).',
      'fill_all_fields': 'Completa todos los campos',
      'invalid_time_format': 'Formato de tiempo inválido (usa HH:MM)',
      'session_added': 'Sesión añadida',

      // HISTORIA
      'history_title': 'Historial de sesiones',
      'history_empty': 'No hay sesiones en el rango seleccionado.',
      'mode_manual': 'Manual',
      'mode_auto': 'Inicio/Detener',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'export': 'Exportar',
      'import': 'Importar',
      'edit_session': 'Editar sesión',
      'edit_session_title': 'Editar sesión',
      'cancel': 'Cancelar',
      'cancel_btn': 'Cancelar',
      'save': 'Guardar',
      'save_btn': 'Guardar',
      'add_btn': 'Añadir',
      'error_edit_time': 'Horas incorrectas (formato HH:MM, fin después del inicio).',
      'session_running_from': 'Sesión desde: ',
      'field_type': 'Tipo: ',
      'field_mode': 'Modo: ',
      'session_deleted': 'Sesión eliminada',
      'session_updated': 'Sesión actualizada',

      // TYPY WŁASNE
      'type_name_label': 'Nombre del tipo',
      'type_exists': 'Este tipo ya existe',
      'type_added': 'Tipo añadido',
      'type_deleted': 'Tipo eliminado',

      // BACKUP/IMPORT/EXPORT
      'export_ok': 'Exportado OK: ',
      'export_error': 'Error de exportación: ',
      'export_success': 'Exportado a',
      'backup_missing': 'No hay archivo de copia de seguridad.',
      'import_ok': 'Sesiones importadas: ',
      'import_error': 'Error de importación: ',
      'import_success': 'Importación exitosa',
      'no_files_to_import': 'No hay archivos para importar',
      'choose_file_to_import': 'Elige archivo para importar',

      // TŁO I USTAWIENIA
      'change_background': 'Cambiar fondo',
      'remove_background': 'Eliminar fondo',
      'icon_color_picker': 'Color de iconos',
      'slide_to_change_color': 'Desliza para cambiar el color',

      // NOWE - CELE 🎯 (HISZPAŃSKI)
      'goals_title': 'Mis Objetivos',
      'add_goal': 'Añadir objetivo',
      'no_goals': '¡Sin objetivos. Añade el primero!',
      'goal_name': 'Nombre del objetivo',
      'goal_name_hint': 'ej. Aprender inglés',
      'goal_hours': 'Objetivo en horas',
      'goal_hours_hint': 'ej. 10',
      'goal_period': 'Período',
      'goal_week': 'Semana',
      'goal_month': 'Mes',
      'goal_type': 'Tipo',
      'goal_all_types': 'Todos',
      'goal_added': '¡Objetivo añadido!',
      'goal_deleted': 'Objetivo eliminado',
      'goal_completed': '¡Objetivo alcanzado! ¡Excelente trabajo!',
      'goal_remaining': 'Faltan {hours}h para el objetivo',
      'goal_progress': '{current}h / {target}h',
      'goal_invalid_hours': 'Ingresa un número válido de horas',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['pl']![key] ??
        key;
  }
}

// Delegate – bez zmian dla Ciebie, po prostu skopiuj
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['pl', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
