import 'package:flutter/material.dart';

extension WidgetExtensions on Widget {
  Widget constrained({
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
        minWidth: minWidth ?? 0,
        minHeight: minHeight ?? 0,
      ),
      child: this,
    );
  }

  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }

  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) {
    return Flexible(flex: flex, fit: fit, child: this);
  }

  Widget padding(EdgeInsets padding) {
    return Padding(padding: padding, child: this);
  }

  Widget margin(EdgeInsets margin) {
    return Container(margin: margin, child: this);
  }

  Widget center() {
    return Center(child: this);
  }

  Widget safeArea() {
    return SafeArea(child: this);
  }
}