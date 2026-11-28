import '../../l10n/generated/app_localizations.dart';
import '../core/errors/app_failure.dart';

/// The localized message for [failure]. Server messages are never shown.
String failureMessage(AppLocalizations l10n, AppFailure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorNetwork,
      NotConfiguredFailure() => l10n.errorNotConfigured,
      NotSignedInFailure(reason: null) => l10n.errorNotSignedIn,
      NotSignedInFailure() => l10n.errorSessionEnded,
      UnauthorizedFailure(reason: 'invalid_credentials') =>
        l10n.errorInvalidCredentials,
      UnauthorizedFailure() => l10n.errorSessionEnded,
      ForbiddenFailure(reason: 'reauthentication_failed') =>
        l10n.errorWrongPassword,
      ForbiddenFailure() => l10n.errorForbidden,
      ConsentRequiredFailure() => l10n.errorConsentRequired,
      ValidationFailure() => l10n.errorValidation,
      ConflictFailure(field: 'email') => l10n.errorEmailTaken,
      ConflictFailure() => l10n.errorConflict,
      NotFoundFailure() => l10n.errorNotFound,
      RateLimitedFailure() => l10n.errorRateLimited,
      ServerFailure() => l10n.errorServer,
      StorageFailure() => l10n.errorStorage,
      UnknownFailure() => l10n.errorUnknown,
    };
