// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'FlowWave';

  @override
  String get disclaimer =>
      'FlowWave pokazuje osobiste szacunki rytmu na podstawie danych, które zdecydujesz się udostępnić. Nie są to oceny medyczne ani diagnozy.';

  @override
  String get actionContinue => 'Dalej';

  @override
  String get actionNext => 'Następna';

  @override
  String get actionCancel => 'Anuluj';

  @override
  String get actionRetry => 'Spróbuj ponownie';

  @override
  String get actionDelete => 'Usuń';

  @override
  String get splashLoading => 'Przygotowuję FlowWave…';

  @override
  String get startupFailedTitle => 'Nie udało się uruchomić FlowWave';

  @override
  String get startupFailedBody =>
      'Coś poszło nie tak podczas otwierania danych zapisanych na tym telefonie.';

  @override
  String get startupKeyLostTitle =>
      'Nie można odczytać danych na tym telefonie';

  @override
  String get startupKeyLostBody =>
      'Brakuje klucza, który chroni dane FlowWave na tym telefonie, więc nie da się ich odszyfrować. To, co zostało zsynchronizowane z kontem, wróci po ponownym zalogowaniu. To, czego nigdy nie zsynchronizowano, przepadło.';

  @override
  String get startupEncryptionUnavailableBody =>
      'Ten telefon nie potrafi zaszyfrować danych FlowWave. FlowWave nigdy nie zapisuje danych bez szyfrowania, więc nie może się uruchomić.';

  @override
  String get startupResetAction => 'Wyczyść dane na tym telefonie';

  @override
  String get startupResetConfirmBody =>
      'To usunie nieczytelne dane z tego telefonu i uruchomi FlowWave od początku.';

  @override
  String get privacyIntroTitle => 'Twoje dane należą do Ciebie';

  @override
  String get privacyIntroLead =>
      'FlowWave pomaga zauważyć Twój rytm energii i skupienia. Oto jak traktuje Twoje dane.';

  @override
  String get privacyIntroLocal =>
      'Wszystko trafia najpierw, w postaci zaszyfrowanej, na ten telefon. FlowWave działa bez konta i bez internetu.';

  @override
  String get privacyIntroConsent =>
      'Nic nie jest odczytywane z innych aplikacji ani urządzeń, dopóki tego nie włączysz. W każdej chwili możesz zmienić zdanie.';

  @override
  String get privacyIntroNoContent =>
      'FlowWave nigdy nie zbiera tego, co piszesz, czytasz lub tworzysz: żadnych wiadomości, adresów stron, tytułów okien, nazw plików ani naciśnięć klawiszy.';

  @override
  String get privacyIntroNotMedical =>
      'FlowWave nie jest aplikacją medyczną. Jej szacunki nie są diagnozami i nie zastępują porady specjalisty.';

  @override
  String get privacyIntroAccount =>
      'Konto jest opcjonalne. Z kontem masz kopię zapasową danych i w każdej chwili możesz usunąć konto razem z danymi.';

  @override
  String get consentTitle => 'Wybierz, czego FlowWave może używać';

  @override
  String get consentLead =>
      'Wszystko jest wyłączone, dopóki tego nie włączysz. Na razie nic nie jest zbierane: każda funkcja użyje swoich danych dopiero wtedy, gdy pojawi się w aplikacji.';

  @override
  String get consentHealthTitle => 'Dane zdrowotne z Health Connect';

  @override
  String get consentHealthBody =>
      'Sen, kroki i tętno do szacowania Twojego rytmu. Import pojawi się w jednej z kolejnych wersji.';

  @override
  String get consentDeviceUsageTitle => 'Wzorce korzystania z telefonu';

  @override
  String get consentDeviceUsageBody =>
      'Czas w poszczególnych kategoriach aplikacji, nigdy treść ani nazwy aplikacji. Pojawi się w jednej z kolejnych wersji.';

  @override
  String get consentNotificationsTitle => 'Przypomnienia';

  @override
  String get consentNotificationsBody =>
      'Delikatne przypomnienia o check-inie w wybranych przez Ciebie porach.';

  @override
  String get consentAnalyticsTitle => 'Anonimowe statystyki użycia';

  @override
  String get consentAnalyticsBody =>
      'Pomagają ulepszać FlowWave. Nigdy nie zawierają wartości zdrowotnych.';

  @override
  String get consentScopesLabel => 'Rodzaje danych';

  @override
  String get consentScopeSleepDuration => 'Długość snu';

  @override
  String get consentScopeSteps => 'Kroki';

  @override
  String get consentScopeHeartRate => 'Tętno';

  @override
  String get consentScopeRestingHeartRate => 'Tętno spoczynkowe';

  @override
  String get consentOutdated =>
      'Opis zmienił się od czasu Twojej zgody. Włącz ponownie, aby zgodzić się na nową wersję.';

  @override
  String get consentChangeLater =>
      'Te wybory możesz zmienić w każdej chwili w Ustawieniach, w sekcji Dane i prywatność.';

  @override
  String get consentStatusOn => 'Włączone';

  @override
  String get consentStatusOff => 'Wyłączone';

  @override
  String get onboardingCheckInTitle => 'Krótkie check-iny';

  @override
  String get onboardingCheckInBody =>
      'Powiedz FlowWave, jak czujesz swoją energię i skupienie, w kilku dotknięciach.';

  @override
  String get onboardingRhythmTitle => 'Twój rytm z wyjaśnieniem';

  @override
  String get onboardingRhythmBody =>
      'FlowWave szuka wzorców w Twoich check-inach i pokazuje, na jakich danych opiera się każdy szacunek.';

  @override
  String get onboardingOfflineTitle => 'Działa offline';

  @override
  String get onboardingOfflineBody =>
      'Korzystaj z FlowWave bez konta. Załóż je, jeśli chcesz mieć kopię zapasową i dostęp na innych urządzeniach.';

  @override
  String onboardingPageLabel(int current, int total) {
    return 'Strona $current z $total';
  }

  @override
  String get onboardingCreateAccount => 'Załóż konto';

  @override
  String get onboardingSignIn => 'Mam już konto';

  @override
  String get onboardingWithoutAccount => 'Kontynuuj bez konta';

  @override
  String get accountsUnavailable =>
      'Konta nie są dostępne w tej wersji. Twoje dane zostają na tym telefonie.';

  @override
  String get loginTitle => 'Zaloguj się';

  @override
  String get registerTitle => 'Załóż konto';

  @override
  String get fieldEmail => 'E-mail';

  @override
  String get fieldPassword => 'Hasło';

  @override
  String get fieldPasswordRepeat => 'Powtórz hasło';

  @override
  String get passwordHint =>
      'Co najmniej 12 znaków. Dobrze sprawdza się krótkie zdanie.';

  @override
  String get showPassword => 'Pokaż hasło';

  @override
  String get hidePassword => 'Ukryj hasło';

  @override
  String get validationEmail => 'Wpisz poprawny adres e-mail.';

  @override
  String get validationPasswordRequired => 'Wpisz hasło.';

  @override
  String get validationPasswordLength => 'Użyj od 12 do 128 znaków.';

  @override
  String get validationPasswordMismatch => 'Hasła nie są takie same.';

  @override
  String get loginAction => 'Zaloguj się';

  @override
  String get registerAction => 'Załóż konto';

  @override
  String get loginToRegister => 'Nie masz konta? Załóż je';

  @override
  String get registerToLogin => 'Masz już konto? Zaloguj się';

  @override
  String registerTimeZoneNote(String zone) {
    return 'Twoja strefa czasowa ($zone) zostanie zapisana z kontem, aby godziny były pokazywane tam, gdzie coś się wydarzyło.';
  }

  @override
  String get registerEmailNote =>
      'Twój e-mail służy wyłącznie do logowania. FlowWave nie wysyła reklam.';

  @override
  String get errorNetwork =>
      'Brak połączenia z serwerem FlowWave. Twoje dane są bezpieczne na tym telefonie; spróbuj później.';

  @override
  String get errorNotConfigured =>
      'Ta wersja FlowWave nie ma skonfigurowanego serwera.';

  @override
  String get errorNotSignedIn =>
      'Wylogowano Cię. Zaloguj się, aby dalej synchronizować dane.';

  @override
  String get errorInvalidCredentials => 'Nieprawidłowy e-mail lub hasło.';

  @override
  String get errorSessionEnded => 'Twoja sesja wygasła. Zaloguj się ponownie.';

  @override
  String get errorWrongPassword => 'Nieprawidłowe hasło.';

  @override
  String get errorForbidden => 'Ta czynność jest niedozwolona.';

  @override
  String get errorConsentRequired => 'To wymaga najpierw Twojej zgody.';

  @override
  String get errorValidation =>
      'Niektóre dane są nieprawidłowe. Sprawdź je i spróbuj ponownie.';

  @override
  String get errorEmailTaken => 'Konto z tym adresem e-mail już istnieje.';

  @override
  String get errorConflict => 'Ta zmiana jest sprzeczna z danymi na serwerze.';

  @override
  String get errorNotFound => 'Nie znaleziono.';

  @override
  String get errorRateLimited =>
      'Zbyt wiele prób. Odczekaj chwilę i spróbuj ponownie.';

  @override
  String get errorServer => 'Serwer ma problem. Spróbuj później.';

  @override
  String get errorStorage => 'Nie udało się zapisać danych na tym telefonie.';

  @override
  String get errorUnknown => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get navToday => 'Dziś';

  @override
  String get navCheckIn => 'Check-in';

  @override
  String get navTimeline => 'Oś czasu';

  @override
  String get navInsights => 'Wnioski';

  @override
  String get openSettings => 'Ustawienia';

  @override
  String get comingLater => 'Pojawi się w jednej z kolejnych wersji';

  @override
  String get todayPlaceholder =>
      'Tutaj zobaczysz swój dzień w skrócie: check-iny i szacunek rytmu energii i skupienia wraz z jego uzasadnieniem.';

  @override
  String get checkInPlaceholder =>
      'Tutaj w kilku dotknięciach zapiszesz, jak teraz czujesz swoją energię, skupienie i nastrój.';

  @override
  String get timelinePlaceholder =>
      'Tutaj pojawią się po kolei Twoje check-iny i zsynchronizowane dane, w czasie lokalnym miejsca, w którym się wydarzyły.';

  @override
  String get insightsPlaceholder =>
      'Tutaj pojawią się wzorce Twojego rytmu, gdy zbierze się wystarczająco dużo danych, zawsze z czynnikami, na których się opierają.';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsAppearance => 'Wygląd';

  @override
  String get settingsTheme => 'Motyw';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get languageSystem => 'Systemowy';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePolish => 'Polski';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get accountSignedIn =>
      'Zalogowano. Dane synchronizują się, gdy masz internet.';

  @override
  String get accountSignedOut =>
      'Nie zalogowano. Dane są zapisane tylko na tym telefonie.';

  @override
  String get accountSignIn => 'Zaloguj się';

  @override
  String get accountCreate => 'Załóż konto';

  @override
  String get accountSignOut => 'Wyloguj się';

  @override
  String get accountSignOutAll => 'Wyloguj się na wszystkich urządzeniach';

  @override
  String get signOutDialogTitle => 'Wylogować się?';

  @override
  String get signOutDialogBody =>
      'Wylogowanie usuwa dane konta z tego telefonu. Twoje preferencje zostają.';

  @override
  String signOutPendingWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zmiany nie zostały jeszcze wysłane i przepadną.',
      many: '$count zmian nie zostało jeszcze wysłanych i przepadnie.',
      few: '$count zmiany nie zostały jeszcze wysłane i przepadną.',
      one: '1 zmiana nie została jeszcze wysłana i przepadnie.',
    );
    return '$_temp0';
  }

  @override
  String get settingsDataPrivacy => 'Dane i prywatność';

  @override
  String get settingsDataPrivacySubtitle =>
      'Zgody, synchronizacja i usuwanie danych';

  @override
  String get settingsAbout => 'O aplikacji';

  @override
  String get dataPrivacyTitle => 'Dane i prywatność';

  @override
  String get dataPrivacyConsents => 'Zgody';

  @override
  String get dataPrivacyOnPhone => 'Na tym telefonie';

  @override
  String get dataPrivacyOnPhoneBody =>
      'Dane FlowWave są zapisane na tym telefonie w postaci zaszyfrowanej i nie trafiają do kopii zapasowych w chmurze.';

  @override
  String dataPrivacyConsentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zapisanej decyzji o zgodach',
      many: '$count zapisanych decyzji o zgodach',
      few: '$count zapisane decyzje o zgodach',
      one: '1 zapisana decyzja o zgodzie',
      zero: 'Brak zapisanych decyzji o zgodach',
    );
    return '$_temp0';
  }

  @override
  String get dataPrivacySync => 'Synchronizacja';

  @override
  String get syncOff =>
      'Synchronizacja jest wyłączona. Zaloguj się, aby mieć kopię zapasową danych.';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zmiany czekają na wysłanie.',
      many: '$count zmian czeka na wysłanie.',
      few: '$count zmiany czekają na wysłanie.',
      one: '1 zmiana czeka na wysłanie.',
      zero: 'Wszystko zostało wysłane.',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Serwer odrzucił $count zmiany. Nie zostaną ponowione.',
      many: 'Serwer odrzucił $count zmian. Nie zostaną ponowione.',
      few: 'Serwer odrzucił $count zmiany. Nie zostaną ponowione.',
      one: 'Serwer odrzucił 1 zmianę. Nie zostanie ponowiona.',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Synchronizuj teraz';

  @override
  String get syncDone => 'Synchronizacja zakończona.';

  @override
  String get syncWillRetry =>
      'Nie udało się teraz zsynchronizować. FlowWave spróbuje ponownie później.';

  @override
  String get deleteLocalTitle => 'Usuń dane z tego telefonu';

  @override
  String get deleteLocalBodySignedIn =>
      'Usuwa wszystko, co FlowWave zapisała na tym telefonie, i wylogowuje Cię. Konto i zsynchronizowane dane zostają na serwerze.';

  @override
  String get deleteLocalBodySignedOut =>
      'Usuwa wszystko, co FlowWave zapisała na tym telefonie. Tej operacji nie można cofnąć.';

  @override
  String get deleteAccountTitle => 'Usuń konto';

  @override
  String get deleteAccountBody =>
      'Od razu usuwa Twoje konto i wszystkie jego dane z serwera, a potem z tego telefonu. Tej operacji nie można cofnąć.';

  @override
  String get deleteAccountPasswordPrompt => 'Wpisz hasło, aby potwierdzić.';

  @override
  String get deleteAccountDone => 'Twoje konto zostało usunięte.';
}
