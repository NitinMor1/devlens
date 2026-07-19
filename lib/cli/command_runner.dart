import 'package:args/command_runner.dart';
import 'package:devlens/cli/commands/scan_command.dart';

/// The main command runner for the devlens CLI.
/// 
/// Provides the entrypoint for executing all subcommands.
class DevLensCommandRunner extends CommandRunner<void> {
  /// Creates a new [DevLensCommandRunner] with the default 'scan' command registered.
  DevLensCommandRunner()
      : super(
          'devlens',
          'Flutter Dependency Explorer - A visual developer tool for Flutter codebases.',
        ) {
    addCommand(ScanCommand());
  }
}
