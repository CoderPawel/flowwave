import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// App name, not translated.
  ///
  /// In en, this message translates to:
  /// **'FlowWave'**
  String get appTitle;

  /// Shown wherever estimates appear (AGENTS.md rules 1 and 2).
  ///
  /// In en, this message translates to:
  /// **'FlowWave shows personal rhythm estimates based on the data you choose to share. They are not medical assessments or diagnoses.'**
  String get disclaimer;

  /// Button that moves to the next step.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Button that shows the next onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// Dismisses a dialog without changes.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Repeats a failed action.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// Confirms a deletion.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Shown while the app opens its local data.
  ///
  /// In en, this message translates to:
  /// **'Preparing FlowWave…'**
  String get splashLoading;

  /// Title when opening local data failed.
  ///
  /// In en, this message translates to:
  /// **'FlowWave could not start'**
  String get startupFailedTitle;

  /// Body when opening local data failed for an unknown reason.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while opening the data stored on this phone.'**
  String get startupFailedBody;

  /// Title when the database key is missing.
  ///
  /// In en, this message translates to:
  /// **'Data on this phone cannot be read'**
  String get startupKeyLostTitle;

  /// Explains a lost database key and its consequences.
  ///
  /// In en, this message translates to:
  /// **'The key that protects FlowWave\'s data on this phone is missing, so the data cannot be decrypted. Anything synced to your account comes back when you sign in again. Anything never synced is lost.'**
  String get startupKeyLostBody;

  /// Shown when the SQLite build has no encryption.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot encrypt FlowWave\'s data. FlowWave never stores data unencrypted, so it cannot start.'**
  String get startupEncryptionUnavailableBody;

  /// Deletes the unreadable local database.
  ///
  /// In en, this message translates to:
  /// **'Reset data on this phone'**
  String get startupResetAction;

  /// Confirmation text before resetting local data.
  ///
  /// In en, this message translates to:
  /// **'This deletes the unreadable data on this phone and starts FlowWave from the beginning.'**
  String get startupResetConfirmBody;

  /// Title of the privacy introduction.
  ///
  /// In en, this message translates to:
  /// **'Your data stays yours'**
  String get privacyIntroTitle;

  /// Lead paragraph of the privacy introduction.
  ///
  /// In en, this message translates to:
  /// **'FlowWave helps you notice your energy and focus rhythm. Here is how it treats your data.'**
  String get privacyIntroLead;

  /// Privacy point: local, encrypted, offline.
  ///
  /// In en, this message translates to:
  /// **'Everything is stored encrypted on this phone first. FlowWave works without an account and without internet.'**
  String get privacyIntroLocal;

  /// Privacy point: consent per source.
  ///
  /// In en, this message translates to:
  /// **'Nothing is read from other apps or devices unless you switch it on. You can change your mind at any time.'**
  String get privacyIntroConsent;

  /// Privacy point: forbidden data (AGENTS.md rule 5).
  ///
  /// In en, this message translates to:
  /// **'FlowWave never collects what you type, read or write: no messages, website addresses, window titles, file names or keystrokes.'**
  String get privacyIntroNoContent;

  /// Privacy point: not a medical app (AGENTS.md rule 1).
  ///
  /// In en, this message translates to:
  /// **'FlowWave is not a medical app. Its estimates are not diagnoses and do not replace advice from a professional.'**
  String get privacyIntroNotMedical;

  /// Privacy point: optional account.
  ///
  /// In en, this message translates to:
  /// **'An account is optional. With one, your data is backed up, and you can delete the account and its data at any time.'**
  String get privacyIntroAccount;

  /// Title of the consent selection.
  ///
  /// In en, this message translates to:
  /// **'Choose what FlowWave may use'**
  String get consentTitle;

  /// Lead paragraph of the consent selection.
  ///
  /// In en, this message translates to:
  /// **'Everything is off until you switch it on. Nothing is collected yet: each feature uses its data only once it is available in the app.'**
  String get consentLead;

  /// Consent for health data from Health Connect.
  ///
  /// In en, this message translates to:
  /// **'Health data from Health Connect'**
  String get consentHealthTitle;

  /// What health data consent covers.
  ///
  /// In en, this message translates to:
  /// **'Sleep, steps and heart rate, to estimate your rhythm. The import arrives in a later version.'**
  String get consentHealthBody;

  /// Consent for device usage data.
  ///
  /// In en, this message translates to:
  /// **'Phone usage patterns'**
  String get consentDeviceUsageTitle;

  /// What device usage consent covers.
  ///
  /// In en, this message translates to:
  /// **'Time per app category, never content or app names. Arrives in a later version.'**
  String get consentDeviceUsageBody;

  /// Consent for notifications.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get consentNotificationsTitle;

  /// What notification consent covers.
  ///
  /// In en, this message translates to:
  /// **'Gentle check-in reminders at times you choose.'**
  String get consentNotificationsBody;

  /// Consent for product analytics.
  ///
  /// In en, this message translates to:
  /// **'Anonymous usage statistics'**
  String get consentAnalyticsTitle;

  /// What analytics consent covers.
  ///
  /// In en, this message translates to:
  /// **'Helps improve FlowWave. Never includes health values.'**
  String get consentAnalyticsBody;

  /// Heading above the health data scope choices.
  ///
  /// In en, this message translates to:
  /// **'Data types'**
  String get consentScopesLabel;

  /// Health data scope.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration'**
  String get consentScopeSleepDuration;

  /// Health data scope.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get consentScopeSteps;

  /// Health data scope.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get consentScopeHeartRate;

  /// Health data scope.
  ///
  /// In en, this message translates to:
  /// **'Resting heart rate'**
  String get consentScopeRestingHeartRate;

  /// Shown when a consent was given under an older text.
  ///
  /// In en, this message translates to:
  /// **'The description changed since you agreed. Switch it on again to agree to the new version.'**
  String get consentOutdated;

  /// Hint below the consent selection.
  ///
  /// In en, this message translates to:
  /// **'You can change these choices at any time in Settings, under Data and privacy.'**
  String get consentChangeLater;

  /// Screen reader value of a granted consent switch.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get consentStatusOn;

  /// Screen reader value of a consent switch that is off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get consentStatusOff;

  /// Onboarding page title.
  ///
  /// In en, this message translates to:
  /// **'Short check-ins'**
  String get onboardingCheckInTitle;

  /// Onboarding page body.
  ///
  /// In en, this message translates to:
  /// **'Tell FlowWave how your energy and focus feel, in a few taps.'**
  String get onboardingCheckInBody;

  /// Onboarding page title.
  ///
  /// In en, this message translates to:
  /// **'Your rhythm, explained'**
  String get onboardingRhythmTitle;

  /// Onboarding page body (AGENTS.md rule 10).
  ///
  /// In en, this message translates to:
  /// **'FlowWave looks for patterns in your check-ins and shows which inputs each estimate is based on.'**
  String get onboardingRhythmBody;

  /// Onboarding page title.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get onboardingOfflineTitle;

  /// Onboarding page body.
  ///
  /// In en, this message translates to:
  /// **'Use FlowWave without an account. Create one if you want a backup and access on other devices.'**
  String get onboardingOfflineBody;

  /// Screen reader label of the onboarding page indicator.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageLabel(int current, int total);

  /// Starts registration from onboarding.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get onboardingCreateAccount;

  /// Starts sign-in from onboarding.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get onboardingSignIn;

  /// Finishes onboarding without an account.
  ///
  /// In en, this message translates to:
  /// **'Continue without account'**
  String get onboardingWithoutAccount;

  /// Shown when the build has no API configured.
  ///
  /// In en, this message translates to:
  /// **'Accounts are not available in this version. Your data stays on this phone.'**
  String get accountsUnavailable;

  /// Title of the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// Title of the registration screen.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// Password confirmation field label.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get fieldPasswordRepeat;

  /// Helper text below the new password field.
  ///
  /// In en, this message translates to:
  /// **'At least 12 characters. A short sentence works well.'**
  String get passwordHint;

  /// Tooltip and screen reader label of the reveal button.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Tooltip and screen reader label of the hide button.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Form error for an invalid email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmail;

  /// Form error for an empty password.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get validationPasswordRequired;

  /// Form error for a new password of the wrong length.
  ///
  /// In en, this message translates to:
  /// **'Use 12 to 128 characters.'**
  String get validationPasswordLength;

  /// Form error when the repeated password differs.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get validationPasswordMismatch;

  /// Submit button of the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginAction;

  /// Submit button of the registration form.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerAction;

  /// Link from sign-in to registration.
  ///
  /// In en, this message translates to:
  /// **'No account yet? Create one'**
  String get loginToRegister;

  /// Link from registration to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get registerToLogin;

  /// Explains why the time zone is sent at registration.
  ///
  /// In en, this message translates to:
  /// **'Your time zone ({zone}) is saved with your account, so times are shown where they happened.'**
  String registerTimeZoneNote(String zone);

  /// Explains what the email is used for.
  ///
  /// In en, this message translates to:
  /// **'Your email is used only to sign in. FlowWave sends no marketing.'**
  String get registerEmailNote;

  /// Failure: offline or timeout.
  ///
  /// In en, this message translates to:
  /// **'No connection to the FlowWave server. Your data is safe on this phone; try again later.'**
  String get errorNetwork;

  /// Failure: no API base URL.
  ///
  /// In en, this message translates to:
  /// **'This version of FlowWave has no server configured.'**
  String get errorNotConfigured;

  /// Failure: no session.
  ///
  /// In en, this message translates to:
  /// **'You are signed out. Sign in to continue syncing.'**
  String get errorNotSignedIn;

  /// Failure: wrong sign-in data.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errorInvalidCredentials;

  /// Failure: session revoked or expired.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Please sign in again.'**
  String get errorSessionEnded;

  /// Failure: re-authentication failed.
  ///
  /// In en, this message translates to:
  /// **'The password is incorrect.'**
  String get errorWrongPassword;

  /// Failure: forbidden.
  ///
  /// In en, this message translates to:
  /// **'This action is not allowed.'**
  String get errorForbidden;

  /// Failure: consent missing.
  ///
  /// In en, this message translates to:
  /// **'This needs your consent first.'**
  String get errorConsentRequired;

  /// Failure: invalid input.
  ///
  /// In en, this message translates to:
  /// **'Some details are not valid. Check them and try again.'**
  String get errorValidation;

  /// Failure: email already registered.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailTaken;

  /// Failure: conflict.
  ///
  /// In en, this message translates to:
  /// **'This change conflicts with data on the server.'**
  String get errorConflict;

  /// Failure: not found.
  ///
  /// In en, this message translates to:
  /// **'This could not be found.'**
  String get errorNotFound;

  /// Failure: rate limited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get errorRateLimited;

  /// Failure: server error.
  ///
  /// In en, this message translates to:
  /// **'The server had a problem. Try again later.'**
  String get errorServer;

  /// Failure: local database.
  ///
  /// In en, this message translates to:
  /// **'Data on this phone could not be saved.'**
  String get errorStorage;

  /// Failure: unknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnknown;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get navCheckIn;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get navTimeline;

  /// Bottom navigation tab.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// Tooltip and screen reader label of the settings button.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// Label on placeholder screens.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later version'**
  String get comingLater;

  /// Today placeholder text.
  ///
  /// In en, this message translates to:
  /// **'Your day at a glance will appear here: your check-ins and an estimate of your energy and focus rhythm, with the reasons behind it.'**
  String get todayPlaceholder;

  /// Check-in placeholder text.
  ///
  /// In en, this message translates to:
  /// **'Here you will record how your energy, focus and mood feel right now, in a few taps.'**
  String get checkInPlaceholder;

  /// Timeline placeholder text.
  ///
  /// In en, this message translates to:
  /// **'Your check-ins and synced data will appear here in order, at the local time where they happened.'**
  String get timelinePlaceholder;

  /// Insights placeholder text.
  ///
  /// In en, this message translates to:
  /// **'Patterns in your rhythm will appear here once there is enough data, always with the factors they are based on.'**
  String get insightsPlaceholder;

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Theme setting label.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme follows the phone.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Language setting label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language follows the phone.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// English, written in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Polish, written in Polish.
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get languagePolish;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// Account state.
  ///
  /// In en, this message translates to:
  /// **'Signed in. Your data syncs when you are online.'**
  String get accountSignedIn;

  /// Account state.
  ///
  /// In en, this message translates to:
  /// **'Not signed in. Your data is stored only on this phone.'**
  String get accountSignedOut;

  /// Opens sign-in from settings.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// Opens registration from settings.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountCreate;

  /// Signs out this device.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// Signs out every device.
  ///
  /// In en, this message translates to:
  /// **'Sign out on all devices'**
  String get accountSignOutAll;

  /// Sign-out confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutDialogTitle;

  /// Sign-out confirmation body.
  ///
  /// In en, this message translates to:
  /// **'Signing out removes your account data from this phone. Your preferences stay.'**
  String get signOutDialogBody;

  /// Warning about unsynced changes at sign-out.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change has not been uploaded yet and will be lost.} other{{count} changes have not been uploaded yet and will be lost.}}'**
  String signOutPendingWarning(int count);

  /// Opens the data and privacy screen.
  ///
  /// In en, this message translates to:
  /// **'Data and privacy'**
  String get settingsDataPrivacy;

  /// Subtitle of the data and privacy entry.
  ///
  /// In en, this message translates to:
  /// **'Consents, sync and deleting data'**
  String get settingsDataPrivacySubtitle;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Title of the data and privacy screen.
  ///
  /// In en, this message translates to:
  /// **'Data and privacy'**
  String get dataPrivacyTitle;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Consents'**
  String get dataPrivacyConsents;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get dataPrivacyOnPhone;

  /// Explains local storage.
  ///
  /// In en, this message translates to:
  /// **'FlowWave\'s data is stored encrypted on this phone and is excluded from cloud backups.'**
  String get dataPrivacyOnPhoneBody;

  /// Number of stored consent decisions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No consent decisions stored} =1{1 consent decision stored} other{{count} consent decisions stored}}'**
  String dataPrivacyConsentCount(int count);

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get dataPrivacySync;

  /// Sync state when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sync is off. Sign in to back up your data.'**
  String get syncOff;

  /// Number of queued changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Everything is uploaded.} =1{1 change is waiting to upload.} other{{count} changes are waiting to upload.}}'**
  String syncPending(int count);

  /// Number of refused changes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The server refused 1 change. It will not be retried.} other{The server refused {count} changes. They will not be retried.}}'**
  String syncRejected(int count);

  /// Starts sync.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// Sync result.
  ///
  /// In en, this message translates to:
  /// **'Sync finished.'**
  String get syncDone;

  /// Sync result.
  ///
  /// In en, this message translates to:
  /// **'Could not sync right now. FlowWave will try again later.'**
  String get syncWillRetry;

  /// Action and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete data on this phone'**
  String get deleteLocalTitle;

  /// Explains local deletion when signed in.
  ///
  /// In en, this message translates to:
  /// **'Removes everything FlowWave stored on this phone and signs you out. Your account and its synced data stay on the server.'**
  String get deleteLocalBodySignedIn;

  /// Explains local deletion when signed out.
  ///
  /// In en, this message translates to:
  /// **'Removes everything FlowWave stored on this phone. This cannot be undone.'**
  String get deleteLocalBodySignedOut;

  /// Action and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// Explains account deletion.
  ///
  /// In en, this message translates to:
  /// **'Deletes your account and all its data on the server at once, then removes it from this phone. This cannot be undone.'**
  String get deleteAccountBody;

  /// Asks for the password before deletion.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm.'**
  String get deleteAccountPasswordPrompt;

  /// Confirmation after deletion.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get deleteAccountDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
