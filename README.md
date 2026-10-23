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

## Configuração local da IA (OpenRouter)

1. Copie `.env.example` para `.env` na raiz do projeto e configure
   `OPENROUTER_API_KEY` com uma chave da sua conta OpenRouter.
2. Configure `OPENROUTER_MODEL` com o ID do modelo desejado em
   https://openrouter.ai/models. O padrão `google/gemini-3.8-flash` usa
   Gemini **por meio do OpenRouter**, mas você pode trocar por qualquer
   modelo compatível. OpenRouter é um gateway, não um modelo de IA.
3. `OPENROUTER_PDF_ENGINE=cloudflare-ai` usa processamento PDF para
   markdown/texto sem custo adicional de OCR; `native` exige modelo
   compatível com PDF; `mistral-ocr` pode ter cobrança adicional por página.
4. Execute `flutter pub get` e `flutter run -d windows`.

O arquivo `.env` está no `.gitignore`, é carregado antes de iniciar
a aplicação e **não é modificado automaticamente**. Se ainda estiver com
`GEMINI_API_KEY`, substitua manualmente pela nova chave OpenRouter.
Uma chave Gemini relatada como vazada deve ser revogada em seu próprio
provedor; o OpenRouter exige uma chave nova e independente.

**Segurança:** `flutter_dotenv` incorpora o `.env` nos assets do aplicativo,
permitindo extrair qualquer chave incluída no build distribuído. Por isso,
use essa configuração exclusivamente para desenvolvimento local. Em produção,
implemente uma API backend com chave no servidor, autenticação e limites de uso.
O importador OpenRouter usa Dio independente **sem LogInterceptor**, evitando
registrar o PDF ou o token no console durante a importação.

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
