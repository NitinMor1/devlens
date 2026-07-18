import 'package:args/command_runner.dart';
import 'package:devlens/cli/commands/scan_command.dart';

class DevLensCommandRunner extends CommandRunner<void> {
  DevLensCommandRunner()
      : super(
          'devlens',
          'Flutter Dependency Explorer - A visual developer tool for Flutter codebases.',
        ) {
    addCommand(ScanCommand());
  }
}
