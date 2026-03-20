import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/summary_assistant_type.dart';
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
      const instruction =
          'Analise a seguinte transcricao de uma reuniao e retorne APENAS um JSON valido com a chave "resumo".\n'
          'O valor deve ser um texto objetivo (3 a 6 frases) em portugues do Brasil.\n'
          'Nao inclua markdown, comentarios ou campos extras.';

      final rawText = await _generateText(
        operation: 'analise',
        prompt: '$instruction\n\nTranscricao:\n$transcription',
        responseMimeType: 'application/json',
      );

      final decoded = _tryDecodeJsonMap(rawText);

      final normalized = _normalizeSummary(
        raw: decoded,
        fallbackText: _sanitizeJson(rawText),
      );
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

  @override
  Future<String> generateFromSummary({
    required String summary,
    required SummaryAssistantType type,
  }) async {
    if (summary.trim().isEmpty) {
      throw const AppException(
        'O resumo esta vazio e nao pode ser usado para gerar conteudo.',
      );
    }

    if (_apiKey.trim().isEmpty) {
      throw const AppException(
        'GEMINI_API_KEY nao configurada no arquivo .env.',
      );
    }

    try {
      final instruction = _instructionForType(type);
      final rawText = await _generateText(
        operation: 'geracao complementar',
        prompt: '$instruction\n\nResumo base:\n$summary',
      );

      final content = _sanitizeJson(rawText).trim();
      if (content.isEmpty) {
        throw const AppException('Resposta vazia ao gerar conteudo adicional.');
      }

      return content;
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Tempo limite excedido ao gerar conteudo adicional no Gemini.',
      );
    } catch (error) {
      throw AppException('Falha ao gerar conteudo adicional: $error');
    }
  }

  Future<String> _generateText({
    required String operation,
    required String prompt,
    String? responseMimeType,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
    );

    final generationConfig = <String, dynamic>{'temperature': 0.25};
    if (responseMimeType != null && responseMimeType.trim().isNotEmpty) {
      generationConfig['responseMimeType'] = responseMimeType;
    }

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': generationConfig,
    };

    final response = await _postWithRetry(
      uri: uri,
      payload: payload,
      timeout: const Duration(seconds: 30),
    );

    if (response.statusCode >= 400) {
      throw AppException(
        _buildGeminiErrorMessage(
          operation: operation,
          statusCode: response.statusCode,
          responseBody: response.body,
        ),
      );
    }

    final rawResponse = jsonDecode(response.body);
    if (rawResponse is! Map<String, dynamic>) {
      throw const AppException('Resposta invalida da API Gemini.');
    }

    return _extractText(rawResponse);
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

  Map<String, dynamic>? _tryDecodeJsonMap(String input) {
    try {
      final decoded = jsonDecode(_sanitizeJson(input));
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Se nao vier JSON valido, usamos o texto como fallback de resumo.
    }
    return null;
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

  Map<String, dynamic> _normalizeSummary({
    required Map<String, dynamic>? raw,
    required String fallbackText,
  }) {
    String summary = '';

    if (raw != null) {
      summary =
          (raw['resumo'] ??
                  raw['summary'] ??
                  raw['contexto'] ??
                  raw['context'] ??
                  raw['descricao'])
              .toString()
              .trim();
    }

    if (summary.isEmpty && raw != null) {
      final legacyParts = <String>[
        _asNonEmptyString(raw['contexto']),
        _asNonEmptyString(raw['context']),
      ].where((part) => part.isNotEmpty).toList();
      summary = legacyParts.join(' ').trim();
    }

    if (summary.isEmpty) {
      summary = fallbackText.trim();
    }

    if (summary.isEmpty) {
      summary = 'Resumo nao identificado para esta reuniao.';
    }

    return {'resumo': summary};
  }

  String _asNonEmptyString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  String _instructionForType(SummaryAssistantType type) {
    switch (type) {
      case SummaryAssistantType.discussionTopics:
        return 'Com base no resumo da reuniao, gere de 5 a 8 topicos de discussao para o proximo encontro.\n'
            'Formato obrigatorio:\n'
            '- Tópico 1\n'
            '- Tópico 2\n'
            'Use frases curtas e objetivas.';
      case SummaryAssistantType.actionTasks:
        return 'Com base no resumo da reuniao, crie tarefas praticas e acionaveis.\n'
            'Formato obrigatorio:\n'
            '- [Responsável sugerido] tarefa\n'
            'Gere entre 4 e 7 tarefas e seja direto.';
      case SummaryAssistantType.keyObservations:
        return 'Com base no resumo da reuniao, liste observacoes importantes, riscos e pontos de atencao.\n'
            'Formato obrigatorio:\n'
            '- Observação\n'
            'Gere entre 4 e 7 itens, com linguagem clara.';
      case SummaryAssistantType.fullPack:
        return 'Com base no resumo da reuniao, gere de forma estruturada: topicos de discussao, tarefas e observacoes importantes.\n'
            'Use listas objetivas e separadas por seção.';
    }
  }
}
