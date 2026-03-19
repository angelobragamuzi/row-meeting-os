import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/error/app_exception.dart';
import '../../domain/services/transcription_service.dart';

class GeminiTranscriptionService implements TranscriptionService {
  GeminiTranscriptionService({
    required http.Client client,
    required String apiKey,
    this.model = 'gemini-2.0-flash',
  }) : _client = client,
       _apiKey = apiKey;

  final http.Client _client;
  final String _apiKey;
  final String model;

  @override
  Future<String> transcribe(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const AppException(
        'Arquivo de audio nao encontrado para transcricao.',
      );
    }

    if (_apiKey.trim().isEmpty) {
      throw const AppException(
        'GEMINI_API_KEY nao configurada no arquivo .env.',
      );
    }

    try {
      final audioBytes = await file.readAsBytes();
      if (audioBytes.isEmpty) {
        throw const AppException(
          'Audio vazio. Grave novamente e tente outra vez.',
        );
      }

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
      );

      final payload = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Transcreva este audio de reuniao em portugues do Brasil. '
                    'Retorne somente o texto transcrito, sem explicacoes extras.',
              },
              {
                'inlineData': {
                  'mimeType': _guessMimeType(filePath),
                  'data': base64Encode(audioBytes),
                },
              },
            ],
          },
        ],
        'generationConfig': {'temperature': 0.0},
      };

      final response = await _postWithRetry(
        uri: uri,
        payload: payload,
        timeout: const Duration(seconds: 90),
      );

      if (response.statusCode >= 400) {
        throw AppException(
          _buildGeminiErrorMessage(
            operation: 'transcricao',
            statusCode: response.statusCode,
            responseBody: response.body,
          ),
        );
      }

      final raw = jsonDecode(response.body);
      if (raw is! Map<String, dynamic>) {
        throw const AppException('Resposta invalida ao transcrever audio.');
      }

      final text = _sanitizeText(_extractText(raw));
      if (text.trim().isEmpty) {
        throw const AppException('Transcricao retornou vazia.');
      }

      return text;
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Tempo limite excedido ao transcrever audio no Gemini.',
      );
    } on SocketException {
      throw const AppException(
        'Falha de rede ao transcrever audio. Verifique a conexao.',
      );
    } catch (error) {
      throw AppException('Falha ao transcrever audio: $error');
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
            final textParts = parts
                .whereType<Map>()
                .map((part) => part['text'])
                .whereType<String>()
                .toList();
            if (textParts.isNotEmpty) {
              return textParts.join('\n').trim();
            }
          }
        }
      }
    }

    throw const AppException('Conteudo de transcricao nao encontrado.');
  }

  String _sanitizeText(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('```')) {
      final cleaned = trimmed
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
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

  String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a') || lower.endsWith('.mp4')) {
      return 'audio/mp4';
    }
    if (lower.endsWith('.wav')) {
      return 'audio/wav';
    }
    if (lower.endsWith('.mp3')) {
      return 'audio/mpeg';
    }
    if (lower.endsWith('.ogg')) {
      return 'audio/ogg';
    }
    return 'audio/mp4';
  }
}
