import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/app_exception.dart';
import '../../domain/services/summary_service.dart';

class GeminiService implements SummaryService {
  GeminiService({
    required http.Client client,
    required String apiKey,
    this.model = 'gemini-2.0-flash',
  }) : _client = client,
       _apiKey = apiKey;

  final http.Client _client;
  final String _apiKey;
  final String model;

  @override
  Future<Map<String, dynamic>> summarize(String transcription) async {
    if (transcription.trim().isEmpty) {
      throw const AppException(
        'A transcricao esta vazia e nao pode ser analisada.',
      );
    }

    if (_apiKey.trim().isEmpty) {
      throw const AppException(
        'GEMINI_API_KEY nao configurada no arquivo .env.',
      );
    }

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
      );

      const instruction =
          'Analise a seguinte transcricao de uma reuniao e retorne um JSON com:\n'
          '* contexto\n'
          '* principais topicos\n'
          '* decisoes\n'
          '* tarefas com responsaveis\n\n'
          'Seja objetivo e estruturado.';

      final payload = {
        'contents': [
          {
            'parts': [
              {'text': '$instruction\n\nTranscricao:\n$transcription'},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      };

      final response = await _postWithRetry(
        uri: uri,
        payload: payload,
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode >= 400) {
        throw AppException(
          _buildGeminiErrorMessage(
            operation: 'analise',
            statusCode: response.statusCode,
            responseBody: response.body,
          ),
        );
      }

      final rawResponse = jsonDecode(response.body);
      if (rawResponse is! Map<String, dynamic>) {
        throw const AppException('Resposta invalida da API Gemini.');
      }

      final rawText = _extractText(rawResponse);
      final decoded = jsonDecode(_sanitizeJson(rawText));
      if (decoded is! Map) {
        throw const AppException(
          'Nao foi possivel converter resumo do Gemini em JSON.',
        );
      }

      final normalized = _normalizeSummary(Map<String, dynamic>.from(decoded));
      normalized['fonte'] = 'gemini';
      return normalized;
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Tempo limite excedido ao analisar a transcricao no Gemini.',
      );
    } catch (error) {
      throw AppException('Falha ao analisar transcricao: $error');
    }
  }

  Future<http.Response> _postWithRetry({
    required Uri uri,
    required Map<String, dynamic> payload,
    required Duration timeout,
  }) async {
    const retryDelays = <Duration>[
      Duration.zero,
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    for (var attempt = 0; attempt < retryDelays.length; attempt++) {
      final delay = retryDelays[attempt];
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      final shouldRetry =
          response.statusCode == 429 && attempt < retryDelays.length - 1;
      if (!shouldRetry) {
        return response;
      }
    }

    throw const AppException('Erro inesperado no envio para Gemini.');
  }

  String _extractText(Map<String, dynamic> response) {
    final candidates = response['candidates'];

    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map) {
        final content = first['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final part = parts.first;
            if (part is Map && part['text'] is String) {
              return (part['text'] as String).trim();
            }
          }
        }
      }
    }

    throw const AppException('Conteudo de resposta do Gemini nao encontrado.');
  }

  String _sanitizeJson(String input) {
    final trimmed = input.trim();

    if (trimmed.startsWith('```')) {
      final cleaned = trimmed
          .replaceFirst(RegExp(r'^```json\s*'), '')
          .replaceFirst(RegExp(r'^```\s*'), '')
          .replaceFirst(RegExp(r'```$'), '');
      return cleaned.trim();
    }

    return trimmed;
  }

  String _buildGeminiErrorMessage({
    required String operation,
    required int statusCode,
    required String responseBody,
  }) {
    final geminiMessage = _extractGeminiErrorMessage(responseBody);

    if (statusCode == 429) {
      return 'Limite de uso do Gemini atingido (HTTP 429) durante a '
          '$operation. Verifique quota/faturamento e tente novamente.';
    }

    if (geminiMessage != null && geminiMessage.trim().isNotEmpty) {
      return 'Falha no Gemini ($operation, HTTP $statusCode): $geminiMessage';
    }

    return 'Falha no Gemini durante $operation (HTTP $statusCode).';
  }

  String? _extractGeminiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    } catch (_) {
      // Ignora falhas de parse para preservar mensagem default.
    }
    return null;
  }

  Map<String, dynamic> _normalizeSummary(Map<String, dynamic> raw) {
    final context = (raw['contexto'] ?? raw['context'] ?? '').toString().trim();

    final topics = _asStringList(raw['topicos'] ?? raw['topics']);
    final decisions = _asStringList(raw['decisoes'] ?? raw['decisions']);
    final tasks = _asTaskList(raw['tarefas'] ?? raw['tasks']);

    return {
      'contexto': context.isEmpty
          ? 'Contexto nao identificado na transcricao.'
          : context,
      'topicos': topics.isEmpty
          ? <String>['Nenhum topico principal identificado.']
          : topics,
      'decisoes': decisions.isEmpty
          ? <String>['Nenhuma decisao explicita registrada.']
          : decisions,
      'tarefas': tasks.isEmpty
          ? <Map<String, String>>[
              {
                'descricao': 'Revisar transcricao e definir proximos passos.',
                'responsavel': 'Time',
              },
            ]
          : tasks,
    };
  }

  List<String> _asStringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, String>> _asTaskList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw.where((item) => item != null).map((item) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final description =
            (map['descricao'] ??
                    map['description'] ??
                    map['tarefa'] ??
                    map['task'] ??
                    '')
                .toString()
                .trim();
        final owner =
            (map['responsavel'] ??
                    map['owner'] ??
                    map['responsible'] ??
                    'Nao definido')
                .toString()
                .trim();

        return {
          'descricao': description.isEmpty ? 'Sem descricao' : description,
          'responsavel': owner.isEmpty ? 'Nao definido' : owner,
        };
      }

      final text = item.toString().trim();
      return {
        'descricao': text.isEmpty ? 'Sem descricao' : text,
        'responsavel': 'Nao definido',
      };
    }).toList();
  }
}
