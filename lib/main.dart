import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omniscribe_ai/app.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => DictationBloc(),
      child: const OmniScribeApp(),
    ),
  );
}
