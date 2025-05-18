import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:story_project/data/api/api_constants.dart';
import 'package:story_project/domain/models/story.dart';

class StoryService {
  Future<List<Story>> getStories(String token, {int? page, int? size}) async {
    final Map<String, String> params = {};
    if (page != null) params['page'] = page.toString();
    if (size != null) params['size'] = size.toString();

    final Uri uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.stories}',
    ).replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> storiesJson = responseData['listStory'];
      return storiesJson.map((json) => Story.fromJson(json)).toList();
    } else {
      throw Exception(responseData['message']);
    }
  }

  Future<Story> getStoryDetail(String token, String id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.detailStory}$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Story.fromJson(responseData['story']);
    } else {
      throw Exception(responseData['message']);
    }
  }

  Future<void> addStory(
    String token,
    String description,
    List<int> photoBytes,
    String fileName, {
    double? lat,
    double? lon,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.stories}');

    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['description'] = description;

    if (lat != null) request.fields['lat'] = lat.toString();
    if (lon != null) request.fields['lon'] = lon.toString();

    request.files.add(
      http.MultipartFile.fromBytes('photo', photoBytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final responseData = jsonDecode(response.body);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(responseData['message']);
    }
  }
}
