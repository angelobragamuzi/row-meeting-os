# ROW

ROW significa **Record, Organize, Work** e e um aplicativo Flutter para gravar reunioes e gerar resumos estruturados em tempo real de forma local (sem backend proprio).

## Funcionalidades

- Gravar audio de reunioes com `record`
- Salvar dados localmente com `Hive`
- Transcrever audio real com Gemini a partir do arquivo gravado
- Analisar transcricao com Gemini (quando `GEMINI_API_KEY` estiver configurada)
- Exibir resumo estruturado com:
  - descricao
  - topicos
  - decisoes
  - tarefas

## Arquitetura

O projeto segue **Clean Architecture** + **BLoC**, com separacao por feature:

- `lib/core`
  - temas, erros e injecao de dependencias
- `lib/features/meeting/domain`
  - entidades
  - contratos de repositorio/servicos
  - use cases
- `lib/features/meeting/data`
  - datasources (gravacao e storage local)
  - servicos (transcricao e resumo com Gemini)
  - implementacao de repositorio
- `lib/features/meeting/presentation`
  - BLoC (eventos/estados)
  - telas e widgets

## Estrutura de pastas

```txt
lib/
  core/
    di/
    error/
    theme/
  features/
    meeting/
      data/
      domain/
      presentation/
```

## Fluxo do app

1. Usuario inicia uma nova reuniao
2. Inicia/parar gravacao
3. Clica em finalizar
4. Tela de processamento exibe:
   - Transcrevendo...
   - Analisando...
5. Reuniao e resumo sao salvos localmente
6. Tela de resultado mostra descricao/topicos/decisoes/tarefas

## BLoC e estados

`MeetingBloc` usa os estados principais:

- `initial`
- `recording`
- `processing`
- `loaded`
- `error`

## Dependencias principais

- `flutter_bloc`
- `equatable`
- `record`
- `http`
- `hive`
- `path_provider`
- `intl`
- `flutter_dotenv`

## Como rodar

1. Instale dependencias:

```bash
flutter pub get
```

2. Configure variaveis de ambiente:

```bash
cp .env.example .env
```

3. Abra o arquivo `.env` e preencha:

```env
GEMINI_API_KEY=SUA_CHAVE_AQUI
GEMINI_MODEL=gemini-2.5-flash
```

4. Rode o app:

```bash
flutter run
```

## Observacoes

- O app funciona sem backend proprio.
- Sem `GEMINI_API_KEY` no `.env`, o app mostra erro de configuracao ao processar.
- Em caso de `HTTP 429` (limite/quota Gemini), o app mostra erro explicito para evitar salvar resultados artificiais.
- Ainda existe fallback para `--dart-define=GEMINI_API_KEY=...` por compatibilidade.
- O modelo pode ser trocado por `.env` com `GEMINI_MODEL=...` (padrao: `gemini-2.5-flash`).
- Dados de reuniao ficam persistidos localmente em Hive.
