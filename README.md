# ROW

ROW (**Record, Organize, Work**) é uma aplicação Flutter para registro e pós-processamento de reuniões com suporte a IA generativa (Gemini). O projeto foi desenhado para funcionar sem backend proprietário, com armazenamento local e foco em transformar conversa em ação.

## Visão Geral

O aplicativo cobre o ciclo completo de uma reunião:

1. gravação de áudio;
2. transcrição automática;
3. síntese do conteúdo;
4. geração de desdobramentos práticos;
5. persistência local e exportação em PDF.

## Funcionalidades Principais

- Gravação de áudio com `record`.
- Transcrição automática via `GeminiTranscriptionService`.
- Geração de resumo executivo via `GeminiService`.
- Geração assistida de conteúdo complementar:
  - tópicos de discussão;
  - tarefas sugeridas;
  - observações importantes;
  - pacote completo consolidado.
- Persistência local de reuniões e resumos com `Hive`.
- Atualização de resumo persistido após interações do assistente.
- Exportação de PDF local com `pdf`.

## Arquitetura

A solução segue **Clean Architecture** com organização **feature-first** e gerenciamento de estado com **BLoC**.

### Camadas

- **Domain**: entidades, contratos e casos de uso.
- **Data**: datasources, serviços externos e implementação de repositórios.
- **Presentation**: telas, widgets, cubits/blocs e estados.
- **Core**: DI, tema e tratamento de erros compartilhados.

### Mapeamento de Responsabilidades

- `GeminiTranscriptionService`: transcrição do áudio para texto.
- `GeminiService`: sumarização e geração de conteúdo adicional a partir do resumo.
- `MeetingRepositoryImpl`: orquestração entre gravação, IA, persistência e exportação.
- `LocalMeetingDataSource`: leitura/escrita local com Hive.
- `SummaryAssistantCubit`: fluxo de geração de conteúdo complementar e exportação.
- `PdfExportServiceImpl`: montagem e escrita de PDF no dispositivo.

## Fluxo Funcional (Ponta a Ponta)

1. Usuário inicia uma nova reunião.
2. Inicia e finaliza a gravação.
3. O app transcreve o áudio com Gemini.
4. O app gera um resumo executivo em português.
5. A reunião é persistida localmente.
6. A tela de resultado permite abrir o assistente de resumo.
7. O assistente gera conteúdo acionável e pode exportar PDF.

## Stack Tecnológica

- **Flutter / Dart**
- **flutter_bloc** (estado e fluxo de UI)
- **equatable** (comparação de objetos de estado)
- **record** (captura de áudio)
- **http** (integração com Gemini API)
- **hive** (persistência local)
- **path_provider** (resolução de diretórios)
- **pdf** (geração de documento)
- **flutter_dotenv** (configuração de ambiente)

## Estrutura de Pastas

```txt
lib/
  core/
    di/
    error/
    theme/
  features/
    meeting/
      data/
        datasources/
        models/
        repositories/
        services/
      domain/
        entities/
        repositories/
        services/
        usecases/
      presentation/
        bloc/
        screens/
        widgets/
    splash/
      presentation/
        screens/
```

## Configuração de Ambiente

1. Crie o arquivo de ambiente:

```bash
cp .env.example .env
```

2. Configure as variáveis:

```env
GEMINI_API_KEY=SUA_CHAVE_AQUI
GEMINI_MODEL=gemini-2.5-flash
```

### Observações de Segurança

- Não versione segredos em `.env`.
- Em produção, o ideal é intermediar chamadas a LLM por backend seguro.

## Como Executar

```bash
flutter pub get
flutter run
```

## Resiliência e Tratamento de Erros

- Validação de entrada para áudio e transcrição vazios.
- Timeout explícito para chamadas de transcrição e sumarização.
- Retentativa com backoff para `HTTP 429` (quota/rate limit).
- Mensagens de erro orientadas ao usuário final.

## Persistência e Exportação

- Reuniões e resumos ficam armazenados localmente em Hive.
- O PDF do pacote completo é gerado no dispositivo.
- No Android, a exportação prioriza diretório externo quando disponível.

## Status

Projeto em evolução contínua, com foco em qualidade de UX, clareza do fluxo de reunião e arquitetura escalável para novas funcionalidades.
