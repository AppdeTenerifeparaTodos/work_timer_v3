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

      // INSTRUKCJA OBSŁUGI
      'instructions_title': 'Instrukcja obsługi',
      'instructions_content':
      'Work Study Timer pomaga śledzić czas nauki i pracy.\n\n'
          '1. Start timera\n'
          '• Na ekranie głównym kliknij przycisk START, aby rozpocząć sesję.\n'
          '• Kliknij STOP, aby zakończyć – sesja zapisze się w historii.\n\n'
          '2. Sesje ręczne\n'
          '• Użyj przycisku dodawania sesji, aby wpisać czas ręcznie (np. gdy zapomniałeś włączyć timer).\n\n'
          '3. Kategorie\n'
          '• Masz 3 podstawowe kategorie: Praca, Sport, Czas wolny.\n'
          '• Możesz tworzyć własne kategorie bezpośrednio z listy wyboru.\n\n'
          '4. Statystyki\n'
          '• Zakładka Statystyki pokazuje wykres słupkowy z ostatnich 7 dni i wykres kołowy podziału czasu.\n\n'
          '5. Cele\n'
          '• Dodaj cele tygodniowe lub miesięczne (np. 10h pracy).\n'
          '• Obserwuj pasek postępu dla każdego celu.\n\n'
          '6. Eksport danych\n'
          '• W zakładce Historia użyj opcji eksportu, aby zapisać dane do pliku JSON w pamięci telefonu.\n\n'
          '7. Import danych\n'
          '• Użyj opcji importu, aby wczytać wcześniej zapisany plik JSON.\n\n'
          '8. Prywatność\n'
          '• Wszystkie dane są zapisywane tylko lokalnie w pamięci urządzenia.',

      // TYPY
      'work': 'Praca',
      'sport': 'Sport',
      'free_time': 'Czas wolny',
      'type': 'Kategoria',
      'type_instruction': 'Wybierz kategorię swojej aktywności',

      // ZARZĄDZANIE TYPAMI
      'add_new_type': 'Dodaj nowy typ',
      'add_custom_type_title': 'Dodaj nowy typ aktywności',
      'custom_type_hint': 'Nazwa nowej aktywności (np. Nauka, Gitara)',
      'manage_custom_types': 'Zarządzaj typami',
      'no_custom_types': 'Brak własnych typów.',
      'type_name_label': 'Nazwa typu',
      'type_exists': 'Ten typ już istnieje',
      'type_added': 'Typ dodany',
      'type_deleted': 'Typ usunięty',
      'delete_type': 'Usuń typ',
      'cannot_delete_default': 'Nie można usunąć domyślnego typu',

      // TIMER
      'quick_timer': 'Szybki timer',
      'description_hint': 'Opis (opcjonalnie)',
      'start_btn': 'Start',
      'stop_btn': 'Stop',
      'no_active': 'Brak aktywnej sesji.',
      'close': 'Zamknij',
      'close_btn': 'Zamknij',

      // NOWA SEKCJA - POŁĄCZONA
      'new_activity_section': 'Nowa aktywność',
      'start_now_btn': 'START TERAZ',
      'add_time_range_btn': 'DODAJ ZAKRES CZASU',
      'running_since': 'Trwa od',

      // PODSUMOWANIA
      'summary_title': 'Podsumowanie',
      'summary_total': 'Suma',
      'no_data': 'Brak danych',
      'date_label': 'Data: ',
      'choose_date': 'Wybierz datę',

      // POLA FORMULARZA
      'description_label': 'Co będziesz robić? (np. Bieganie, Nauka)',
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

      // CELE
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

      // MEMORY GAME
      'games_tab': 'Gry',
      'memory_game_title': 'Memory Game',
      'new_game': 'Nowa gra',
      'time': 'Czas',
      'moves': 'Ruchy',
      'record': 'Rekord',
      'congratulations': 'Gratulacje! 🎉',
      'game_completed': 'Ukończyłeś grę!',
      'new_time_record': '🏆 NOWY REKORD CZASU!',
      'new_moves_record': '🏆 NOWY REKORD RUCHÓW!',
      'play_again': 'Graj ponownie',
      'game_instructions': 'Znajdź wszystkie pary! Kliknij kartę aby ją odkryć.',
      'your_records': '🏆 Twoje rekordy:',
      'best_time': 'Najlepszy czas:',
      'fewest_moves': 'Najmniej ruchów:',
      'choose_game': 'Wybierz grę',
      'games_subtitle': 'Relaksuj się pomiędzy sesjami pracy',
      'memory_game_desc': 'Znajdź wszystkie pary kart!',
      'coming_soon': 'Wkrótce dostępne!',
      'memory_level_easy': 'Łatwy (4x3, 6 par)',
      'memory_level_medium': 'Średni (4x4, 8 par)',
      'memory_level_hard': 'Trudny (4x5, 10 par)',
      'memory_level_advanced': 'Zaawansowany (4x6, 12 par)',
      'memory_level_expert': 'Ekspert (5x6, 15 par)',
      'memory_level_master': 'Mistrz (5x8, 18 par)',
      'memory_level_legend': 'Legenda (5x8, 20 par)',
      'memory_level_epic': 'Epicki (5x9, 22 pary)',
      'memory_level_nightmare': 'Koszmar (5x10, 24 pary)',
      'memory_level_impossible': 'Niemożliwy (5x10, 25 par)',
      'memory_choose_level': 'Wybierz poziom',
      'memory_locked': 'Poziom zablokowany. Najpierw ukończ poprzedni.',

      // SUDOKU
      'sudoku_game_title': 'Sudoku',
      'sudoku_game_desc': 'Wypełnij siatkę 9x9 cyframi!',
      'sudoku_choose_level': 'Wybierz poziom Sudoku',
      'sudoku_level_1': 'Poziom 1 - Początkujący',
      'sudoku_level_2': 'Poziom 2 - Łatwy',
      'sudoku_level_3': 'Poziom 3 - Średni łatwy',
      'sudoku_level_4': 'Poziom 4 - Średni',
      'sudoku_level_5': 'Poziom 5 - Średni trudny',
      'sudoku_level_6': 'Poziom 6 - Trudny',
      'sudoku_level_7': 'Poziom 7 - Bardzo trudny',
      'sudoku_level_8': 'Poziom 8 - Ekspert',
      'sudoku_level_9': 'Poziom 9 - Mistrz',
      'sudoku_level_10': 'Poziom 10 - Niemożliwy',
      'sudoku_locked': 'Poziom zablokowany. Najpierw ukończ poprzedni.',
      'sudoku_congratulations': 'Sudoku ukończone! 🎉',
      'sudoku_new_game': 'Nowa gra',
      'sudoku_check': 'Sprawdź',
      'sudoku_errors': 'Błędy',
      'sudoku_hint': 'Podpowiedź',
      'sudoku_hints_left': 'Podpowiedzi',
      'sudoku_solved': 'Rozwiązano!',
      'sudoku_mistake': 'Błąd! Spróbuj ponownie.',
      'sudoku_best_time': 'Najlepszy czas',

      // 📅 KALENDARZ WYDARZEŃ
      'events_tab': 'Wydarzenia',
      'events_title': 'Kalendarz Wydarzeń',
      'add_event': 'Dodaj wydarzenie',
      'no_events': 'Brak zaplanowanych wydarzeń',
      'event_title': 'Tytuł wydarzenia',
      'event_title_hint': 'np. Spotkanie, Trening',
      'event_date': 'Data i godzina',
      'event_category': 'Kategoria',
      'event_notes': 'Notatki',
      'event_notes_hint': 'Dodatkowe informacje (opcjonalnie)',
      'event_reminder': 'Przypomnienie',
      'event_category_other': 'Inne',
      'event_category_custom': 'Wpisz nazwę kategorii',
      'event_category_custom_hint': 'np. Spotkanie, Nauka, Zakupy',
      'event_added': 'Wydarzenie dodane!',
      'event_deleted': 'Wydarzenie usunięte',
      'reminder_before': 'przed',
      'reminder_day': 'dzień przed',
      'reminder_2days': '2 dni przed',
      'reminder_week': 'tydzień przed',
      'start_from_event': 'START z wydarzenia',
      'today_events': 'Dziś',
      'upcoming_events': 'Nadchodzące',
      'past_events': 'Przeszłe',
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

      // INSTRUKCJA
      'instructions_title': 'Instrucciones de uso',
      'instructions_content':
      'Work Study Timer te ayuda a seguir tu tiempo de estudio y trabajo.\n\n'
          '1. Iniciar el temporizador\n'
          '• En la pantalla principal pulsa START para comenzar una sesión.\n'
          '• Pulsa STOP para terminarla: la sesión se guardará en el historial.\n\n'
          '2. Sesiones manuales\n'
          '• Usa el botón de añadir sesión para introducir el tiempo manualmente.\n\n'
          '3. Categorías\n'
          '• Tienes 3 categorías básicas: Trabajo, Deporte, Tiempo libre.\n'
          '• Puedes crear tus propias categorías directamente desde la lista de selección.\n\n'
          '4. Estadísticas\n'
          '• La pestaña de Estadísticas muestra un gráfico de barras con los últimos 7 días.\n\n'
          '5. Objetivos\n'
          '• Añade objetivos semanales o mensuales.\n\n'
          '6. Exportar datos\n'
          '• En la pestaña de Historial utiliza la opción de exportar.\n\n'
          '7. Importar datos\n'
          '• Utiliza la opción de importar para cargar un archivo JSON.\n\n'
          '8. Privacidad\n'
          '• Todos los datos se guardan solo de forma local en tu dispositivo.',

      // TYPY
      'work': 'Trabajo',
      'sport': 'Deporte',
      'free_time': 'Tiempo libre',
      'type': 'Categoría',
      'type_instruction': 'Elige la categoría de tu actividad',

      // ZARZĄDZANIE TYPAMI
      'add_new_type': 'Añadir nuevo tipo',
      'add_custom_type_title': 'Añadir nuevo tipo de actividad',
      'custom_type_hint': 'Nombre de la nueva actividad',
      'manage_custom_types': 'Gestionar tipos',
      'no_custom_types': 'Sin tipos personalizados.',
      'type_name_label': 'Nombre del tipo',
      'type_exists': 'Este tipo ya existe',
      'type_added': 'Tipo añadido',
      'type_deleted': 'Tipo eliminado',
      'delete_type': 'Eliminar tipo',
      'cannot_delete_default': 'No se puede eliminar el tipo predeterminado',

      // TIMER
      'quick_timer': 'Temporizador rápido',
      'description_hint': 'Descripción (opcional)',
      'start_btn': 'Iniciar',
      'stop_btn': 'Detener',
      'no_active': 'Sin sesión activa.',
      'close': 'Cerrar',
      'close_btn': 'Cerrar',

      // NOWA SEKCJA - POŁĄCZONA
      'new_activity_section': 'Nueva actividad',
      'start_now_btn': 'INICIAR AHORA',
      'add_time_range_btn': 'AÑADIR RANGO DE TIEMPO',
      'running_since': 'Ejecutando desde',

      // PODSUMOWANIA
      'summary_title': 'Resumen',
      'summary_total': 'Total',
      'no_data': 'Sin datos',
      'date_label': 'Fecha: ',
      'choose_date': 'Elegir fecha',

      // POLA FORMULARZA
      'description_label': '¿Qué vas a hacer? (ej. Correr, Estudiar)',
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
      'error_edit_time': 'Horas incorrectas (formato HH:MM).',
      'session_running_from': 'Sesión desde: ',
      'field_type': 'Tipo: ',
      'field_mode': 'Modo: ',
      'session_deleted': 'Sesión eliminada',
      'session_updated': 'Sesión actualizada',

      // BACKUP
      'export_ok': 'Exportado OK: ',
      'export_error': 'Error de exportación: ',
      'export_success': 'Exportado a',
      'backup_missing': 'No hay archivo de copia de seguridad.',
      'import_ok': 'Sesiones importadas: ',
      'import_error': 'Error de importación: ',
      'import_success': 'Importación exitosa',
      'no_files_to_import': 'No hay archivos para importar',
      'choose_file_to_import': 'Elige archivo para importar',

      // USTAWIENIA
      'change_background': 'Cambiar fondo',
      'remove_background': 'Eliminar fondo',
      'icon_color_picker': 'Color de iconos',
      'slide_to_change_color': 'Desliza para cambiar el color',

      // CELE
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

      // MEMORY GAME
      'games_tab': 'Juegos',
      'memory_game_title': 'Juego de Memoria',
      'new_game': 'Nuevo juego',
      'time': 'Tiempo',
      'moves': 'Movimientos',
      'record': 'Récord',
      'congratulations': '¡Felicitaciones! 🎉',
      'game_completed': '¡Has completado el juego!',
      'new_time_record': '¡NUEVO RÉCORD DE TIEMPO!',
      'new_moves_record': '¡NUEVO RÉCORD DE MOVIMIENTOS!',
      'play_again': 'Jugar de nuevo',
      'game_instructions': '¡Encuentra todos los pares! Toca una carta para revelarla.',
      'your_records': '🏆 Tus récords:',
      'best_time': 'Mejor tiempo:',
      'fewest_moves': 'Menos movimientos:',
      'choose_game': 'Elige un juego',
      'games_subtitle': 'Relájate entre sesiones de trabajo',
      'memory_game_desc': '¡Encuentra todos los pares de cartas!',
      'coming_soon': '¡Próximamente!',
      'memory_level_easy': 'Fácil (4x3, 6 pares)',
      'memory_level_medium': 'Medio (4x4, 8 pares)',
      'memory_level_hard': 'Difícil (4x5, 10 pares)',
      'memory_level_advanced': 'Avanzado (4x6, 12 pares)',
      'memory_level_expert': 'Experto (5x6, 15 pares)',
      'memory_level_master': 'Maestro (5x8, 18 pares)',
      'memory_level_legend': 'Leyenda (5x8, 20 pares)',
      'memory_level_epic': 'Épico (5x9, 22 pares)',
      'memory_level_nightmare': 'Pesadilla (5x10, 24 pares)',
      'memory_level_impossible': 'Imposible (5x10, 25 pares)',
      'memory_choose_level': 'Elige la dificultad',
      'memory_locked': 'Nivel bloqueado. Primero completa el anterior.',

      // SUDOKU
      'sudoku_game_title': 'Sudoku',
      'sudoku_game_desc': '¡Rellena la cuadrícula 9x9 con números!',
      'sudoku_choose_level': 'Elige nivel de Sudoku',
      'sudoku_level_1': 'Nivel 1 - Principiante',
      'sudoku_level_2': 'Nivel 2 - Fácil',
      'sudoku_level_3': 'Nivel 3 - Fácil medio',
      'sudoku_level_4': 'Nivel 4 - Medio',
      'sudoku_level_5': 'Nivel 5 - Medio difícil',
      'sudoku_level_6': 'Nivel 6 - Difícil',
      'sudoku_level_7': 'Nivel 7 - Muy difícil',
      'sudoku_level_8': 'Nivel 8 - Experto',
      'sudoku_level_9': 'Nivel 9 - Maestro',
      'sudoku_level_10': 'Nivel 10 - Imposible',
      'sudoku_locked': 'Nivel bloqueado. Primero completa el anterior.',
      'sudoku_congratulations': '¡Sudoku completado! 🎉',
      'sudoku_new_game': 'Nuevo juego',
      'sudoku_check': 'Comprobar',
      'sudoku_errors': 'Errores',
      'sudoku_hint': 'Pista',
      'sudoku_hints_left': 'Pistas',
      'sudoku_solved': '¡Resuelto!',
      'sudoku_mistake': '¡Error! Inténtalo de nuevo.',
      'sudoku_best_time': 'Mejor tiempo',

      // 📅 CALENDARIO DE EVENTOS
      'events_tab': 'Eventos',
      'events_title': 'Calendario de Eventos',
      'add_event': 'Añadir evento',
      'no_events': 'No hay eventos programados',
      'event_title': 'Título del evento',
      'event_title_hint': 'ej. Reunión, Entrenamiento',
      'event_date': 'Fecha y hora',
      'event_category': 'Categoría',
      'event_notes': 'Notas',
      'event_notes_hint': 'Información adicional (opcional)',
      'event_reminder': 'Recordatorio',
      'event_category_other': 'Otro',
      'event_category_custom': 'Escribe el nombre de la categoría',
      'event_category_custom_hint': 'ej. Reunión, Estudio, Compras',
      'event_added': '¡Evento añadido!',
      'event_deleted': 'Evento eliminado',
      'reminder_before': 'antes',
      'reminder_day': 'día antes',
      'reminder_2days': '2 días antes',
      'reminder_week': 'semana antes',
      'start_from_event': 'INICIAR desde evento',
      'today_events': 'Hoy',
      'upcoming_events': 'Próximos',
      'past_events': 'Pasados',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['pl']![key] ??
        key;
  }
}

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