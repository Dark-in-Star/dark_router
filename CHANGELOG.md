# Changelog

## 0.0.1

- Initial release.
- Added `@QueryParamsSerializable` annotation.
- Added `@CallbackIdField` annotation.
- Added source_gen builder (`query_params`).
- Query parameter serialization/deserialization.
- Callback registry support.
- Payload encoding via `ed`.
- Example project included.
- MIT License added.


## 0.1.1

### New Features
- **Added `DarkRoute` extension**
  - Provides `buildConfig()` for `SimpleRouteConfig` → `GoRoute` conversion.
  - Provides `futureBuildConfig()` for `AsyncRouteConfig` → async-enabled `GoRoute` with:
    - typed route data parsing
    - async fetching (`fetch`)
    - loading widget
    - error widget
  - Greatly reduces boilerplate when defining routes in GoRouter.
  - Ensures consistent, type-safe routing across large applications.

- **Added `DarkStatefulShellRoute`**
  - Provides `indexedStackConfig()` to convert any `ShellIndexedStackConfig` into a complete:
    - `StatefulShellRoute.indexedStack`
  - Centralizes all shell logic (tabs, bottom navigation, dashboard shells).
  - Keeps route definitions clean and easy to maintain.

---

### Improvements
- Reorganized package structure for clarity and maintainability:
  - `config/` → route configuration abstractions
  - `extension/` → GoRouter helpers
  - `query_params_builder/` → annotations + builder + generator
- Created unified export file **`dark_router.dart`** to simplify importing.
- Updated inline documentation with detailed examples for all route configs.
- Removed outdated files and old builder implementations.
- Cleaned up comments, formatting, and internal code structure.
