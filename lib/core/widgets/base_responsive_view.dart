import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import '../widgets/responsive_widgets.dart';

abstract class BaseResponsiveView extends StatelessWidget {
  const BaseResponsiveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: SafeArea(
        child: ResponsiveContainer(
          child: buildBody(context),
        ),
      ),
      floatingActionButton: buildFloatingActionButton(context),
      drawer: ResponsiveHelper.isMobile(context) ? buildDrawer(context) : null,
    );
  }

  PreferredSizeWidget? buildAppBar(BuildContext context);
  Widget buildBody(BuildContext context);
  Widget? buildFloatingActionButton(BuildContext context) => null;
  Widget? buildDrawer(BuildContext context) => null;
}

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, constraints, deviceType) {
        return Scaffold(
          appBar: appBar,
          body: SafeArea(
            child: ResponsiveContainer(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
                child: body,
              ),
            ),
          ),
          floatingActionButton: floatingActionButton,
          drawer: deviceType == DeviceType.mobile ? drawer : null,
          endDrawer: endDrawer,
          backgroundColor: backgroundColor,
        );
      },
    );
  }
}

class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding ?? EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      children: children,
    );
  }
}

class ResponsiveFormField extends StatelessWidget {
  final Widget child;
  final String? label;
  final bool isRequired;

  const ResponsiveFormField({
    super.key,
    required this.child,
    this.label,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getResponsivePadding(context) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            RichText(
              text: TextSpan(
                text: label!,
                style: Theme.of(context).textTheme.bodyMedium,
                children: isRequired
                    ? [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}