# greencity_os

## Estrutura de Pasta do Projeto

```bash
lib/
├── core/              # Utilidades globais, erros e constantes
├── data/              # Implementação técnica (Infra)
│   ├── datasources/   # Chamadas HTTP (Dio)
│   ├── models/        # Conversão JSON <-> Dart
│   └── repositories/  # Implementação dos contratos do Domain
├── domain/            # Regras de Negócio (Independente de Framework)
│   ├── entities/      # Objetos de dados puros (SolarProject)
│   ├── repositories/  # Interfaces (Contratos)
│   └── usecases/      # Ações do sistema (CalcularHsp)
├── presentation/      # Interface de Usuário
│   ├── bloc/          # Gerenciamento de estado (Logic)
│   ├── pages/         # Telas (UI)
│   └── widgets/       # Componentes reutilizáveis
└── main.dart          # Ponto de entrada e Injeção de Dependência
```

## Configuração local da IA (OpenRouter — somente modelos gratuitos)

1. Copie `.env.example` para `.env` e configure
   `OPENROUTER_API_KEY` com a chave da sua conta.
2. `OPENROUTER_MODEL` define o modelo primário. **Deve terminar com
   `:free`**, pois o importador recusa modelos pagos e auto-routers.
3. `OPENROUTER_FALLBACK_MODELS` lista os modelos alternativos separados
   por vírgula. O OpenRouter tenta os candidatos na ordem quando houver
   falhas elegíveis de inferência (rate limit, indisponibilidade etc.).
   Caso a resposta HTTP 200 não contenha JSON extraível, o aplicativo
   realiza no máximo mais uma tentativa, iniciando no segundo modelo.
   Para desativar fallback, deixe `OPENROUTER_FALLBACK_MODELS=`.
4. `OPENROUTER_PDF_ENGINE=cloudflare-ai` converte o PDF em markdown
   sem custo extra de parsing. `native` depende de suporte do modelo.
   `mistral-ocr` foi bloqueado, pois pode cobrar por página.
5. Execute `flutter pub get` e `flutter run -d windows`.

Exemplo no `.env` local (nunca commitar a chave):
```dotenv
OPENROUTER_API_KEY=COLOQUE_SUA_CHAVE_LOCAL
OPENROUTER_MODEL=nvidia/nemotron-3.5-super-vl:free
OPENROUTER_FALLBACK_MODELS=nvidia/nemotron-3-super-120b-a12b:free
OPENROUTER_PDF_ENGINE=cloudflare-ai
```

**Observação sobre HTTP 400:** um erro de formato de PDF/requisição não
fica correto só por trocar de modelo. O serviço tenta remover
`response_format` **uma vez** apenas quando o erro explicitamente
indica que o modelo não suporta essa opção. Caso contrário, apresenta
uma mensagem de diagnóstico, sem repetir requisições inválidas.
No [Activity do OpenRouter](https://openrouter.ai/activity) você pode
verificar o motivo completo e qual modelo atendeu a requisição.

O `.env` está no `.gitignore` e não é alterado pelos commits.
Chaves comprometidas de outros provedores devem ser revogadas.
**Segurança:** `flutter_dotenv` inclui o `.env` nos assets distribuídos.
Essa abordagem é somente para desenvolvimento; em produção use backend
autenticado que proteja a chave. O OpenRouter e o provedor selecionado
recebem o PDF anexado. Não envie documentos confidenciais a endpoints
gratuitos sem revisar seus termos.

## Identidade visual — ícone do aplicativo

O logo GreenCity enviado como referência foi preparado como imagem PNG otimizada e
mantido em `assets/icon/greencity_icon.png`. O gerador usa a configuração
`flutter_launcher_icons.yaml` para Android, iOS, macOS, Windows e Web.

Para **gerar os ícones nativos** (necessário após baixar a branch e sempre que
a imagem fonte mudar):

```powershell
flutter pub get
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
flutter analyze
flutter test
flutter run -d windows
```

O comando de geração atualiza arquivos específicos de cada plataforma
(`windows/runner/resources/app_icon.ico`, ícones Android/iOS/macOS e favicon/
manifest do Web). Antes de versionar os artefatos gerados, revise o `git diff`
e evite incluir modificações locais de Gradle, lockfile ou plugins que não
façam parte da mudança. O PNG usado no gerador tem fundo transparente;
a configuração do iOS compõe uma cor de fundo porque ícones iOS não aceitam
canal alfa.

## Catálogo local de equipamentos (Isar)

Os módulos fotovoltaicos e os inversores ficam persistidos no banco Isar no
diretório de documentos da aplicação. O catálogo **não é apagado ao iniciar**.
Uma carga inicial de exemplos é feita somente na primeira inicialização e
registrada pelo marcador `.greencity_seed_v1`. Não apague o arquivo do banco
`default.isar` ou o marcador para limpar o catálogo sem querer.

Na tela **Banco de Dados Solar** é possível adicionar manualmente, excluir
com confirmação e consultar os cadastros atualizados. A identidade do registro
é a combinação fabricante + modelo, comparada sem diferenciar maiúsculas de
minúsculas ou espaços repetidos.

### Importação de datasheet PDF por IA

1. Configure `OPENROUTER_API_KEY` no **.env local**, além de
   `OPENROUTER_MODEL` e `OPENROUTER_PDF_ENGINE` se desejar.
2. Em **Banco de Dados Solar > Adicionar**, escolha
   **Importar datasheet PDF com IA** (PDF de até 10 MB).
3. O documento selecionado é enviado ao OpenRouter, que processa o PDF
   com o motor escolhido e o modelo configurado. A resposta contém uma
   lista de módulos e inversores; cada modelo é apresentado individualmente.
4. Confira fabricante, modelo, potência, STC, dimensões e limites MPPT.
   Você pode **revisar e salvar um por um**, pular modelos, ou usar
   **Importar todos (se completos)** para registrar a lista de uma vez.
5. O lote é **atômico**, exige parâmetros essenciais e ignora duplicatas.
   Campos opcionais não encontrados podem ser guardados como zero no Isar
   existente (não informado). Confira o datasheet antes de dimensionar.

**Privacidade e custo:** somente PDFs escolhidos explicitamente são
enviados ao OpenRouter e ao provedor de inferência. O modelo escolhido pode
cobrar tokens e motores de OCR podem cobrar por página.

### Validação no Windows

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Confira manualmente: cadastrar módulo; fechar e abrir o app (deve persistir);
remover módulo e reiniciar (não deve voltar); repetir para inversor; tentar
cadastro duplicado; importar um datasheet com 2+ variantes; conferir IDs
distintos e valores por modelo; verificar que registros incompletos não são
incluídos silenciosamente. Não use `git add -A` para incluir arquivos locais
alheios à correção (Gradle, plugins, .env ou lockfile).
