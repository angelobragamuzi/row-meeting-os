import '../../domain/services/transcription_service.dart';

class MockTranscriptionService implements TranscriptionService {
  @override
  Future<String> transcribe(String filePath) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    return '''
Reuniao de alinhamento semanal do time de produto e engenharia.
Foi discutido o andamento da feature de onboarding, os bloqueios no fluxo de pagamento e os resultados da sprint atual.
A equipe decidiu priorizar a correcao do bug de autenticacao e publicar uma atualizacao na sexta-feira.
Joana ficou responsavel por validar os requisitos com o cliente, Carlos por corrigir o bug, e Ana por preparar o relatorio de status.
''';
  }
}
