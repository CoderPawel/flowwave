/// The signed-in user's account on the server (decision 0014).
abstract interface class AccountRepository {
  /// `DELETE /v1/account`: deletes the account and all its data at once.
  /// Throws `AppFailure.forbidden(reason: 'reauthentication_failed')` when
  /// [password] is wrong.
  Future<void> deleteAccount({required String password});
}
