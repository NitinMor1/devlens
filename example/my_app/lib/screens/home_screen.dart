import 'package:my_app/blocs/user_bloc.dart';

// DevLens automatically categorizes classes ending in 'Screen' as UI components.
// We don't need actual Flutter imports for it to map our architecture!
class HomeScreen {
  final UserBloc bloc;

  HomeScreen(this.bloc);

  void render() {
    print('Rendering Home Screen...');
  }
}
