import 'package:flutter/material.dart';

class CyberScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;

  const CyberScaffold({
    super.key,
    required this.child,
    this.title,
    this.backgroundColor,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.black,
      appBar: appBar ??
          (title != null
              ? AppBar(
                  title: Text(title!),
                  backgroundColor: Colors.black,
                  elevation: 0,
                )
              : null),
      body: SafeArea(
        child: child,
      ),
    );
  }
}