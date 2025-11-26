import 'package:dark_router/query_params_builder/query_params_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'example_query_params.g.dart';

@JsonSerializable()
@QueryParamsSerializable()
class ExampleQueryParams {
  String? id;
  String? type;

  @CallbackIdField()
  String? cb; // example callback id field

  ExampleQueryParams({this.id, this.type, this.cb});

  factory ExampleQueryParams.fromJson(Map<String, dynamic> json) =>
      _$ExampleQueryParamsFromJson(json);

  Map<String, dynamic> toJson() => _$ExampleQueryParamsToJson(this);

  // encodePayload/decodePayload must exist for your generated code:
  static String? encodePayload(Map<String, dynamic> payload) {
    // simple example: no encoded payload
    return null;
  }

  static Map<String, dynamic>? decodePayload(String? ed) {
    // corresponding decode
    return null;
  }
}
