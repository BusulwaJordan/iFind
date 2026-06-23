import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ifind/core/constants/api_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    required this.releaseNotes,
    required this.required,
  });

  final String versionName;
  final int versionCode;
  final String apkUrl;
  final String releaseNotes;
  final bool required;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      versionName: json['versionName'] as String? ?? '',
      versionCode: json['versionCode'] as int? ?? 0,
      apkUrl: json['apkUrl'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      required: json['required'] as bool? ?? false,
    );
  }
}

class AppUpdateService {
  const AppUpdateService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<AppUpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
    final client = _client ?? http.Client();

    try {
      final response = await client.get(
        Uri.parse(ApiConstants.appUpdateManifestUrl),
      );
      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final updateInfo = AppUpdateInfo.fromJson(json);
      if (updateInfo.apkUrl.isEmpty ||
          updateInfo.versionCode <= currentVersionCode) {
        return null;
      }

      return updateInfo;
    } catch (_) {
      return null;
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}
