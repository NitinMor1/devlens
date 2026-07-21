import 'package:my_app/models/user_model.dart';

class UserRepository {
  Future<UserModel> fetchUser(String id) async {
    // Fake repository logic
    return UserModel(id, 'Nitin Mor');
  }
}
