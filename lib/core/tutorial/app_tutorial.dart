import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ifind/core/constants/app_colors.dart';
import 'package:ifind/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tutorialProvider = Provider<AppTutorialService>((ref) {
  return AppTutorialService(ref.watch(sharedPreferencesProvider));
});

class AppTutorialService {
  final SharedPreferences _prefs;

  AppTutorialService(this._prefs);

  static const customerHomeKey = 'tutorial_customer_home_complete';
  static const businessSetupKey = 'tutorial_business_setup_complete';
  static const pendingBusinessSetupKey = 'tutorial_business_setup_pending';

  bool shouldShow(String key) => !(_prefs.getBool(key) ?? false);

  Future<void> complete(String key) => _prefs.setBool(key, true);

  Future<void> markPending(String key) => _prefs.setBool(key, true);

  Future<bool> consumePending(String key) async {
    final pending = _prefs.getBool(key) ?? false;
    if (pending) {
      await _prefs.setBool(key, false);
    }
    return pending;
  }
}

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final String action;

  const TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
  });
}

Future<void> showAppTutorial({
  required BuildContext context,
  required String storageKey,
  required List<TutorialStep> steps,
  required WidgetRef ref,
}) async {
  if (steps.isEmpty) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _TutorialDialog(steps: steps),
  );

  await ref.read(tutorialProvider).complete(storageKey);
}

class _TutorialDialog extends StatefulWidget {
  final List<TutorialStep> steps;

  const _TutorialDialog({required this.steps});

  @override
  State<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<_TutorialDialog> {
  int _index = 0;

  bool get _isLast => _index == widget.steps.length - 1;

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final width = MediaQuery.of(context).size.width;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width > 520 ? 460 : width),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(step.icon, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Step ${_index + 1} of ${widget.steps.length}',
                      style: GoogleFonts.outfit(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _close,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Skip tutorial',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                step.title,
                style: GoogleFonts.outfit(
                  color: AppColors.darkText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step.description,
                style: GoogleFonts.outfit(
                  color: AppColors.lightText,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        color: AppColors.deepGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.action,
                        style: GoogleFonts.outfit(
                          color: AppColors.deepGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  TextButton(
                    onPressed: _close,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.outfit(color: AppColors.lightText),
                    ),
                  ),
                  const Spacer(),
                  ...List.generate(
                    widget.steps.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: i == _index ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: i == _index
                            ? AppColors.primaryGreen
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_isLast) {
                        _close();
                      } else {
                        setState(() => _index++);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_isLast ? 'Done' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
