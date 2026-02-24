import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000'; // Alterado para 127.0.0.1 para evitar problemas de IPv6 no Windows

  static Future<String?> _getToken() async {
    return await AuthService().getIdToken();
  }

  // Método genérico para requisições GET
  static Future<dynamic> get(String endpoint, {String? token}) async {
    final headers = <String, String>{};
    final authToken = token ?? await _getToken();
    
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar dados: ${response.statusCode} - ${response.body}');
    }
  }

  // Método genérico para requisições POST
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    final authToken = token ?? await _getToken();

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao enviar dados: ${response.statusCode} - ${response.body}');
    }
  }

  // Método para requisições Multipart (Upload de Arquivos)
  static Future<dynamic> postMultipart(String endpoint, Map<String, String> fields, List<int> fileBytes, String filename, {String? token}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    final authToken = token ?? await _getToken();
    
    if (authToken != null && authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }

    // Adiciona campos de texto
    request.fields.addAll(fields);

    // Adiciona arquivo
    var multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: filename,
    );
    request.files.add(multipartFile);

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro no upload: ${response.statusCode} - ${response.body}');
    }
  }

  // Método genérico para requisições PUT
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data, {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    final authToken = token ?? await _getToken();

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } else {
      throw Exception('Erro ao atualizar dados: ${response.statusCode} - ${response.body}');
    }
  }

  // Método genérico para requisições DELETE
  static Future<dynamic> delete(String endpoint, {String? token}) async {
    final headers = <String, String>{};
    final authToken = token ?? await _getToken();

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } else {
      throw Exception('Erro ao deletar dados: ${response.statusCode} - ${response.body}');
    }
  }

  // Buscar compromissos (events) do calendário
  static Future<List<dynamic>> getAppointments({
    required int childId,
    required String startDate,
    required String endDate,
    String? token,
    bool useMock = false,
  }) async {
    final uri = Uri.parse(useMock
        ? '$baseUrl/calendar/events/mock'
        : '$baseUrl/calendar/events?child_id=$childId&start_date=$startDate&end_date=$endDate');

    final headers = <String, String>{};
    final authToken = token ?? await _getToken();

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map && body['events'] != null) {
        return body['events'] as List<dynamic>;
      }
      return [];
    } else if (response.statusCode == 401) {
      return [];
    } else {
      String bodyText = response.body;
      throw Exception('Erro ao buscar compromissos: ${response.statusCode} - $bodyText');
    }
  }

  // Método para obter resposta bruta (para debug)
  static Future<String> getRawAppointments({
    required int childId,
    required String startDate,
    required String endDate,
    String? token,
    bool useMock = false,
  }) async {
    final uri = Uri.parse(useMock
        ? '$baseUrl/calendar/events/mock'
        : '$baseUrl/calendar/events?child_id=$childId&start_date=$startDate&end_date=$endDate');

    final headers = <String, String>{};
    final authToken = token ?? await _getToken();

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.get(uri, headers: headers);
    return response.body; 
  }
}
