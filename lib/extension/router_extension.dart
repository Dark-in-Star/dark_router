import 'package:dark_router/config/route_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ---------------------------------------------------------------------------
/// DarkRoute
/// ---------------------------------------------------------------------------
///
/// Provides factory helpers to convert your custom route configuration classes
/// (`SimpleRouteConfig`, `AsyncRouteConfig`) into ready-to-use GoRouter `GoRoute`
/// instances.
///
/// WHY THIS EXISTS
/// --------------
/// Normally, GoRouter route definitions look like:
///
/// ```dart
/// GoRoute(
///   name: 'home',
///   path: '/home',
///   builder: (_, state) => HomeScreen(),
/// );
/// ```
///
/// But once your app grows, you want:
/// - strict consistency
/// - typed data passing
/// - centralized parsing of params
/// - reusable definitions
///
/// So instead of manually writing constructors for every route, you write:
///
/// ```dart
/// final home = DarkRoute.buildConfig(config: HomeRouteConfig());
/// final course = DarkRoute.futureBuildConfig(config: CourseRouteConfig());
/// ```
///
/// This makes your routing layer:
/// - predictable
/// - type-safe
/// - easy to maintain
/// - easily shared across projects
extension DarkRoute on GoRoute {
  // ---------------------------------------------------------------------------
  // SIMPLE ROUTE BUILDER
  // ---------------------------------------------------------------------------
  //
  /// Converts a [SimpleRouteConfig] into a standard [GoRoute].
  ///
  /// WHEN TO USE:
  /// - Screens that do NOT need asynchronous fetching
  /// - Screens that depend only on path/query params or static data
  ///
  /// EXAMPLE:
  /// ```dart
  /// class HomeRouteConfig extends SimpleRouteConfig<HomeScreen> {
  ///   @override
  ///   String get name => 'home';
  ///
  ///   @override
  ///   HomeScreen routeConfig(GoRouterState state) => HomeScreen();
  /// }
  ///
  /// DarkRoute.buildConfig(config: HomeRouteConfig());
  /// ```
  static GoRoute buildConfig<TRouteData extends Widget>({
    required SimpleRouteConfig<TRouteData> config,
  }) {
    return GoRoute(
      path: config.path,
      name: config.name,
      builder: (_, state) => config.routeConfig(state),
    );
  }

  // ---------------------------------------------------------------------------
  // ASYNC ROUTE BUILDER (FUTURE-BUILDER)
  // ---------------------------------------------------------------------------
  //
  /// Converts an [AsyncRouteConfig] into a GoRoute that:
  /// - Parses state into route-specific data
  /// - Extracts an ID via [getFetchingId]
  /// - Fetches async data via [fetch]
  /// - Shows loading widget until fetch completes
  /// - Shows error widget if fetch fails
  ///
  /// WHEN TO USE:
  /// - Screens that require asynchronous API/data fetching
  ///   e.g., course details, profile page, event detail page
  ///
  /// EXAMPLE:
  /// ```dart
  /// class CourseDetailsRoute
  ///     extends AsyncRouteConfig<CourseDetailsScreen, Course> {
  ///
  ///   String get name => 'courseDetails';
  ///   String get path => '/course/:id';
  ///
  ///   CourseDetailsScreen routeConfig(GoRouterState state) =>
  ///     CourseDetailsScreen(id: state.pathParameters['id']!);
  ///
  ///   String getFetchingId(GoRouterState state) =>
  ///     state.pathParameters['id']!;
  ///
  ///   Future<Course?> fetch(String id) => api.getCourse(id);
  ///
  ///   Widget buildScreen(CourseDetailsScreen data, {Course? fetched}) =>
  ///     CourseDetailsScreen(id: data.id, initialCourse: fetched);
  ///
  ///   Widget get loadingWidget => const Loading();
  ///
  ///   Widget buildError(snapshot) => ErrorScreen();
  /// }
  ///
  /// DarkRoute.futureBuildConfig(config: CourseDetailsRoute());
  /// ```
  static GoRoute futureBuildConfig<TRouteData extends Widget, TFetchData>({
    required AsyncRouteConfig<TRouteData, TFetchData> config,
  }) {
    return GoRoute(
      path: config.path,
      name: config.name,
      builder: (_, state) {
        // Build initial UI data (parsed from URL)
        final routeData = config.routeConfig(state);

        // If fetching is unnecessary (overrideable), return directly
        if (!config.shouldFetch(routeData)) {
          return config.buildScreen(routeData);
        }

        // Otherwise fetch async data
        final id = config.getFetchingId(state);

        return FutureBuilder<TFetchData?>(
          future: config.fetch(id),
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return config.loadingWidget;
            }

            if (snapshot.hasData && snapshot.data != null) {
              return config.buildScreen(
                routeData,
                fetched: snapshot.data as TFetchData,
              );
            }

            return config.buildError(snapshot);
          },
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// DarkStatefulShellRoute
/// ---------------------------------------------------------------------------
///
/// Helper to convert a `ShellIndexedStackConfig` into a full
/// `StatefulShellRoute.indexedStack`.
///
/// WHY YOU NEED THIS
/// -----------------
/// GoRouter's multi-branch layout for bottom navigation looks like this:
///
/// ```dart
/// StatefulShellRoute.indexedStack(
///   branches: [...],
///   builder: (context, state, navShell) {
///     return Scaffold(...);
///   }
/// );
/// ```
///
/// Instead of writing this by hand for each app:
///
/// - You define a clean config class
/// - You pass it to this helper
///
/// This keeps your routing layer minimal and all shell logic centralized.
///
/// EXAMPLE:
///
/// ```dart
/// class MainShellConfig extends ShellIndexedStackConfig<MainShellWidget> {
///   List<StatefulShellBranch> get branches => [...];
///
///   MainShellWidget routeConfig(GoRouterState state) =>
///     MainShellWidget(currentIndex: ...);
/// }
///
/// final router = GoRouter(
///   routes: [
///     DarkStatefulShellRoute.indexedStackConfig(config: MainShellConfig()),
///   ],
/// );
/// ```
extension DarkStatefulShellRoute on StatefulShellRoute {
  /// Build a complete [StatefulShellRoute.indexedStack] from a
  /// [ShellIndexedStackConfig].
  static StatefulShellRoute indexedStackConfig<TRouteData extends Widget>({
    required ShellIndexedStackConfig<TRouteData> config,
  }) {
    return StatefulShellRoute.indexedStack(
      branches: config.branches,
      builder: (_, state, __) => config.routeConfig(state),
    );
  }
}
