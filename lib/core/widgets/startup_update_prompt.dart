import 'package:flutter/material.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/core/services/app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class StartupUpdatePrompt extends StatefulWidget {
  const StartupUpdatePrompt({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<StartupUpdatePrompt> createState() => _StartupUpdatePromptState();
}

class _StartupUpdatePromptState extends State<StartupUpdatePrompt> {
  static const _skippedVersionCodeKey = 'skipped_update_version_code';

  bool _hasCheckedUpdate = false;
  bool _isShowingPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      await _promptForUpdateIfNeeded();
    });
  }

  Future<void> _promptForUpdateIfNeeded() async {
    if (_hasCheckedUpdate || _isShowingPrompt || !mounted) return;
    _hasCheckedUpdate = true;

    final updateInfo = await const AppUpdateService().checkForUpdate();
    if (!mounted || updateInfo == null) return;

    final prefs = await SharedPreferences.getInstance();
    final skippedVersionCode = prefs.getInt(_skippedVersionCodeKey);
    if (!updateInfo.required &&
        skippedVersionCode != null &&
        skippedVersionCode >= updateInfo.versionCode) {
      return;
    }
    if (!mounted) return;

    _isShowingPrompt = true;
    final result = await showDialog<_UpdatePromptResult>(
      context: context,
      barrierDismissible: !updateInfo.required,
      builder: (context) => PopScope(
        canPop: !updateInfo.required,
        child: AlertDialog(
          icon: const Icon(
            Icons.system_update_alt_rounded,
            color: AppColors.primaryGreen,
          ),
          title: Text('Update ${updateInfo.versionName} available'),
          content: Text(
            updateInfo.releaseNotes.isEmpty
                ? 'A new version of iFind is ready to install.'
                : updateInfo.releaseNotes,
          ),
          actions: [
            if (!updateInfo.required)
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(_UpdatePromptResult.later),
                child: const Text('Later'),
              ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(_UpdatePromptResult.update),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    _isShowingPrompt = false;

    if (!mounted) return;
    if (result == _UpdatePromptResult.update) {
      await launchUrl(
        Uri.parse(updateInfo.apkUrl),
        mode: LaunchMode.externalApplication,
      );
    } else if (!updateInfo.required) {
      await prefs.setInt(_skippedVersionCodeKey, updateInfo.versionCode);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _UpdatePromptResult {
  later,
  update,
}
