# Testes locais: Análise 3D GreenCity OS × HSP Simulator

## Estado atual

- [HSP Simulator PR #7](https://github.com/SladeSouzaSantos/hsp_simulator/pull/7):
  `feature/hourly-resource-api`, fornece `POST /recurso-solar/horario`.
- [GreenCity OS PR #14](https://github.com/SladeSouzaSantos/greencity-os/pull/14):
  `feature/solar3d-shading-analysis`, inclui uma **prévia tridimensional
  nativa Flutter** via `CustomPainter`, com posições, obstáculos,
  seleção de placa, posição solar manual e perdas ópticas mensais.
- [HSP Solar3D Lab PR #3](https://github.com/SladeSouzaSantos/hsp_simulator/pull/3):
  preserva o protótipo Three.js do laboratório **separadamente**;
  nesta etapa o Flutter não embute o editor Three.js. A compatibilidade
  WebGL (Windows/Android) será estudada antes de substituí-lo.
- Nada foi integrado a `main` ou publicado no servidor. O novo endpoint
  precisa rodar localmente ou ser homologado em DEV antes da consulta
  do GreenCity OS.

## 1. Inicializar a nova API HSP em Windows (PowerShell)

```powershell
git clone https://github.com/SladeSouzaSantos/hsp_simulator.git
cd hsp_simulator
git fetch origin
git switch feature/hourly-resource-api
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m pytest -q
python -m uvicorn api:app --host 127.0.0.1 --port 8000 --reload
```

Swagger local: `http://127.0.0.1:8000/docs`.

Em **outro terminal**:

```powershell
$payload = @{
  latitude = -5.79448
  longitude = -35.21101
  inclinacao_graus = 15
  azimute_graus = 0
  fonte_dados = 'NASA POWER'
  ano_utc = 2023
  mes_utc = 1
} | ConvertTo-Json
$r = Invoke-RestMethod -Method POST -Uri 'http://127.0.0.1:8000/recurso-solar/horario' -ContentType 'application/json' -Body $payload
$r.periodo.horas_retornadas  # 744
$r.amostras[0]
```

A primeira consulta NASA POWER pode exigir acesso à internet e
processamento. Alternativamente, o dashboard HSP tradicional permanece em
`python -m streamlit run dashboard.py`, abrindo `http://localhost:8501`.
A interface de obstáculos tradicional do HSP continua por
retrocompatibilidade, separada do futuro editor do GreenCity.

### Editor React/Three.js legado (opcional, isolado)

Ainda no repositório HSP, sem abandonar a branch horária:

```powershell
git worktree add ..\hsp-solar3d feature/solar3d-lab
cd ..\hsp-solar3d
docker compose -f solar3d/compose.yaml up --build -d
```

Abra `http://127.0.0.1:5174`. Esse protótipo é uma
implementação separada da experiência do GreenCity.

## 2. GreenCity OS em Windows

```powershell
git clone https://github.com/SladeSouzaSantos/greencity-os.git
cd greencity-os
git fetch origin
git switch feature/solar3d-shading-analysis
if (!(Test-Path .env)) { Copy-Item .env.example .env }
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter devices
flutter run -d windows --dart-define=HSP_HOURLY_URL=http://127.0.0.1:8000/recurso-solar/horario
```

No aplicativo, abra um projeto, adicione inversor e módulos, e selecione
**ABRIR ANÁLISE 3D**. Teste:
1. Selecione placas individuais e confira fabricante/modelo/MPPT.
2. Ajuste a câmera, mova uma placa, adicione um obstáculo e varie a
   posição solar **manual**; isso é uma prévia geométrica.
3. Use **Ocultar** para esconder sem afetar a análise;
   **Ignorar na análise** para remover o objeto apenas do raycasting.
   Nenhum deles remove fisicamente uma placa do inversor.
4. Informe ID de string e MPPT **no estudo** e salve.
   Feche/reabra a tela: posições/obstáculos devem ser restaurados.
   O dimensionamento elétrico e o orçamento **não** são modificados.
5. Confirme API HSP local ativa, selecione janeiro de 2023 e clique
   **Calcular perdas ópticas por placa**. O resultado é HSP em
   kWh/m²/dia e perda percentual de **irradiância**, não perda de
   energia elétrica do MPPT.
6. **Calcular 12 meses** chama a API mês a mês e pode demorar.
   Comece por um mês e 2–6 placas; o limite síncrono impede cenas
   grandes e orientações demais.

**Android:** a interface Flutter funciona nativamente; o endereço
`127.0.0.1` no emulador aponta para o próprio Android, não para o
PC. Troque por `10.0.2.2` para o emulador Android e configure
explicitamente o acesso HTTP local de desenvolvimento se necessário.
Não habilite cleartext global para produção. Primeiro homologue
a integração no Windows.

## Limitações/segurança

- O editor desta entrega usa **renderização volumétrica nativa Flutter**,
  não ainda o WebGL Three.js compartilhado. Está adequado a seleção e
  alterações iniciais; performance e qualidade visual exigem avaliação.
- A cena salva fica localmente em
  `getApplicationSupportDirectory()/solar3d/scene-*.json`, com
  identificador hash derivado do projeto. Não há sincronização com Isar
  de strings individuais, nem migração automática ao orçamento.
- As posições geradas a partir de arranjos são uma grade ilustrativa,
  **não um levantamento real do telhado**.
- A cena e a análise só consideram objetos opacos em forma de caixas,
  com sombreamento do feixe direto. Difusa, reflexões locais, terreno,
  modelos de vegetação e efeitos elétricos permanecem fora de escopo.
- O recurso horário sem obstáculos precisa coincidir com inclinação e
  azimute da placa. O app recusa usar POA de orientação diferente.
- A atribuição de string no editor ainda não representa sua conexão em
  série validada, nem as limitações reais dos MPPTs.
- Resultados parciais/mês não devem ser tratados como rendimento anual
  certificado. Validação adicional com PVsyst/medições segue pendente.
