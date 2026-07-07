import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ifind/core/widgets/app_toast.dart';

/// Shares [text] via the platform's native share sheet, falling back to
/// copying it to the clipboard on Windows desktop — the native Windows
/// Share flyout requires an MSIX-packaged app to complete its handshake
/// with the OS, so on a plain Win32 build it opens and immediately closes
/// itself without actually sharing anything.
Future<void> shareText(BuildContext context, String text) async {
  if (!kIsWeb && Platform.isWindows) {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      AppToast.show(
        context,
        'Sharing isn\'t supported on Windows desktop, so this was copied to your clipboard instead.',
        type: ToastType.info,
      );
    }
    return;
  }
  await SharePlus.instance.share(ShareParams(text: text));
}
