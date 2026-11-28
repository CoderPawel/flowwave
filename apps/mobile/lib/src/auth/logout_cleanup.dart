/// Removes one kind of local data at sign-out, for example a cache or a
/// database table. It must be safe to run when there is nothing to remove.
typedef CleanupTask = Future<void> Function();

/// Every feature that stores account data on the phone registers a task
/// here, so signing out leaves none of it behind (decision 0013).
class LogoutCleanup {
  final Map<String, CleanupTask> _tasks = {};

  /// Registers [task] under [name]; registering a name again replaces it.
  void register(String name, CleanupTask task) => _tasks[name] = task;

  void unregister(String name) => _tasks.remove(name);

  Iterable<String> get registeredNames => _tasks.keys;

  /// Runs every task, even when some fail, and returns the names of those
  /// that failed so they can be retried.
  Future<List<String>> runAll() async {
    final failed = <String>[];
    for (final entry in _tasks.entries.toList()) {
      try {
        await entry.value();
      } catch (_) {
        failed.add(entry.key);
      }
    }
    return failed;
  }
}
