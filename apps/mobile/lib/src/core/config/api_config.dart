/// Where the FlowWave API runs, set at build time:
///
/// ```sh
/// flutter run --dart-define=FLOWWAVE_API_BASE_URL=http://10.0.2.2:3000/
/// ```
///
/// Empty means no server: the app runs fully offline and never signs in.
const String _apiBaseUrl = String.fromEnvironment('FLOWWAVE_API_BASE_URL');

/// The API base URL, or `null` when none was configured.
Uri? apiBaseUrl() {
  if (_apiBaseUrl.isEmpty) return null;
  final parsed = Uri.tryParse(_apiBaseUrl);
  if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
    throw StateError('FLOWWAVE_API_BASE_URL is not an absolute URL.');
  }
  // Relative paths such as `v1/auth/login` resolve below the base path only
  // when it ends with a slash.
  return parsed.path.endsWith('/')
      ? parsed
      : parsed.replace(path: '${parsed.path}/');
}
