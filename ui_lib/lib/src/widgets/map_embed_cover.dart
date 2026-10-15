import 'package:flutter/widgets.dart';

/// The routes a widget at [context] sits in, innermost first: its page, then
/// the page of each navigator around that one (a shell's page), up to the
/// root.
///
/// A dialog opened with `showShadDialog` goes on the root navigator, while
/// the app's pages sit in the nested navigators of its shells: the page
/// nearest a map stays current while such a dialog is open, so every route
/// around it has to be asked.
List<Route<dynamic>> routesAround(BuildContext context) {
  final routes = <Route<dynamic>>[];
  BuildContext? ctx = context;
  while (ctx != null) {
    final route = ModalRoute.of(ctx);
    if (route == null) break;
    routes.add(route);
    ctx = route.navigator?.context;
  }
  return routes;
}

/// Whether anything — a dialog, a sheet, another page — is open over any of
/// [routes].
bool anyCovered(List<Route<dynamic>> routes) =>
    routes.any((route) => !route.isCurrent);
