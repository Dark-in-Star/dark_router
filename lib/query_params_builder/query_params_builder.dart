// ignore_for_file: depend_on_referenced_packages

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'query_params_generator.dart';

Builder queryParamsBuilder(BuilderOptions options) => SharedPartBuilder(
      [QueryParamsGenerator()],
      'query_params',
    );
