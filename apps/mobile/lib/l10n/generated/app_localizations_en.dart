// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FlowWave';

  @override
  String get disclaimer =>
      'FlowWave shows personal rhythm estimates based on the data you choose to share. They are not medical assessments or diagnoses.';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionNext => 'Next';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionDelete => 'Delete';

  @override
  String get splashLoading => 'Preparing FlowWave…';

  @override
  String get startupFailedTitle => 'FlowWave could not start';

  @override
  String get startupFailedBody =>
      'Something went wrong while opening the data stored on this phone.';

  @override
  String get startupKeyLostTitle => 'Data on this phone cannot be read';

  @override
  String get startupKeyLostBody =>
      'The key that protects FlowWave\'s data on this phone is missing, so the data cannot be decrypted. Anything synced to your account comes back when you sign in again. Anything never synced is lost.';

  @override
  String get startupEncryptionUnavailableBody =>
      'This phone cannot encrypt FlowWave\'s data. FlowWave never stores data unencrypted, so it cannot start.';

  @override
  String get startupResetAction => 'Reset data on this phone';

  @override
  String get startupResetConfirmBody =>
      'This deletes the unreadable data on this phone and starts FlowWave from the beginning.';

  @override
  String get privacyIntroTitle => 'Your data stays yours';

  @override
  String get privacyIntroLead =>
      'FlowWave helps you notice your energy and focus rhythm. Here is how it treats your data.';

  @override
  String get privacyIntroLocal =>
      'Everything is stored encrypted on this phone first. FlowWave works without an account and without internet.';

  @override
  String get privacyIntroConsent =>
      'Nothing is read from other apps or devices unless you switch it on. You can change your mind at any time.';

  @override
  String get privacyIntroNoContent =>
      'FlowWave never collects what you type, read or write: no messages, website addresses, window titles, file names or keystrokes.';

  @override
  String get privacyIntroNotMedical =>
      'FlowWave is not a medical app. Its estimates are not diagnoses and do not replace advice from a professional.';

  @override
  String get privacyIntroAccount =>
      'An account is optional. With one, your data is backed up, and you can delete the account and its data at any time.';

  @override
  String get consentTitle => 'Choose what FlowWave may use';

  @override
  String get consentLead =>
      'Everything is off until you switch it on. Nothing is collected yet: each feature uses its data only once it is available in the app.';

  @override
  String get consentHealthTitle => 'Health data from Health Connect';

  @override
  String get consentHealthBody =>
      'Sleep, steps and heart rate, to estimate your rhythm. The import arrives in a later version.';

  @override
  String get consentDeviceUsageTitle => 'Phone usage patterns';

  @override
  String get consentDeviceUsageBody =>
      'Time per app category, never content or app names. Arrives in a later version.';

  @override
  String get consentNotificationsTitle => 'Reminders';

  @override
  String get consentNotificationsBody =>
      'Gentle check-in reminders at times you choose.';

  @override
  String get consentAnalyticsTitle => 'Anonymous usage statistics';

  @override
  String get consentAnalyticsBody =>
      'Helps improve FlowWave. Never includes health values.';

  @override
  String get consentScopesLabel => 'Data types';

  @override
  String get consentScopeSleepDuration => 'Sleep duration';

  @override
  String get consentScopeSteps => 'Steps';

  @override
  String get consentScopeHeartRate => 'Heart rate';

  @override
  String get consentScopeRestingHeartRate => 'Resting heart rate';

  @override
  String get consentOutdated =>
      'The description changed since you agreed. Switch it on again to agree to the new version.';

  @override
  String get consentChangeLater =>
      'You can change these choices at any time in Settings, under Data and privacy.';

  @override
  String get consentStatusOn => 'On';

  @override
  String get consentStatusOff => 'Off';

  @override
  String get onboardingCheckInTitle => 'Short check-ins';

  @override
  String get onboardingCheckInBody =>
      'Tell FlowWave how your energy and focus feel, in a few taps.';

  @override
  String get onboardingRhythmTitle => 'Your rhythm, explained';

  @override
  String get onboardingRhythmBody =>
      'FlowWave looks for patterns in your check-ins and shows which inputs each estimate is based on.';

  @override
  String get onboardingOfflineTitle => 'Works offline';

  @override
  String get onboardingOfflineBody =>
      'Use FlowWave without an account. Create one if you want a backup and access on other devices.';

  @override
  String onboardingPageLabel(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get onboardingCreateAccount => 'Create account';

  @override
  String get onboardingSignIn => 'I already have an account';

  @override
  String get onboardingWithoutAccount => 'Continue without account';

  @override
  String get accountsUnavailable =>
      'Accounts are not available in this version. Your data stays on this phone.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get registerTitle => 'Create account';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordRepeat => 'Repeat password';

  @override
  String get passwordHint =>
      'At least 12 characters. A short sentence works well.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get validationEmail => 'Enter a valid email address.';

  @override
  String get validationPasswordRequired => 'Enter your password.';

  @override
  String get validationPasswordLength => 'Use 12 to 128 characters.';

  @override
  String get validationPasswordMismatch => 'The passwords do not match.';

  @override
  String get loginAction => 'Sign in';

  @override
  String get registerAction => 'Create account';

  @override
  String get loginToRegister => 'No account yet? Create one';

  @override
  String get registerToLogin => 'Already have an account? Sign in';

  @override
  String registerTimeZoneNote(String zone) {
    return 'Your time zone ($zone) is saved with your account, so times are shown where they happened.';
  }

  @override
  String get registerEmailNote =>
      'Your email is used only to sign in. FlowWave sends no marketing.';

  @override
  String get errorNetwork =>
      'No connection to the FlowWave server. Your data is safe on this phone; try again later.';

  @override
  String get errorNotConfigured =>
      'This version of FlowWave has no server configured.';

  @override
  String get errorNotSignedIn =>
      'You are signed out. Sign in to continue syncing.';

  @override
  String get errorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get errorSessionEnded => 'Your session ended. Please sign in again.';

  @override
  String get errorWrongPassword => 'The password is incorrect.';

  @override
  String get errorForbidden => 'This action is not allowed.';

  @override
  String get errorConsentRequired => 'This needs your consent first.';

  @override
  String get errorValidation =>
      'Some details are not valid. Check them and try again.';

  @override
  String get errorEmailTaken => 'An account with this email already exists.';

  @override
  String get errorConflict => 'This change conflicts with data on the server.';

  @override
  String get errorNotFound => 'This could not be found.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get errorServer => 'The server had a problem. Try again later.';

  @override
  String get errorStorage => 'Data on this phone could not be saved.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get navToday => 'Today';

  @override
  String get navCheckIn => 'Check-in';

  @override
  String get navTimeline => 'Timeline';

  @override
  String get navInsights => 'Insights';

  @override
  String get openSettings => 'Settings';

  @override
  String get comingLater => 'Coming in a later version';

  @override
  String get todayPlaceholder =>
      'Your day at a glance will appear here: your check-ins and an estimate of your energy and focus rhythm, with the reasons behind it.';

  @override
  String get checkInPlaceholder =>
      'Here you will record how your energy, focus and mood feel right now, in a few taps.';

  @override
  String get timelinePlaceholder =>
      'Your check-ins and synced data will appear here in order, at the local time where they happened.';

  @override
  String get insightsPlaceholder =>
      'Patterns in your rhythm will appear here once there is enough data, always with the factors they are based on.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePolish => 'Polski';

  @override
  String get settingsAccount => 'Account';

  @override
  String get accountSignedIn =>
      'Signed in. Your data syncs when you are online.';

  @override
  String get accountSignedOut =>
      'Not signed in. Your data is stored only on this phone.';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountCreate => 'Create account';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutAll => 'Sign out on all devices';

  @override
  String get signOutDialogTitle => 'Sign out?';

  @override
  String get signOutDialogBody =>
      'Signing out removes your account data from this phone. Your preferences stay.';

  @override
  String signOutPendingWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes have not been uploaded yet and will be lost.',
      one: '1 change has not been uploaded yet and will be lost.',
    );
    return '$_temp0';
  }

  @override
  String get settingsDataPrivacy => 'Data and privacy';

  @override
  String get settingsDataPrivacySubtitle => 'Consents, sync and deleting data';

  @override
  String get settingsAbout => 'About';

  @override
  String get dataPrivacyTitle => 'Data and privacy';

  @override
  String get dataPrivacyConsents => 'Consents';

  @override
  String get dataPrivacyOnPhone => 'On this phone';

  @override
  String get dataPrivacyOnPhoneBody =>
      'FlowWave\'s data is stored encrypted on this phone and is excluded from cloud backups.';

  @override
  String dataPrivacyConsentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consent decisions stored',
      one: '1 consent decision stored',
      zero: 'No consent decisions stored',
    );
    return '$_temp0';
  }

  @override
  String get dataPrivacySync => 'Sync';

  @override
  String get syncOff => 'Sync is off. Sign in to back up your data.';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes are waiting to upload.',
      one: '1 change is waiting to upload.',
      zero: 'Everything is uploaded.',
    );
    return '$_temp0';
  }

  @override
  String syncRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The server refused $count changes. They will not be retried.',
      one: 'The server refused 1 change. It will not be retried.',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncDone => 'Sync finished.';

  @override
  String get syncWillRetry =>
      'Could not sync right now. FlowWave will try again later.';

  @override
  String get deleteLocalTitle => 'Delete data on this phone';

  @override
  String get deleteLocalBodySignedIn =>
      'Removes everything FlowWave stored on this phone and signs you out. Your account and its synced data stay on the server.';

  @override
  String get deleteLocalBodySignedOut =>
      'Removes everything FlowWave stored on this phone. This cannot be undone.';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountBody =>
      'Deletes your account and all its data on the server at once, then removes it from this phone. This cannot be undone.';

  @override
  String get deleteAccountPasswordPrompt => 'Enter your password to confirm.';

  @override
  String get deleteAccountDone => 'Your account was deleted.';
}
