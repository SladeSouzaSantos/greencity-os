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

## Navegação e posicionamento — incremento UX (2026-11-07)

Na tela **ABRIR ANÁLISE 3D**:
- A bússola no canto superior direito mostra **N, S, L e O reais**
  (Norte, Sul, Leste, Oeste), girando junto com a câmera.
- A geometria usa **X = Leste/Oeste**, **Z = Norte/Sul** e
  **Y = elevação/altura**, em metros. O plano do terreno é X/Z,
  não X/Y; o editor agora explica isso explicitamente.
- Habilite **Arrastar placas e obstáculos** e arraste o objeto
  tocando diretamente na cena. Ele se move no plano X/Z, mantendo Y.
  Isso vale mesmo após rodar a câmera, sem mover todo o enquadramento.
- **Vista superior · N ↑** coloca Norte para cima e Leste à direita.
  **Perspectiva** restaura a vista oblíqua. **Enquadrar cena** reajusta
  o enquadramento após mover objetos para fora da área inicial.
- **Editar coordenadas X / Z / Y** permite ajustar posições numéricas
  precisas em metros (inclusive negativas em X/Z; vírgula aceita).
  O campo Y é altura. Os botões de deslocamento de 0,25 m continuam
  disponíveis para ajuste fino.
- Use **Salvar cena** e reabra a tela para conferir persistência.
  O movimento modifica apenas a cena de estudo, não o arranjo elétrico
  real no orçamento.
- Testes automatizados cobrem ida-e-volta da projeção, drag em câmera
  inclinada, coordenadas geográficas na bússola e quadro de referência
  fixo enquanto arrasta.

**Limitação:** a vista Flutter nativa continua sendo projeção 3D
simplificada e não um ambiente Three.js com seleção/perspectiva GPU completa.

## Editor 3D — centro do módulo, touch e ciclo solar (2026-11-07)

1. **Altura do centro ao solo:** a configuração original
   `SolarScenario.distanceToGround` é respeitada literalmente como o
   valor Y do centro de cada módulo. O editor não eleva a placa
   automaticamente com base na inclinação. Se uma borda atravessar
   o terreno, aparece um aviso geométrico e deve-se revisar o layout.
   Em cenas antigas já salvas, o editor preserva a altura editada e
   oferece **Usar altura do centro cadastrada** para reaplicar o valor
   do projeto sem apagar as demais posições.
2. **Navegação:** toque/arraste sobre uma placa ou obstáculo para mover
   no terreno X/Z mantendo Y. Toque/arraste no terreno vazio para
   **girar a câmera**. Com dois dedos, **pinça para zoom e giro**;
   a roda do mouse aproxima/afasta no Windows. Os botões antigos
   de Oeste/Leste/Norte/Sul/Altura e os sliders de câmera/zoom
   foram retirados.
3. **Data e horário:** o controle manual de azimute/elevação solar foi
   substituído por **calendário + horário em passos de 15 minutos**.
   Há opção de reproduzir/pausar o movimento do Sol durante o dia.
   O Sol é calculado usando **latitude e longitude do SolarProject**,
   com efemérides geométricas NOAA e fuso do projeto explícito
   (UTC-3 inicial, ajustável por usuário). O fuso não é inferido
   automaticamente pelo celular nem pela longitude.
4. **Sombras visíveis:** edifícios/obstáculos e módulos geram
   projeções de sombra direta no solo conforme a data/hora; módulos
   indicam tonalidade/percentual de **área do feixe direto bloqueada**
   por raycasting. À noite não são projetadas sombras solares.
   Objetos ocultos visualmente continuam produzindo sombra;
   objetos marcados como *Ignorar na análise* não participam
   do cálculo. As perdas de irradiância mensal continuam separadas
   do motor óptico do relógio e dos efeitos elétricos MPPT.
5. **Verificação rápida:** selecionar uma placa e um obstáculo,
   avançar o horário entre 08h e 16h locais e observar deslocamento
   da sombra; trocar junho/dezembro com a mesma latitude e comparar
   trajetórias; testar zoom, rotação da câmera, ocultar e ignorar;
   conferir a altura do centro e salvar/reabrir.

### Precisão e restrições

- A posição solar da **prévia visual** não substitui pvlib/NASA POWER
  na consulta de POA mensal, e não inclui correção atmosférica de
  refração/horizonte local. Perdas de irradiância mensais usam
  `/recurso-solar/horario` (backend HSP separado).
- A sombra volumétrica desenhada no solo é o casco convexo da projeção
  dos cantos das caixas/módulos, uma **visualização aproximada**.
  A porcentagem bloqueada **na face da placa** é calculada com raycasting
  de amostras, separadamente.
- O editor não altera a geração energética comercial do GreenCity OS.
  Não tratar área sombreada como mesma porcentagem de perda elétrica.
- O controle de fuso usa offsets UTC em horas inteiras; fusos
  fracionários ou transições de horário de verão não são modelados
  pela prévia. A data/hora solar mostrada deve ser entendida como
  horário civil de referência informado pelo usuário.

## Diagnóstico 17h e HTTP 404 (07/11/2026)

### Quando uma placa indica 0% e outra tem sombra

Existem dois recursos distintos na cena: (1) casco escuro no TERRENO
— projeção visual de objetos; (2) raio incidente amostrado na FACE
FRONTAL de cada placa — calcula fração geométrica bloqueada,
não perda de potência. Um obstáculo pode sombrear apenas parte
das placas ao final da tarde mesmo projetando uma sombra grande no
solo. Ainda assim é obrigatório verificar orientação, altitude e
bloqueadores, sobretudo se a altura central do módulo colocar a
placa atravessando o plano do terreno.

No editor, selecione qualquer placa e veja: `N pontos bloqueados / total`
e quais obstáculos foram primeiro interceptados pelos raios.
A prévia do painel selecionado usa 12×8 amostras (96 pontos);
outras placas usam 8×6 (48 pontos), até limite de prévia. Uma
sombra muito fina pode escapar da malha; os valores não são uma
simulação celular nem estimativa elétrica certificada. O resultado
`sem incidência direta na face` é diferente de **0% sombreado**.

Se um módulo cruza o chão, a interface avisará e bloqueará a
estimativa mensal até ajustar as dimensões/altura. Não reajusta
automaticamente a altura central digitada no dimensionamento.

### Erro 404 ao calcular perdas mensais

Esse erro é esperado se a aplicação tenta acessar a rota
`https://hsp.greencity.net.br/api/recurso-solar/horario`,
**não implantada** em produção. Não são os containers
`hsp-solar3d-lab-*` que oferecem essa rota. No Windows, em
outro PowerShell na pasta do repositório HSP Simulator:

```powershell
git fetch origin
git switch feature/hourly-resource-api
git pull --ff-only
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m uvicorn api:app --host 127.0.0.1 --port 8000 --reload
```

Abra `http://127.0.0.1:8000/docs` para confirmar a presença
de `/recurso-solar/horario`. Não basta abrir o endereço da
rota GET no navegador: **o endpoint é POST**. Na tela Flutter,
o campo **Endpoint horário HSP** é editável sem recompilar;
clique em **Usar API local Windows · porta 8000**, selecione
mês 1 de 2023 e execute a consulta. Requer acesso à NASA POWER.

### Parar/remover somente o Solar 3D Lab antigo

```powershell
docker rm -f hsp-solar3d-lab-solar3d-web-1 hsp-solar3d-lab-solar3d-api-1
docker ps
```

Esses dois containers servem o laboratório web local da branch
`feature/solar3d-lab` (`127.0.0.1:5174` e API interna) e
**não** são necessários para o editor Flutter nativo nem para
a rota horária do HSP executada por `uvicorn api:app` local.

Não remova os containers `phasscode-platform-*`, Redis ou
PostgreSQL. Não rode `docker system prune` nem `down -v`.
