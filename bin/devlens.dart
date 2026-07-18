import 'package:devlens/cli/command_runner.dart';
import 'dart:io';

void main(List<String> arguments) async {
  final runner = DevLensCommandRunner();
  try {
    await runner.run(arguments);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
