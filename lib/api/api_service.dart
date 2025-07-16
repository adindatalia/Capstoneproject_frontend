import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/recipe_model.dart';

class ApiService {
  final String _baseUrl = "http://127.0.0.1:5000/api";

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    print(
        'API Service - Getting headers, token: ${token != null ? 'present' : 'null'}');
    if (token != null) {
      print('Token length: ${token.length}');
      print('Token prefix: ${token.substring(0, min(20, token.length))}...');
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('Headers being sent: ${headers.keys.toList()}');
    return headers;
  }

  // API UNTUK RESEP & BAHAN

  Future<Map<String, List<dynamic>>> getIngredients() async {
    final response =
        await http.get(Uri.parse('$_baseUrl/ingredients-by-category'));
    if (response.statusCode == 200) {
      return Map<String, List<dynamic>>.from(
          json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Gagal memuat daftar bahan');
    }
  }

  Future<List<Recipe>> getRecommendations(List<String> ingredients) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/recommendations'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, List<String>>{'ingredients': ingredients}),
    );
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((recipe) => Recipe.fromJson(recipe)).toList();
    } else {
      throw Exception('Gagal mendapatkan rekomendasi');
    }
  }

  Future<Map<String, dynamic>> getRecipeDetails(int recipeId) async {
    final response = await http.get(Uri.parse('$_baseUrl/recipe/$recipeId'));
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Gagal memuat detail resep');
    }
  }

  Future<List<Recipe>> getLatestRecipes() async {
    final response = await http.get(Uri.parse('$_baseUrl/recipes/latest'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse.map((recipe) => Recipe.fromJson(recipe)).toList();
    } else {
      throw Exception('Gagal memuat resep terbaru');
    }
  }

  //API UNTUK AUTENTIKASI

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );
    return {
      'statusCode': response.statusCode,
      'body': json.decode(response.body)
    };
  }

  Future<Map<String, dynamic>> register(
      String nama, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(
          <String, String>{'nama': nama, 'email': email, 'password': password}),
    );
    return {
      'statusCode': response.statusCode,
      'body': json.decode(response.body)
    };
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Gagal memuat profil');
    }
  }

  // API UNTUK FAVORIT

  Future<Map<String, dynamic>> toggleFavorite(int recipeId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/favorite/$recipeId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'data': {'error': 'Failed to toggle favorite'},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': {'error': 'Network error: $e'},
      };
    }
  }

  Future<List<Recipe>> getFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/favorites'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        return jsonData.map((data) => Recipe.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}