// lib/utils/iframe.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:html' as html;

class Iframe extends StatelessWidget {
  final String src;
  final String style;

  const Iframe({Key? key, required this.src, this.style = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate a unique ID for this iframe
    final String viewId = 'iframe_view_${DateTime.now().millisecondsSinceEpoch}';

    // Register the iframe view
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = src
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';

        if (style.isNotEmpty) {
          iframe.style.cssText = style;
        }

        return iframe;
      },
    );

    return HtmlElementView(
      viewType: viewId,
    );
  }
}