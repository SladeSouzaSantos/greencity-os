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

## Configuração local da IA (Gemini)

1. Copie `.env.example` para `.env` na raiz do projeto.
2. Configure `GEMINI_API_KEY` no arquivo `.env` local, sem aspas.
3. Execute `flutter pub get` e `flutter run`.

O arquivo `.env` está no `.gitignore`, e `lib/main.dart` o carrega antes de iniciar o app. A chave previamente publicada no repositório deve ser **revogada e substituída**: removê-la de commits novos não a elimina do histórico.

**Segurança:** `flutter_dotenv` inclui o `.env` nos assets do build. Portanto, essa configuração serve para desenvolvimento, não protege uma chave em APK/IPA/web distribuído. Para produção, mova o consumo do Gemini para um backend com autenticação e limitação de uso.

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

1. Configure `GEMINI_API_KEY` no seu **.env local**. Pode configurar
   `GEMINI_MODEL` para escolher um modelo Gemini disponível.
2. Em **Banco de Dados Solar > Adicionar**, escolha
   **Importar datasheet PDF com IA** (PDF de até 10 MB).
3. O documento selecionado é enviado à API do Google Gemini, que devolve
   uma lista de módulos e inversores. A tela apresenta cada modelo
   individualmente, com os dados técnicos disponíveis.
4. Confira fabricante, modelo, potência, STC, dimensões e limites MPPT.
   Você pode **revisar e salvar um por um**, pular modelos, ou usar
   **Importar todos (se completos)** para registrar a lista de uma vez.
5. O salvamento em lote é **atômico** e rejeita o lote quando faltam
   especificações obrigatórias. Registros existentes/duplicados são
   ignorados. Os campos opcionais não encontrados podem ser guardados
   como zero (não informado) porque o esquema Isar atual não usa null.
   **Revise antes de utilizar no dimensionamento real.**

**Privacidade:** somente PDFs escolhidos explicitamente são enviados à
API Gemini. A chave em `.env` é apenas adequada para desenvolvimento:
qualquer chave embutida em aplicativos distribuídos pode ser extraída.
Para distribuir publicamente, mova a chamada Gemini para um backend seguro.
A integração mantém o SDK Dart existente; esse SDK está obsoleto e merece
uma migração separada em uma próxima etapa.

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
