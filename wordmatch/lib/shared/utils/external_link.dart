import 'package:flutter/material.dart';

import 'package:wordmatch/shared/widgets/in_app_browser_screen.dart';

/// 在应用内 WebView 打开外部链接（GitHub 仓库 / 资讯原文等）。
/// 仅支持 http(s)；链接无效时弹 SnackBar 提示。
Future<void> openInAppBrowser(
  BuildContext context,
  String url, {
  String? title,
}) async {
  final uri = Uri.tryParse(url.trim());
  final valid = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  if (!valid) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('无法打开链接')),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => InAppBrowserScreen(url: uri.toString(), title: title),
    ),
  );
}
