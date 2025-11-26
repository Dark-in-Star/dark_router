# dark_router

[![Pub Version](https://img.shields.io/pub/v/dark_router.svg)](https://pub.dev/packages/dark_router)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.3.0-blue.svg)]()
[![Build Runner](https://img.shields.io/badge/build_runner-compatible-success.svg)]()

A lightweight extension package for **go_router** that adds **automatic query parameter generation**, **callback support**, and **payload encoding utilities** using `source_gen`.

This package allows you to annotate your classes and automatically generate:

- Strongly typed Query Parameter → Model transformation  
- Model → Query Parameter serialization  
- Encoded payload field (`ed`) support  
- Automatic callback ID storage + execution  
- Seamless integration with `json_serializable`  
- Clean output merged into the standard `*.g.dart` file  

Perfect for apps using `go_router` deep links and dynamic routing.

---

## ✨ Features

- **`@QueryParamsSerializable()`**  
  Marks a class that should generate query-parameter helpers.

- **`@CallbackIdField()`**  
  Marks a `String?` field that stores an auto-generated callback ID.

- Automatically generates:
  ```dart
  toQueryParameters();
  MyParams.fromQueryParameters(Map<String, String>);
  hasCallback;
  setCallback(Function);
  executeCallback();
  ```
* Supports JSON payload encoding via `ed` field.

* Fully compatible with:

  ```
  json_serializable
  source_gen|combining_builder
  build_runner
  ```

---

## 🚀 Installation

Add to your **pubspec.yaml**:

```yaml
dependencies:
  dark_router: ^0.0.1

dev_dependencies:
  json_serializable: ^6.8.0
  build_runner: ^2.4.0
```

If you use a custom build.yaml:

```yaml
targets:
  $default:
    builders:
      json_serializable:json_serializable:
        enabled: true
      dark_router|query_params:
        enabled: true
```

---

## 📦 Usage Example

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:dark_router/dark_router.dart';

part 'example_query_params.g.dart';

@JsonSerializable()
@QueryParamsSerializable()
class MyQueryParams {
  String? id;
  String? type;

  @CallbackIdField()
  String? cb;

  MyQueryParams({this.id, this.type, this.cb});

  factory MyQueryParams.fromJson(Map<String, dynamic> json) =>
      _$MyQueryParamsFromJson(json);

  Map<String, dynamic> toJson() => _$MyQueryParamsToJson(this);

  static String? encodePayload(Map<String, dynamic> payload) {
    return null; // optional custom encoding
  }

  static Map<String, dynamic>? decodePayload(String? ed) {
    return null; // optional custom decoding
  }
}
```

Then run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Output appears inside:

```
example_query_params.g.dart
```

---

## 🧠 Generated API Overview

Your annotated class automatically gets:

```dart
Map<String, String> toQueryParameters();
static MyQueryParams fromQueryParameters(Map<String, String>);

bool get hasCallback;
void setCallback(Function fn);
Future<void> executeCallback([List<dynamic>? args]);
```

Callback registry is maintained in-memory per model type.

---

## 🧩 Why this package?

`go_router` is great, but manually encoding/decoding query parameters is:

* Repetitive  
* Error-prone  
* Hard to maintain  
* Poorly typed  

`dark_router` generates a clean, type-safe conversion layer, improves DX, and keeps routing logic clean.

---

## 📂 Example Project

See a fully working example under:

```
example/
```

Run it with:

```bash
cd example
dart run build_runner build --delete-conflicting-outputs
```

---

## 📝 License

MIT © 2025 darkinstar

---

## 🙌 Contribution

Issues and pull requests are welcome!  
If you’re using this package in production or want more features, open an issue on GitHub.