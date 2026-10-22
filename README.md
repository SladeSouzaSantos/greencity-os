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
