class QueryParamsSerializable {
  const QueryParamsSerializable();
}

/// Marks a String? field that will store the callback ID
/// for an in-memory callback registry generated in the extension.
class CallbackIdField {
  const CallbackIdField();
}

/// Marks a `String?` field on the QueryParams class that will carry the
/// encoded payload (e.g. base64 of nested/complex fields).
///
/// This field is managed by the generator and should NOT be set or read
/// manually in client code. Use:
///
///   - `toQueryParameters()`
///   - `fromQueryParameters()`
///
/// for the correct behavior.
///
/// Example:
/// ```dart
/// @QueryParamsSerializable()
/// class QueryParams {
///   String? type;
///   String? id;
///
///   @EncodeValueField()
///   String? ed; // or `payload`, or any other name you like
/// }
/// ```
class EncodeValueField {
  const EncodeValueField();
}