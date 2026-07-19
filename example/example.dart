import 'package:devlens/cli/command_runner.dart';

/// This is an example of how to invoke the devlens scanner programmatically.
/// 
/// You can run this file directly using `dart run example/example.dart`
void main() async {
  // Initialize the CLI runner
  final runner = DevLensCommandRunner();
  
  // Run the 'scan' command on the current directory
  // This behaves identically to running `devlens scan --path .`
  print('Running devlens scan programmatically...');
  await runner.run(['scan', '--path', '.']);
}
