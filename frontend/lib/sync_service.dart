import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

class SyncService {
  static const String _queueBoxName = 'sync_queue';
  static Box<String>? _queueBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _queueBox = await Hive.openBox<String>(_queueBoxName);
    
    // Listen to network changes (Updated for connectivity_plus v6+)
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _syncPendingQueue();
      }
    });
  }

  static Future<bool> hasInternetConnection() async {
    // Standard usage for InternetConnectionChecker (Ensuring compatibility)
    return await InternetConnectionChecker().hasConnection;
  }

  /// Queues a request to be executed when the device is back online
  static Future<void> enqueueRequest(String endpoint, Map<String, dynamic> data) async {
    if (_queueBox == null) return;
    
    final request = {
      'endpoint': endpoint,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _queueBox!.add(jsonEncode(request));
    debugPrint("Requisição no endpoint $endpoint enfileirada para sync posterior.");
  }

  /// Tries to execute the request immediately. If offline, puts it in the queue.
  static Future<Map<String, dynamic>?> postOrEnqueue(String endpoint, Map<String, dynamic> data) async {
    if (await hasInternetConnection()) {
      try {
        return await ApiService.post(endpoint, data);
      } catch (e) {
        debugPrint("Erro na API, colocando requisição na fila para $endpoint: $e");
        await enqueueRequest(endpoint, data);
        return null;
      }
    } else {
      await enqueueRequest(endpoint, data);
      return {'status': 'queued', 'message': 'Gravado localmente. Será sincronizado quando houver rede.'};
    }
  }

  /// Tries to execute a multipart request immediately. If offline, puts it in the queue.
  static Future<Map<String, dynamic>?> postMultipartOrEnqueue(String endpoint, Map<String, dynamic> data, List<int> fileBytes, String filename) async {
    // Convert Map<String, dynamic> to Map<String, String> for ApiService.postMultipart
    final Map<String, String> stringFields = data.map((key, value) => MapEntry(key, value.toString()));

    if (await hasInternetConnection()) {
      try {
        return await ApiService.postMultipart(endpoint, stringFields, fileBytes, filename);
      } catch (e) {
        debugPrint("Erro na API, colocando requisição multipart na fila para $endpoint: $e");
        var storableData = Map<String, dynamic>.from(data);
        storableData['__is_multipart'] = true;
        storableData['__file_bytes'] = fileBytes;
        storableData['__filename'] = filename;
        await enqueueRequest(endpoint, storableData);
        return null;
      }
    } else {
      var storableData = Map<String, dynamic>.from(data);
      storableData['__is_multipart'] = true;
      storableData['__file_bytes'] = fileBytes; 
      storableData['__filename'] = filename;
      await enqueueRequest(endpoint, storableData);
      return {'status': 'queued', 'message': 'Gravado localmente. Será sincronizado quando houver rede.'};
    }
  }

  /// Replays pending requests and removes them if successful
  static Future<void> _syncPendingQueue() async {
    if (_queueBox == null || _queueBox!.isEmpty) return;
    
    bool hasConnection = await hasInternetConnection();
    if (!hasConnection) return;
    
    debugPrint("Iniciando sincronização de fila pendente.");
    
    final keys = _queueBox!.keys.toList();
    for (var key in keys) {
      try {
        final requestStr = _queueBox!.get(key);
        if (requestStr != null) {
          final request = jsonDecode(requestStr);
          final endpoint = request['endpoint'];
          final data = request['data'];
          
          if (data != null && data['__is_multipart'] == true) {
            final fileBytes = List<int>.from(data['__file_bytes']);
            final filename = data['__filename'];
            data.remove('__is_multipart');
            data.remove('__file_bytes');
            data.remove('__filename');
            
            // Convert to Map<String, String>
            final Map<String, String> stringFields = (data as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
            
            await ApiService.postMultipart(endpoint, stringFields, fileBytes, filename);
          } else {
            await ApiService.post(endpoint, data);
          }
          await _queueBox!.delete(key);
          debugPrint("Sincronizado sucesso: $endpoint");
        }
      } catch (e) {
        debugPrint("Falha ao sincronizar requisição da fila (tentará mais tarde): $e");
        break; 
      }
    }
  }
}
