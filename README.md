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


### Precisão técnica de extração e limites conhecidos

- Os dados são extraídos pelo OpenRouter e **devem ser conferidos na
  ficha original** antes do dimensionamento. Uma extração parcial não é
  evidência de que o datasheet não possui os campos.
- Potências com unidade explícita W/Wp podem ser convertidas para kW,
  faixas compostas (por exemplo, 80–560 V / 360 V) separadas e códigos
  "3/1" identificados como 3 MPPTs / 1 string. Nenhum intervalo é
  convertido silenciosamente em valor nominal.
- Se faltarem pelo menos dois parâmetros essenciais do inversor, uma
  segunda leitura **somente do texto presente em file.annotations**
  é tentada uma vez. O PDF Base64 não é retransmitido. Na ausência
  dessas annotations, mantém a extração inicial sem tentar novamente.
  A segunda inferência usa quota do modelo gratuito.
- O banco Isar atual guarda somente uma corrente para todos os MPPTs.
  Quando o datasheet informa correntes distintas (como 20/16/20 A),
  a prévia mostra o vetor; a importação em lote fica bloqueada e o
  salvamento individual requer confirmação de que será armazenado o
  **MENOR** valor (conservador, mas não equivalente ao equipamento real).
  A persistência individual por MPPT exige evolução futura do esquema.
- PDF de até 10 MB; acima de 5 MB o aplicativo avisa sobre o acréscimo
  de aproximadamente 33% do Base64 e oferece cancelamento para que
  o usuário otimize imagens mantendo a legibilidade das tabelas.

#### Gabaritos públicos usados nos testes

Somente fatos técnicos foram convertidos em testes unitários, sem
incluir cópias das fichas de terceiros no repositório:

- AUXSOL ASN-(3 a 6)SL-G2, 7 modelos:
  https://assistencia.souenergy.com.br/docs/download/360
- Solplanet Série S, 5 modelos:
  https://assistencia.souenergy.com.br/docs/download/124
- SolaX X1-Hybrid G4, família monofásica:
  https://assistencia.souenergy.com.br/docs/download/41
- Leapton S1X-5K1P-Y / S1X-7.5K1P-Y:
  https://assistencia.souenergy.com.br/docs/download/299

**Atenção:** diferentes revisões comerciais da mesma família podem
informar potências CC recomendadas distintas. O extrator deve usar a
revisão do **PDF selecionado**, nunca substituir seus dados pelos gabaritos.


## Testes locais de datasheets via Ollama (Windows)

O mesmo botão **Importar datasheet PDF com IA** agora escolhe o provedor
pela configuração do `.env`:

```dotenv
# true = Ollama local; false = OpenRouter (padrão)
OLLAMA_ENABLED=true
OLLAMA_MODEL=qwen2.5:3b
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_NUM_CTX=4096
OLLAMA_RECEIVE_TIMEOUT_SECONDS=900
OLLAMA_PYTHON=python
```

Ollama ativo: não é necessário configurar `OPENROUTER_API_KEY`, e falhas
no serviço local **não** geram fallback para OpenRouter nem consumo de
créditos. Ollama desativado: o fluxo original OpenRouter continua ativo.
O valor de `OLLAMA_ENABLED` deve ser explicitamente `true` ou `false`.
Reinicie o aplicativo após alterar o `.env`.

### Preparação

```powershell
python -m pip install --upgrade pymupdf
ollama list
Invoke-RestMethod http://localhost:11434/api/tags
flutter pub get
flutter run -d windows
```

Se a API local estiver indisponível, execute `ollama serve` em um terminal.
Os modelos disponíveis dependem do Ollama instalado. Para máquinas com
4 GB de VRAM, comece por `qwen2.5:3b` e contexto 4096. Os modelos 9B/27B
podem ficar predominantemente na CPU e levar muito mais tempo.

O script `tools/ollama_pdf_extract.py` extrai texto e tabelas
com PyMuPDF, passa-os ao endpoint local `/api/chat` e recebe JSON estruturado.
O resultado é normalizado pelas **mesmas entidades e auditoria semântica**
já utilizadas com OpenRouter. Uma segunda chamada local recupera campos
ausentes. O PDF em si **não é enviado** ao OpenRouter.

**Limitação importante:** esse modo é experimental para desenvolvimento
no Windows, exige Python e PDFs com texto pesquisável. Datasheets somente
digitalizados exigem OCR (ainda não implementado). Para distribuição
em outras plataformas, é necessário um extrator PDF multiplataforma.
Com `OLLAMA_ENABLED=true`, o endereço é intencionalmente restrito a
`localhost`/`127.0.0.1` para evitar transferências involuntárias.
O JSON da IA não é automaticamente confiável: revise os campos antes
de salvar ou dimensionar. Nenhuma dependência de Python é exigida
quando `OLLAMA_ENABLED=false`.

### Diagnóstico de falhas locais

A chamada `POST /api/chat` reporta códigos amigáveis como
`conexao_recusada`, `conexao_interrompida`, `timeout_conexao`,
`timeout_envio`, `timeout_resposta`, `modelo_nao_encontrado`,
`memoria_insuficiente`, `contexto_excedido` e `resposta_json_invalida`.
O diálogo mostra o tempo da tentativa e sugere uma ação adequada.
A duração inclui carregamento do modelo, avaliação do prompt e geração.

`OLLAMA_RECEIVE_TIMEOUT_SECONDS=900` controla o limite de espera da
resposta sem streaming (30 a 3600 s). Um `ollama run` curto funcionando
não garante que o modelo processe um datasheet completo dentro desse
limite. O console do Flutter registra **somente métricas** (tempo do
cliente, tempo de carregamento, tokens, tempo de avaliação/geração e
categoria da falha); não registra conteúdo do PDF, prompts, respostas
ou credenciais. Respostas bem-sucedidas retornam métricas de execução
em nanossegundos pela API Ollama.

Se uma importação falhar, confirme o endpoint local com
`curl.exe http://127.0.0.1:11434/api/version` e uma inferência pequena
no `/api/chat`. Se ambos funcionarem, avalie `ollama ps`, memória e
logs locais durante a importação. O modo Ollama não usa OpenRouter
mesmo em caso de erro.


## Roteador de IA multicloud — extração de datasheets

Ative `AI_PROVIDER=auto` no `.env` local. A ordem de prioridade, sem
paralelismo e sem ciclos, é:

1. OpenRouter (somente modelos `:free` já validados pela política do app)
2. Google Gemini (PDF nativo)
3. Groq (texto PyMuPDF)
4. Mistral AI (texto PyMuPDF)
5. Cloudflare Workers AI (texto PyMuPDF)
6. Cohere (texto PyMuPDF)

O OpenRouter é consultado primeiro em `GET /api/v1/key` para conferir
`free_model_daily_requests.remaining` e `limit_remaining`. Uma
resposta zero pula para Gemini **sem enviar o PDF ao OpenRouter**.
Essa consulta **não garante** que não haverá limitação por minuto ou
falha do modelo: HTTP 402/429/5xx durante a inferência também pode levar
ao provedor seguinte. Quando o endpoint de quota não responde, o app
tenta a chamada real, pois a ausência de informação não comprova
limite esgotado.

Somente provedores com credenciais configuradas são tentados.
`AI_CLOUD_FALLBACK_ENABLED=true` autoriza o envio sequencial do mesmo
documento aos provedores habilitados; `false` interrompe após a
primeira falha. Falhas de requisição inválida (HTTP 400/413/422) e
arquivo PDF inválido não disparam retransmissões. Erros de
autenticação/timeout/cota/indisponibilidade de provedores podem ser
tratados como indisponibilidade da opção e avançam na sequência.

`AI_CLOUD_TIMEOUT_SECONDS=180` aplica o timeout de resposta **por
provedor**, não ao fluxo completo. Se todos atingirem timeout, o total
poderá ser elevado. APIs podem contabilizar requisições mesmo quando
o cliente recebe timeout; revise os limites do plano e configure
orçamentos adequados. Os modelos configurados para outros provedores
NÃO são necessariamente gratuitos em todas as contas. Confirme no
painel de cada provedor o plano free/trial e o bloqueio de cobrança.

Os logs locais do Flutter incluem:
`[AI Router] provider=...; evento=preflight/tentativa/selecionado/
fallback/ignorado/sucesso; modelo=...; tempo_ms=...; http=...;
motivo=...; tokens_entrada=...; tokens_saida=...`
Quando a API não retorna tokens, o campo aparece como `-`.
O código não imprime prompts, documentos, resposta da IA ou chaves.

**Privacidade e implantação:** os dados do PDF seguem para cada API
realmente utilizada na sequência, conforme a configuração habilitada.
O usuário deve usar apenas documentos que tenha autorização para enviar.
O `.env` é um arquivo local de desenvolvimento; em builds Flutter
ele pode ser extraído do pacote. Em produção, mova credenciais e
chamadas HTTP para um backend autenticado, com rate limiting e
controle de cotas.

**Compatibilidade:** `AI_PROVIDER=ollama` mantém apenas inferência
local, sem fallback; `AI_PROVIDER=openrouter` mantém a extração
anterior exclusiva do OpenRouter. Se `AI_PROVIDER` não for definido,
a configuração anterior `OLLAMA_ENABLED=true/false` continua válida.
Para usar `auto`, basta acrescentar `AI_PROVIDER=auto`, mesmo que
`OLLAMA_ENABLED=true` esteja presente no `.env`.
