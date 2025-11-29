import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ---------------------------------------------------------------------------
/// Dark Router: Base Route Configs
///
/// This file defines 3 base abstractions that standardize how we configure
/// GoRouter routes in a type-safe way:
///
/// 1. [SimpleRouteConfig]
///    - For normal pages that don't need async fetching.
///    - Example: static screens, detail pages where all data is passed via
///      query params / extra.
///
/// 2. [AsyncRouteConfig]
///    - For pages that require async data loading (fetch by ID, etc.).
///    - Example: `/product/:id` that must fetch the product from API/DB.
///
/// 3. [ShellIndexedStackConfig]
///    - For building a `StatefulShellRoute.indexedStack` shell with multiple
///      tabs/branches.
///    - Example: main bottom navigation container with 3–5 tabs.
///
/// These abstractions:
/// - Keep route registration consistent across the app.
/// - Let you define routes as typed configs instead of ad-hoc functions.
/// - Make it easier to share routing patterns across projects.
///
/// See usage examples at the bottom of this file.
/// ---------------------------------------------------------------------------

/// ---------------------------------------------------------------------------
/// 1. SimpleRouteConfig
/// ---------------------------------------------------------------------------
///
/// Use this for routes that:
/// - Do NOT need async data fetching.
/// - Only depend on [GoRouterState] (path params, query params, extra, etc.).
///
/// Typical usage:
///
/// ```dart
/// class HomeRouteConfig extends SimpleRouteConfig<HomeScreen> {
///   const HomeRouteConfig();
///
///   @override
///   String get name => 'home';
///
///   @override
///   HomeScreen routeConfig(GoRouterState state) {
///     // You can parse query params/extra here if needed.
///     return const HomeScreen();
///   }
/// }
///
/// // When registering routes with GoRouter:
/// final homeConfig = HomeRouteConfig();
///
/// GoRoute(
///   name: homeConfig.name,
///   path: homeConfig.path,
///   builder: (context, state) => homeConfig.routeConfig(state),
/// );
/// ```
abstract class SimpleRouteConfig<TRouteData extends Widget> {
  const SimpleRouteConfig();

  /// A unique name for this route within GoRouter.
  ///
  /// This is used when calling:
  /// ```dart
  /// context.goNamed(name, params: {...}, queryParameters: {...});
  /// ```
  String get name;

  /// Path of the route.
  ///
  /// By default, this uses a / prefix and [name]
  /// to a path string, but you can override this if you want a custom path.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// String get path => '/product/:id';
  /// ```
  String get path => "/${name}";

  /// Convert a [GoRouterState] into the final widget for this route.
  ///
  /// This is where you:
  /// - Read path params: `state.pathParameters['id']`
  /// - Read query params: `state.uri.queryParameters`
  /// - Read state.extra: `state.extra as MyData?`
  ///
  /// and then build your `TRouteData` widget.
  TRouteData routeConfig(GoRouterState state);
}

/// ---------------------------------------------------------------------------
/// 2. AsyncRouteConfig
/// ---------------------------------------------------------------------------
///
/// Use this for routes that must:
/// - Fetch data asynchronously before building the final screen.
/// - Typically use an `id` from the URL or query params.
///
/// Most common pattern:
/// - Path: `/item/:id`
/// - Extract ID in [getFetchingId]
/// - Fetch via API/DB in [fetch]
/// - Build UI using [buildScreen]
///
/// Example:
///
/// ```dart
/// class ProductDetailsRouteConfig
///     extends AsyncRouteConfig<ProductDetailsScreen, product> {
///   const ProductDetailsRouteConfig();
///
///   @override
///   String get name => 'ProductDetails';
///
///   @override
///   ProductDetailsScreen routeConfig(GoRouterState state) {
///     final id = state.pathParameters['id']!;
///     return ProductDetailsScreen(id: id);
///   }
///
///   @override
///   String getFetchingId(GoRouterState state) => state.pathParameters['id']!;
///
///   @override
///   Future<product?> fetch(String id) => productRepository.getproductById(id);
///
///   @override
///   Widget buildScreen(ProductDetailsScreen data, {product? fetched}) {
///     return ProductDetailsScreen(
///       id: data.id,
///       initialproduct: fetched,
///     );
///   }
///
///   @override
///   Widget get loadingWidget => const Center(child: CircularProgressIndicator());
///
///   @override
///   Widget buildError(AsyncSnapshot<product?> snapshot) {
///     return ErrorScreen(error: snapshot.error);
///   }
/// }
///
/// // When registering with GoRouter:
/// final productConfig = ProductDetailsRouteConfig();
///
/// GoRoute(
///   name: productConfig.name,
///   path: productConfig.path,
///   builder: (context, state) {
///     final routeData = productConfig.routeConfig(state);
///     if (!productConfig.shouldFetch(routeData)) {
///       // If no fetch required, directly build screen without async call.
///       return productConfig.buildScreen(routeData);
///     }
///
///     final id = productConfig.getFetchingId(state);
///
///     return FutureBuilder<product?>(
///       future: productConfig.fetch(id),
///       builder: (context, snapshot) {
///         if (snapshot.connectionState != ConnectionState.done) {
///           return productConfig.loadingWidget;
///         }
///         if (!snapshot.hasData) {
///           return productConfig.buildError(snapshot);
///         }
///         return productConfig.buildScreen(
///           routeData,
///           fetched: snapshot.data,
///         );
///       },
///     );
///   },
/// );
/// ```
abstract class AsyncRouteConfig<TRouteData extends Widget, TFetchData> {
  const AsyncRouteConfig();

  /// Unique name for GoRouter.
  String get name;

  /// Path for this route.
  ///
  /// By default, this uses a / prefix and [name]
  /// to a path string, but you can override this if you want a custom path.
  /// ```dart
  /// @override
  /// String get path => '/product/:id';
  /// ```
  String get path => "/${name}";

  /// Convert GoRouterState -> initial route data widget.
  ///
  /// This is where you parse IDs, query params, initial models, etc.
  TRouteData routeConfig(GoRouterState state);

  /// Optional pre-condition before fetching.
  ///
  /// Return `false` to skip `fetch()` and directly call [buildScreen]
  /// with `fetched == null`.
  ///
  /// Example:
  /// - If routeData already contains a fully loaded model, you can skip fetch.
  bool shouldFetch(TRouteData data) => true;

  /// Extract the ID (or key) from [GoRouterState] which will be passed to [fetch].
  ///
  /// Example:
  /// ```dart
  /// @override
  /// String getFetchingId(GoRouterState state) =>
  ///   state.pathParameters['id']!;
  /// ```
  String getFetchingId(GoRouterState state);

  /// Async data fetch method.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<product?> fetch(String id) => api.getproduct(id);
  /// ```
  Future<TFetchData?> fetch(String id);

  /// Final screen builder.
  ///
  /// [data] is the initial `TRouteData` created in [routeConfig].
  /// [fetched] is the data returned from [fetch], or null if:
  /// - `shouldFetch` returned false, or
  /// - `fetch` returned null.
  Widget buildScreen(TRouteData data, {TFetchData? fetched});

  /// Widget displayed while data is being fetched.
  Widget get loadingWidget;

  /// Widget displayed when async fetch fails or returns an error.
  ///
  /// You receive the [AsyncSnapshot] so you can inspect `error` and `stackTrace`.
  Widget buildError(AsyncSnapshot<TFetchData?> snapshot);
}

/// ---------------------------------------------------------------------------
/// 3. ShellIndexedStackConfig
/// ---------------------------------------------------------------------------
///
/// Base config for an `indexedStack` [StatefulShellRoute] in GoRouter.
///
/// Use this for the "main shell" that owns bottom navigation / tabbed layout:
/// - E.g. Home, Explore, Wallet, Profile tabs.
/// - Each tab is a [StatefulShellBranch].
///
/// Example:
///
/// ```dart
/// class MainShellRouteData extends StatelessWidget {
///   final int currentIndex;
///
///   const MainShellRouteData({super.key, required this.currentIndex});
///
///   @override
///   Widget build(BuildContext context) {
///     // Build your Scaffold with BottomNavigationBar using currentIndex
///   }
/// }
///
/// class MainShellConfig extends ShellIndexedStackConfig<MainShellRouteData> {
///   const MainShellConfig();
///
///   @override
///   List<StatefulShellBranch> get branches => [
///     StatefulShellBranch(
///       routes: [
///         GoRoute(
///           path: '/home',
///           name: 'home',
///           builder: (context, state) => const HomeScreen(),
///         ),
///       ],
///     ),
///     StatefulShellBranch(
///       routes: [
///         GoRoute(
///           path: '/profile',
///           name: 'profile',
///           builder: (context, state) => const ProfileScreen(),
///         ),
///       ],
///     ),
///   ];
///
///   @override
///   MainShellRouteData routeConfig(GoRouterState state) {
///     // Determine the current tab index from the route state.
///     final index = state.matchedLocation.contains('/profile') ? 1 : 0;
///     return MainShellRouteData(currentIndex: index);
///   }
/// }
///
/// // GoRouter registration:
/// final shellConfig = MainShellConfig();
///
/// final router = GoRouter(
///   routes: [
///     StatefulShellRoute.indexedStack(
///       branches: shellConfig.branches,
///       builder: (context, state, navigationShell) {
///         final data = shellConfig.routeConfig(state);
///         return data; // your shell widget
///       },
///     ),
///   ],
/// );
/// ```
abstract class ShellIndexedStackConfig<TRouteData extends Widget> {
  const ShellIndexedStackConfig();

  /// All branches (tabs) used by this shell.
  ///
  /// Each [StatefulShellBranch] represents a tab with its own sub-routes.
  List<StatefulShellBranch> get branches;

  /// Map the current [GoRouterState] to a typed route data widget.
  ///
  /// Typically, this is your main shell widget (e.g. Scaffold with BottomNav)
  /// that needs to know:
  /// - Which tab is selected.
  /// - Optional additional state derived from the router.
  TRouteData routeConfig(GoRouterState state);
}
