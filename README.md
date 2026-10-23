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

## Cálculo HSP: GHI, POA e limitações

- **HSP local (GHI)**: referência horizontal da latitude/longitude e da fonte de dados (não depende do módulo). A tela utiliza `detalhes.hsp_horizontal`; se ausente, apenas a consulta `placeholder` com inclinação zero fornece o fallback.
- **HSP do arranjo (POA)**: recebe inclinação, azimute, sombreamento e ganho traseiro equivalente se bifacial. Não é o GHI local. A API fornece componentes frontal e traseira em `detalhes` quando disponíveis.
- **Dimensionamento inicial**: segue a referência horizontal e PR simplificado de 77%; o ganho bifacial sugerido de 5% é apenas uma aproximação, não resultado físico do projeto.
- **Geração mensal**: soma a produção estimada de cada arranjo usando a própria irradiância mensal e coeficiente térmico. O aplicativo **não modela perdas I–V por mismatch, clipping do inversor ou restrições de strings**. Misturar configurações em um MPPT produz alerta de revisão elétrica, não um percentual inventado de perda. Não use a estimativa como validação elétrica final de um projeto comercial.
- **Integração**: o Flutter envia dimensões (metros), orientação, fonte de dados `auto` e transposição Perez. A fonte efetivamente usada depende do provedor selecionado pela API; confira o campo de fonte ao comparar com o dashboard.

### Testes das correções

```bash
flutter pub get
flutter analyze
flutter test test/data/models/solar_scenario_result_model_test.dart
flutter test test/data/repositories/solar_repository_impl_test.dart
flutter test test/domain/services/solar_reference_service_test.dart
flutter test test/domain/entities/solar_system_test.dart
```
