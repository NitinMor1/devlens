import 'package:my_app/models/user_model.dart';
import 'package:my_app/repositories/user_repository.dart';

class UserBloc {
  final UserRepository repository;
  
  UserBloc(this.repository);

  Future<void> loadUser() async {
    final user = await repository.fetchUser('123');
    print(user.name);
  }
}
