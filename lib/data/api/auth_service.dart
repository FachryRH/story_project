import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:story_project/data/api/api_constants.dart';
import 'package:story_project/domain/models/user.dart';

class AuthService {
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return User.fromJson(responseData['loginResult']);
    } else {
      throw Exception(responseData['message']);
    }
  }

  Future<void> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(responseData['message']);
    }
  }
}
