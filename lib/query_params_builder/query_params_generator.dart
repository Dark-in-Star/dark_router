// ignore_for_file: always_use_package_imports, depend_on_referenced_packages

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'query_params_annotation.dart';

class QueryParamsGenerator
    extends GeneratorForAnnotation<QueryParamsSerializable> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@QueryParamsSerializable can only be used on classes.',
        element: element,
      );
    }

    final className = element.name;

    final fields =
        element.fields.where((f) => !f.isStatic && !f.isSynthetic).toList();

    // Simple keys = all String fields (type, id, cb, ...)
    final simpleKeys = fields
        .where((f) => f.type.isDartCoreString)
        .map((f) => f.name)
        .toList();

    if (!simpleKeys.contains('ed') &&
        fields.any((f) => f.name == 'ed' && f.type.isDartCoreString)) {
      simpleKeys.add('ed');
    }

    final simpleKeysLiteral = simpleKeys.map((k) => "'$k'").join(', ');

    // Identify the callback-ID field via @CallbackIdField annotation
    FieldElement? callbackField;
    for (final f in fields) {
      final hasCallbackAnno = const TypeChecker.fromRuntime(CallbackIdField)
          .hasAnnotationOfExact(f);
      if (hasCallbackAnno) {
        callbackField = f;
        break;
      }
    }

    final callbackFieldName = callbackField?.name;

    // If we have a callback field, generate registry + helpers
    final callbackSection = (callbackFieldName != null)
        ? _generateCallbackSection(className, callbackFieldName)
        : '';

    return '''
// GENERATED QUERY PARAMS EXTENSION - DO NOT MODIFY BY HAND

extension ${className}QueryParamsExt on $className {
  static const _simpleKeys = <String>{$simpleKeysLiteral};

  /// Convert this instance to URL query parameters.
  Map<String, String> toQueryParameters() {
    final full = _\$${className}ToJson(this);

    // Payload = everything except simple keys (type, id, token, ed, ...)
    final payload = Map<String, dynamic>.from(full)
      ..removeWhere((key, _) => _simpleKeys.contains(key));

    final edValue = $className.encodePayload(payload);

    final result = <String, String>{};
    for (final key in _simpleKeys) {
      Object? value;
      if (key == 'ed') {
        value = edValue ?? full['ed'];
      } else {
        value = full[key];
      }
      if (value != null) {
        result[key] = value.toString();
      }
    }
    return result;
  }

  /// Create an instance from URL query parameters.
  static $className fromQueryParameters(Map<String, String> query) {
    final baseJson = <String, dynamic>{...query};

    final ed = baseJson['ed'] as String?;
    final payload = $className.decodePayload(ed);
    if (payload != null) {
      baseJson.addAll(payload);
    }

    return _\$${className}FromJson(baseJson);
  }

$callbackSection
}
''';
  }

  String _generateCallbackSection(String className, String fieldName) {
    // Generates an in-memory registry only for this extension
    return '''
  // ---------------------------------------------------------------------------
  // Callback registry for field `$fieldName`
  // ---------------------------------------------------------------------------

  static final Map<String, Function> _\$${className}Callbacks = <String, Function>{};
  static int _\$${className}CallbackSeed = 0;

  static String _\$${className}GenerateCallbackId() {
    // simple monotonically-increasing ID; sufficient as an in-memory key
    _\$${className}CallbackSeed++;
    return _\$${className}CallbackSeed.toRadixString(16);
  }

  /// Registers a callback function and saves its ID into `$fieldName`.
  void setCallback(Function fn) {
    final id = _\$${className}GenerateCallbackId();
    _\$${className}Callbacks[id] = fn;
    $fieldName = id;
  }

  /// Executes the callback stored in `$fieldName`, if any, and removes it.
  Future<void> executeCallback([List<dynamic>? args]) async {
    final id = $fieldName;
    if (id == null) return;

    final fn = _\$${className}Callbacks[id];
    if (fn == null) return;

    try {
      await Function.apply(fn, args ?? const []);
    } catch (e, st) {
      // you can replace this with your own logging
      // ignore: avoid_print
      print('Error executing callback ' '\$id: \$e');
      // ignore: avoid_print
      print(st);
    } finally {
      _\$${className}Callbacks.remove(id);
      $fieldName = null;
    }
  }

  /// True if a callback id is present in `$fieldName`.
  bool get hasCallback => $fieldName != null;
''';
  }
}
