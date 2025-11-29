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

    // -------------------------------------------------------------------------
    // 1) Simple keys = all String fields (type, id, cb, token, ed, ...)
    // -------------------------------------------------------------------------
    final simpleKeys = fields
        .where((f) => f.type.isDartCoreString)
        .map((f) => f.name)
        .toList();

    // -------------------------------------------------------------------------
    // 2) Find encoded-payload field:
    //    - Prefer the one annotated with @EncodeValueField
    //    - Fallback to a String field named "ed" (backward compatible)
    // -------------------------------------------------------------------------
    FieldElement? encodeField;

    // First: look for @EncodeValueField
    for (final f in fields) {
      final hasEncodeAnno = const TypeChecker.fromRuntime(EncodeValueField)
          .hasAnnotationOfExact(f);
      if (hasEncodeAnno) {
        encodeField = f;
        break;
      }
    }

    // Fallback: look for "ed" String? field
    FieldElement? tryFindEdField(List<FieldElement> fields) {
      for (final f in fields) {
        if (f.name == 'ed' && f.type.isDartCoreString) {
          return f;
        }
      }
      return null;
    }

    encodeField ??= tryFindEdField(fields);

    final encodeFieldHasAnnotation = encodeField != null &&
        const TypeChecker.fromRuntime(EncodeValueField)
            .hasAnnotationOfExact(encodeField);

    // If annotated with @EncodeValueField, enforce String? type
    if (encodeFieldHasAnnotation && !encodeField.type.isDartCoreString) {
      throw InvalidGenerationSourceError(
        '@EncodeValueField can only be used on String? fields.',
        element: encodeField,
      );
    }

    final encodeFieldName = encodeField?.name;
    final simpleKeysLiteral = simpleKeys.map((k) => "'$k'").join(', ');

    // -------------------------------------------------------------------------
    // 3) Find callback field via @CallbackIdField
    // -------------------------------------------------------------------------
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
    final callbackSection = (callbackFieldName != null)
        ? _generateCallbackSection(className, callbackFieldName)
        : '';

    // -------------------------------------------------------------------------
    // 4) Generate extension
    // -------------------------------------------------------------------------
    return '''
// GENERATED QUERY PARAMS EXTENSION - DO NOT MODIFY BY HAND

extension ${className}QueryParamsExt on $className {
  static const _simpleKeys = <String>{$simpleKeysLiteral};

  /// Convert this instance to URL query parameters.
  ///
  /// All primitive String fields (type, id, token, etc.) are passed directly
  /// as query params.
  ///
  /// All remaining fields (integers, booleans, objects, nested models, etc.)
  /// are collected into a payload map and encoded into the field marked with
  /// @EncodeValueField (or "ed" by default).
  Map<String, String> toQueryParameters() {
    final full = _\$${className}ToJson(this);

    // Payload = everything except simple keys (type, id, token, ed, ...)
    final payload = Map<String, dynamic>.from(full)
      ..removeWhere((key, _) => _simpleKeys.contains(key));

    // Encode payload using static helper on the class.
    final encoded = $className.encodePayload(payload);

    final result = <String, String>{};
    for (final key in _simpleKeys) {
      Object? value;

      // If an encoded field is configured, always override its value from the
      // encoded payload and ignore any manual value set by client code.
      ${encodeFieldName != null ? '''
      if (key == '$encodeFieldName') {
        value = encoded;
      } else {
        value = full[key];
      }
      ''' : '''
      value = full[key];
      '''}

      if (value != null) {
        result[key] = value.toString();
      }
    }
    return result;
  }

  /// Create an instance from URL query parameters.
  ///
  /// Steps:
  /// 1) Copy query map into a mutable JSON map.
  /// 2) Extract the encoded string from the @EncodeValueField (or "ed").
  /// 3) Decode payload using static helper on the class.
  /// 4) Merge decoded payload into the JSON map.
  /// 5) Remove the encoded field from JSON so it remains "internal only".
  /// 6) Delegate to the generated fromJson constructor.
  static $className fromQueryParameters(Map<String, String> query) {
    final baseJson = <String, dynamic>{...query};

    ${encodeFieldName != null ? '''
    final encoded = baseJson['$encodeFieldName'] as String?;
    final payload = $className.decodePayload(encoded);
    if (payload != null) {
      baseJson.addAll(payload);
    }
    // Do not expose raw encoded string as a JSON field – treat it as internal.
    baseJson.remove('$encodeFieldName');
    ''' : '''
    // No encoded field configured; just decode with null by default.
    final payload = $className.decodePayload(null);
    if (payload != null) {
      baseJson.addAll(payload);
    }
    '''}

    return _\$${className}FromJson(baseJson);
  }

$callbackSection
}
''';
  }

  String _generateCallbackSection(String className, String fieldName) {
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

  /// Registers a callback function, saves its ID into `$fieldName`,
  /// and returns the same instance to allow chaining.
  $className setCallback(Function fn) {
    final id = _\$${className}GenerateCallbackId();
    _\$${className}Callbacks[id] = fn;
    $fieldName = id;
    return this;
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
