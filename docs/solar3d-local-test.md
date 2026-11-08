# Testes locais: Análise 3D GreenCity OS × HSP Simulator

## Estado atual

- [HSP Simulator PR #7](https://github.com/SladeSouzaSantos/hsp_simulator/pull/7):
  integrada a `dev`, fornece `POST /recurso-solar/horario`
  e já passou no deploy/healthcheck em DEV.
- [GreenCity OS PR #14](https://github.com/SladeSouzaSantos/greencity-os/pull/14):
  `feature/solar3d-shading-analysis`, inclui uma **prévia tridimensional
  nativa Flutter** via `CustomPainter`, com posições, obstáculos,
  seleção de placa, posição solar manual e perdas ópticas mensais.
- [HSP Solar3D Lab PR #3](https://github.com/SladeSouzaSantos/hsp_simulator/pull/3):
  preserva o protótipo Three.js do laboratório **separadamente**;
  nesta etapa o Flutter não embute o editor Three.js. A compatibilidade
  WebGL (Windows/Android) será estudada antes de substituí-lo.
- GreenCity OS PR #14 ainda não foi integrado a `main`. A nova API HSP
  está implantada em **DEV** (pipeline #42438742622 aprovado), mas
  não está comprovada em produção; usar API local/DEV durante testes.
  CI GreenCity #42441894386 aprovado e Windows homologado pelo
  relato do usuário. Android físico ainda pendente.

## 1. Inicializar a nova API HSP em Windows (PowerShell)

```powershell
git clone https://github.com/SladeSouzaSantos/hsp_simulator.git
cd hsp_simulator
git fetch origin
git switch dev
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
4. Informe ID de string e MPPT **no estudo**. O cenário é salvo automaticamente.
   Feche/reabra a tela: posições/obstáculos devem ser restaurados.
   O dimensionamento elétrico e o orçamento **não** são modificados.
5. Confirme a API HSP local/pública disponível e abra a seção
   **Calcular perdas ópticas · 12 meses**. Clique em
   **Calcular perdas ópticas por placa**. O aplicativo consulta
   janeiro a dezembro, em sequência, sem seleção de um mês isolado.
6. Confira a identificação do **ano UTC completo retornado pelo HSP**.
   O modo automático utiliza o mais recente disponibilizado pelo
   serviço (atualmente 2024 com os padrões NASA POWER), não o ano
   corrente incompleto. O resultado é HSP e perda de **irradiância**,
   não energia elétrica certificada do MPPT.

**Android:** a interface Flutter funciona nativamente; o endereço
`127.0.0.1` no emulador aponta para o próprio Android, não para o
PC. Troque por `10.0.2.2` para o emulador Android e configure
explicitamente o acesso HTTP local de desenvolvimento se necessário.
Não habilite cleartext global para produção. Primeiro homologue
a integração no Windows.

A elevação informada no editor é a altura da borda inferior da placa.
Se o centro resultante exceder o limite geométrico da cena (500 m),
a interface apresenta erro de validação e mantém o posicionamento
anterior, sem encerrar a tela.

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
- Arraste um objeto e reabra a tela para conferir a persistência automática.
  O movimento modifica apenas a cena de estudo, não o arranjo elétrico
  real no orçamento.
- Testes automatizados cobrem ida-e-volta da projeção, drag em câmera
  inclinada, coordenadas geográficas na bússola e quadro de referência
  fixo enquanto arrasta.

**Limitação:** a vista Flutter nativa continua sendo projeção 3D
simplificada e não um ambiente Three.js com seleção/perspectiva GPU completa.

### Obstáculos: altura da BASE em relação ao solo

- Para obstáculos/construções, informar `Y = 0 m` significa que a
  **face inferior está apoiada no terreno**. O editor calcula
  `Y_centro = Y_base + altura_total / 2` mantendo o contrato interno
  do raycasting, do renderer e do JSON local.
- Por exemplo: base `0 m`, altura total `3 m`, centro `1,5 m`
  e topo `3 m`. Subir a base para `2 m` posiciona o centro em
  `3,5 m`, sem mudar a altura do obstáculo.
- Alterar a altura total via slider mantém a base fixa, fazendo o
  obstáculo crescer/encolher para cima. Drag altera apenas X/Z.
- Cenas salvas continuam com `schema_version=1` e coordenadas
  internas de **centro**. Não se reinterpreta o JSON antigo. Se uma
  cena antiga tinha o centro do obstáculo em `Y=0` e altura de
  `3 m`, a tela mostrará base `-1,5 m` até o usuário escolher
  **Apoiar base no solo (0 m)**; não há migração silenciosa.
- Testar adicionar obstáculo, editar base, redimensionar, salvar,
  reabrir, conferir topo/base e comparar raycast de sombras.

## Editor 3D — referência de altura na borda inferior, touch e ciclo solar

1. **Altura da borda inferior ao solo (08/11/2026):** o usuário informa
   sempre a folga **vertical desde o terreno até o ponto mais baixo** da
   placa inclinada. `0,15 m` significa 15 cm livres sob a borda inferior,
   não 15 cm para o centro. O aplicativo calcula automaticamente:
   `Y_centro = Y_borda + (comprimento_inclinado/2)*sin(tilt) +
   (espessura/2)*cos(tilt)`. A altura interna e o campo
   `distancia_centro_modulo_chao` da API HSP v2 continuam sendo
   altura do **centro** (contrato preservado). A espessura volumétrica
   usada na prévia de módulos é de 0,045 m.
   Em cenas legadas, posições e dimensões 3D salvas permanecem com
   sua coordenada central original; **não há deslocamento silencioso**.
   Ao selecionar uma placa, o editor exibe a altura equivalente da borda,
   permite **Editar coordenadas X / Z / Y** (Y da placa = borda inferior)
   e oferece **Elevar borda inferior a 0 m** se a placa atravessar o solo.
   O botão de restauração usa a borda inferior do cadastro e alterar
   a inclinação preserva a folga da borda.
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
git switch dev
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
clique em **Usar HSP local Windows**, deixe o ano no modo
**Mais recente completo (automático)** e execute os 12 meses.
Requer acesso à NASA POWER. A fonte escolhe seu último ano
completo disponível, nunca inventa meses faltantes.

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

## Aplicação da correção óptica 3D à geração estimada (incremento de 07/11/2026)

**Objetivo:** após calcular o recurso solar horário pelo HSP e a máscara
geométrica de sombreamento por placa, recalcular a projeção de geração
exibida na tela principal do GreenCity OS, sem assumir que a perda óptica
seja uma perda elétrica I-V de string ou de MPPT.

### Fluxo de uso (Windows)

1. Abra um projeto e conclua o dimensionamento HSP normal dos arranjos.
   **Não habilite obstáculos na chamada HSP legada** se pretender
   aplicar a correção 3D: isso duplicaria a penalidade.
2. Abra **ANÁLISE 3D**. Ajuste as posições e os obstáculos. Confira se
   nenhuma placa cruza o terreno e se os **MPPTs, inclinação e azimute
   cadastrados** correspondem à cena. Valores editados apenas no 3D e
   diferentes do dimensionamento são rejeitados na aplicação.
3. Use a API HSP horária da branch `dev` ou a API pública
   homologada e execute **Calcular perdas ópticas · 12 meses**.
   Os 12 meses são obrigatórios e processados sequencialmente.
   Não é necessário selecionar mês nem ativar uma opção.
   O servidor confirma o ano meteorológico completo utilizado.
4. Clique em **APLICAR CORREÇÃO ÓPTICA NA GERAÇÃO** e confirme a
   explicação de limitações. A página 3D retorna à tela do projeto.
5. O cartão **Geração projetada · correção óptica 3D** mostra
   geração média sem e com sombra, diferença em kWh/mês e uma tabela
   recolhível de comparação para os 12 meses. Cada cartão de arranjo
   também identifica o HSP óptico estimado do respectivo MPPT.
6. **Remover correção 3D e comparar geração original** volta
   imediatamente à estimativa original e apaga os fatores salvos, sem
   apagar a cena. Abrir o editor sem alterar nada mantém a correção.
   Alterar a cena, os MPPTs ou recalcular HSP invalida o ajuste.
   O salvamento local é de uma estimativa óptica experimental,
   **não de rendimento elétrico certificado**.

### Integração numérica

Para um módulo `i` do MPPT `m`, em cada mês `k`, obtêm-se
`HSP_ref(i,k)` e `HSP_sombra(i,k)` da mesma série horária POA,
com somente a componente direta afetada pelos raios geométricos.

A retenção óptica do MPPT é:

```
retencao(m,k) =
  soma_i[Pnominal_i * HSP_sombra(i,k)]
  / soma_i[Pnominal_i * HSP_ref(i,k)]
```

A estimativa já calculada pelo GreenCity OS para esse MPPT (HSP do
grupo, fator térmico, derates, eficiência do inversor) recebe
**uma única multiplicação** por `retencao(m,k)`.
A soma dos MPPTs passa a compor a geração mensal de projeto e
consequentemente a média de 12 meses. Não se faz média simples de
percentuais de sombra e **não se multiplica percentuais individuais
em série** como se existisse curva I-V real.

Por ser uma aplicação óptica aproximada, ela NÃO calcula:
- mismatch não-linear entre módulos em série/paralelo;
- bypass/substring/células, rastreamento de MPP global nem clipping;
- perdas difusas por obstrução de céu;
- perdas/ganhos da face traseira bifacial com geometria detalhada;
- rendimento AC bancável/validado.

### Travas de consistência

- Exige exatamente **12 meses e todos os módulos**, com IDs físicos,
  potência nominal, MPPT, orientação e modelo conciliados com
  `SolarSystem` / `SolarArray` do cadastro existente.
- Recusa `SolarScenario.obstacle` legado ou
  `solarScenarioResult.shadowLossPercentage` diferente de 0%.
- Recusa módulo omitido, duplicado, abaixo do terreno ou com
  MPPT/orientação divergente do cadastro.
- Se a geometria ou o endpoint da API mudar DURANTE o cálculo, o
  resultado fica obsoleto, sem autorizar aplicação.
- Se os equipamentos, quantidades, distribuição de MPPT ou HSP-base
  forem alterados, a assinatura de projeto invalida o fator ativo.

### Critérios de homologação manual

- Cálculo base original permanece idêntico com correção desativada.
- Alterar apenas a posição de um obstáculo exige novo cálculo e
  modifica os fatores das placas atingidas, sem afetar artificialmente
  os MPPTs livres.
- Aplicar cenário 3D modifica totais mensais/anuais de geração.
- Retirar o cenário restaura os mesmos valores-base.
- Alterar MPPT na tela 3D (sem configurar o circuito real no projeto)
  é bloqueado para aplicação, não uma redistribuição elétrica silenciosa.
- Verificar resultados com HSP local e comparar com PVsyst/medição,
  antes de considerar qualquer rendimento como resultado técnico final.

## Isolamento de inversores, remapeamento de MPPT e reset (08/11/2026)

### Dois inversores sem interferência

- Cada `SolarSystem.id` identifica um **inversor diferente**.
- Cada módulo individual usa ID `inverter_id/array_index/panel_index`.
  Assim, `Inversor 1 / MPPT 1` e `Inversor 2 / MPPT 1` **não são
  a mesma entrada**: a retenção óptica é guardada em
  `groupsBySystemMppt[systemId][mpptIndex]`.
- Os IDs de novos inversores recebem `microsecondsSinceEpoch` com
  verificação contra colisão, evitando mistura acidental de dois
  inversores criados muito rapidamente.
- O cálculo óptico corrigido por MPPT é somado por inversor para
  o total do projeto. Não existe um MPPT global do projeto.

### Alterar MPPT individual de placa no 3D

- Um grupo de 4 módulos adicionado no cadastro continua sendo **um
  SolarArray original**, inicialmente no mesmo MPPT.
- Ao selecionar cada placa no laboratório, o campo
  **MPPT da placa — inversor N** permite atribuí-la a qualquer MPPT
  **existente naquele mesmo inversor**. O campo mostra o nome/modelo
  do inversor para desambiguar. Não há transferência entre inversores.
- MPPTs existentes são definidos por `inverter.mpptCount`. Um
  inversor com somente 1 MPPT não permite selecionar MPPT 2:
  isso exigiria alterar o equipamento do projeto.
- Ao recalcular os 12 meses e aplicar o cenário, a nova distribuição
  de potência por MPPT entra no cálculo experimental de geração,
  utilizando HSP-base das placas de cada grupo e o fator de
  retenção da irradiância POA.
- Não se muda automaticamente o valor de `SolarArray.mpptIndex`
  nem a ligação elétrica real do projeto. Validar tensão de partida,
  faixas Vmp, corrente, limite de strings e comportamento de bypass
  continua necessário antes da instalação.
- Na tela principal, o cartão de cada inversor exibe os MPPTs do
  **cenário 3D** (quantidade de módulos, potência e HSP corrigido)
  separadamente do(s) array(s) original(is).
- Uma mudança de distribuição de MPPT pode **aumentar ou diminuir**
  a estimativa do cenário em relação à base, independentemente da
  sombra: a comparação mostra variação assinada, não "perda" forçada.

### Reset de laboratório e cálculo original

Na página **ANÁLISE 3D** use **RESETAR ANÁLISE 3D** e confirme:
- A cena persistida `scene-<hash>.json` **apenas deste projeto**
  é excluída; os demais projetos permanecem intactos.
- Obstáculos 3D, posições, ocultações/exclusões, strings
  experimentais e remapeamento de MPPT são descartados.
- A geometria/MPPTs são reconstruídos a partir dos arrays originais.
- Os resultados mensais ópticos são descartados.
- O overlay de geração projetada 3D é retirado;
  **HSP legado sem obstáculos e resultados originais permanecem**.

O botão **Remover correção 3D e comparar geração original** da
tela principal apenas retira o efeito numérico; ele NÃO descarta
o arquivo de cena editada. Para eliminar os obstáculos e todas
as alterações da cena, utilize o reset dentro do laboratório.

### Remoção da interface legada de obstáculos no HSP

A janela **Adicionar módulos a este inversor** deixou de apresentar
`Simular Sombreamento Individual?` e seus campos de distância,
altura, largura, azimute e direção de fileira. Agora gera um
SolarScenario agrupado, com `obstacle == null`. Obstáculos
permanecem como objetos editáveis no laboratório 3D e **não**
entram na API HSP base.

### Testes locais após atualizar a branch

```powershell
git switch feature/solar3d-shading-analysis
git pull --ff-only
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Crie dois inversores, ambos com MPPT 1 e um deles com MPPT 2.
Adicione 4 placas ao primeiro como um grupo e mais placas ao segundo;
atribua no 3D somente UMA das quatro placas ao MPPT 2 do
primeiro inversor. Calcule o ano completo pelo endpoint horário
HSP local, clique em **APLICAR CORREÇÃO ÓPTICA NA GERAÇÃO** e
confirme a nova contagem por MPPT no respectivo inversor. O MPPT 1
do segundo inversor deve permanecer independente. Volte à cena,
clique **RESETAR ANÁLISE 3D**, e confira o retorno ao layout original.
Abra o modal de adição de placas: não deverá existir formulário
de obstáculos.

**Nota de engenharia:** o novo cenário altera somente o estudo
óptico, não é um circuito validado, um string design nem uma
estimativa AC confiável. Os testes automatizados não substituem
homologação visual e comparação com medições/PVsyst.

### Identificação de strings e avisos UNASSIGNED_STRING (08/11/2026)

O contador **Placas com string 0/8 · 0 bloqueios · 8 avisos** significa
que existem oito placas sem ID de string definido. Isso não é erro de API
nem falha do cálculo geométrico. É falta de topologia para auditar
Voc/Vmp/Imp/Isc **em série/paralelo**.

Duas opções:
- Selecionar cada placa e definir o campo **String da placa — estudo**,
  indicando a mesma string para os módulos realmente conectados em série;
- Usar **SUGERIR STRINGS PARA ESTUDO**, confirmar a hipótese e revisar
  o resultado. A proposta agrupa placas do mesmo arranjo original
  **e do mesmo MPPT 3D** em uma string hipotética `ESTUDO-ARRx-MPPTy`.
  O mesmo nome em inversores diferentes não mistura seus circuitos.

Após preencher, execute novamente **VALIDAR STRINGS E LIMITES DO INVERSOR**.
As sugestões não mudam o circuito Isar, nem provam instalação viável.
Uma string com apenas uma placa poderá ser bloqueada por tensão de
partida/MPPT insuficiente.

**Não confundir:** os 786/638 kWh exibidos no exemplo da interface
representam geração-base versus previsão **óptica**, não rendimentos
DC/AC calculados. O arranjo elétrico da obra requer datasheet e análise
específica antes de instalar.

### Testes de regressão da altura

- Inclinação de 20°, módulo de 2 m em retrato, altura de borda de
  0,15 m: centro aproximadamente 0,513 m (espessura 45 mm).
- Inclinação zero e borda de 0 m: centro fica a meia espessura
  do painel, sem cruzar o solo.
- Alteração da inclinação de 20° para 40° não modifica a
  altura da borda inferior escolhida.
- Cenário antigo com centro em 0,15 m continua com a
  coordenada armazenada; o usuário decide quando reajustar a borda.
- A API HSP continua recebendo `distancia_centro_modulo_chao` e
  não ganha campos de obstáculo.

## Revisão da interação Android e endpoint horário (08/11/2026)

### Gestos dentro da área 3D

O `ListView` da página deixava movimentos verticais disputarem o
reconhecedor de escala do editor; no Android a rolagem da página podia
interromper rotação/arrasto do objeto. A área 3D agora usa
`Solar3dTouchSurface` com `RawGestureDetector` e
`EagerGestureRecognizer`: o gesto iniciado dentro do canvas pertence ao
canvas, e **a página só rola fora dele**.

- **1 dedo no objeto:** seleciona e arrasta o objeto em X/Z, preservando Y.
- **1 dedo sobre o fundo:** não altera a orientação da câmera.
- **2 dedos:** cancela o arrasto em andamento; a câmera usa
  controles dedicados, para evitar conflitos com objetos.
- **Bússola N/S/L/O:** orientação horizontal; setas de giro
  e inclinação ajustam os dois eixos de rotação 3D.
- **Direcional de quatro setas:** move a vista sem deslocar objetos.
  Os comandos verticais foram invertidos após testes no celular.
- **Vista superior:** ícone junto ao N da bússola.
- **Zoom:** +/− no visor ou roda do mouse no Windows.

Testes automatizados cobrem o bloqueio do scroll do `ListView`,
movimento/cancelamento de objetos e controles independentes da câmera.

### API horária pública

Em 08/11/2026, o domínio público
`https://hsp.greencity.net.br/api/recurso-solar/horario` respondia
**404** e o esquema OpenAPI público ainda não listava a rota.
O HSP **DEV** já a implementa. **O caminho padrão do aplicativo estava
correto**, mas o backend de produção precisa receber essa versão antes
do uso no Android. A tela disponibiliza seleção explícita entre
endpoint público HTTPS e HSP local; o domínio de produção nunca deve
ser substituído automaticamente por `127.0.0.1` no Android.

## Interação mobile por controles dedicados da câmera (revisão 08/11/2026)

Após retorno de uso no Android, foi abolida a concorrência entre
arrastar objetos e girar/zoom/pan da câmera por gestos no canvas.

- A **área 3D** captura um único dedo exclusivamente para selecionar
  e mover módulos/obstáculos no plano X/Z. Soltar o dedo finaliza a
  operação. Arrastar o fundo **não gira a câmera**; dois dedos
  cancelam a edição ativa e não reconfiguram a câmera.
- O seletor de objetos considera faces 3D (topo, base e laterais
  de obstáculos), respeita `hiddenIds` e usa 18 px de tolerância.
- **Câmera 3D dedicada:** bússola interativa N/S/L/O define o azimute
  horizontal; setas `↑`/`↓` alteram o **pitch** (inclinação da
  câmera), de modo que a vista continua sendo 3D e não apenas
  rotação de imagem 2D. Botão central restaura a perspectiva.
- **Zoom:** botões sobrepostos `+` e `−`; roda do mouse preservada
  no Windows. As ações de câmera não movem a geometria nem alteram MPPT.
- Durante um arrasto, reusa-se a última visualização das máscaras
  de sombra; o raycasting volta a atualizar ao soltar o objeto.
  Isso evita trabalho geométrico caro em cada pixel do toque no celular.
- Testes de regressão: toque/arrasto isolado do `ListView`, cancelamento
  ao inserir segundo dedo, botões de câmera, faces laterais dos
  obstáculos e tolerância de toque de painéis pequenos.

**Smoke manual Android:** testar módulo e lateral do obstáculo com um
dedo, arrastar o fundo e confirmar que a vista não gira, mudar N/L/S/O,
inclinar com ↑/↓, zoom +/−, salvar/reabrir e executar HSP.

## Navegação 3D incremental e direcional de câmera

- Na bússola N/S/L/O, os dois botões de giro **esquerda/direita**
  modificam `yaw` em passos de 0,18 radianos. As setas de
  inclinação **↑/↓** continuam mudando `pitch` em passos de 0,16.
  São dois eixos de rotação 3D, independentes da geometria solar.
- Um segundo direcional de quatro setas, **MOVER VISTA**, aplica
  deslocamentos de 32 pixels à projeção da câmera (cima/baixo/
  esquerda/direita) sem editar X/Z/Y dos objetos.
  O centro do direcional restaura apenas `cameraPan`.
- O zoom continua nos botões + e -, sem interferência no arrasto de
  objetos. A altura mínima da viewport 3D passa a 390 px para impedir
  que controles de orientação e deslocamento se sobreponham em
  celulares de tela menor.

## Digitação das medidas e coordenadas dos obstáculos

Ao tocar em **Adicionar obstáculo**, o editor abre um diálogo
numérico com X (leste/oeste), Z (norte/sul), altura da **base** Y,
largura, profundidade, altura **total** e azimute. Cancelar não adiciona
um objeto temporário à cena. Ao selecionar um obstáculo salvo, o botão
**Digitar medidas e posição do obstáculo** reabre o mesmo editor.

- Valores podem ser digitados com vírgula ou ponto decimal;
  coordenadas X/Z admitem sinal.
- A cena só é atualizada após validação **atômica de todos os campos**;
  valores inválidos não deixam parte do objeto modificada.
- Altura da base `0 m` deixa a face inferior no solo.
  Após alterar altura total, `centroY = base + alturaTotal / 2`.
- Largura, profundidade e altura devem ser positivas, até 1.000 m;
  X/Z limitados a ±500 m; a base e o centro resultante devem
  respeitar os limites geométricos.
- O formulário preserva o ID e o tipo do objeto, e mantém o formato
  de persistência JSON v1. Os sliders permanecem disponíveis como
  controle rápido, inclusive para medidas fora do alcance inicial de
  20 m (expansão dinâmica do controle).

## Correção de oclusão 3D e localização solar visível (08/11/2026)

- Caso relatado: obstáculo de **5 m** (topo Y=5) e placa cuja
  **borda inferior** fica a **5,5 m** no mesmo X/Z. Na vista superior,
  a placa deve aparecer **na frente** do obstáculo, não atrás.
- Causa diagnosticada: o pintor usava ordenação decrescente da
  profundidade do **centro**; pintava primeiro o mais próximo e
  cobria-o com o objeto de trás.
- Solução: ordenar a pintura da face mais distante para a mais
  próxima, considerando o ponto visível mais próximo entre os oito
  vértices transformados de cada volume, e não só o centro.
  `Solar3dObjectPicker` usa a ordem inversa para selecionar o
  elemento visível no toque.
- Testes: placa com borda a 5,5 m sobre obstáculo de topo 5 m;
  situação inversa de placa abaixo do topo do obstáculo; rotação
  azimutal da vista superior; seleção coerente ao tocar.
- O motor de sombreamento e as coordenadas dos objetos **não foram
  modificados**. Trata-se de correção de profundidade da exibição.
  Em geometrias intersectadas complexas, a prévia Flutter ainda
  utiliza ordenação por objeto, não um z-buffer de polígonos.
- A latitude e a longitude de `widget.project` agora aparecem com
  **6 casas decimais** imediatamente antes da cena 3D, com nomes
  explícitos, e na seção de sombra. São exatamente os mesmos campos
  enviados a `Solar3dSunPosition.calculate` e
  `SolarResourceHourlyDataSource.getHourlyResource`, não a posição
  automática do aparelho.

## Consolidação do editor móvel — revisão 08/11/2026

### Erro de altura da placa e ciclo de vida

O editor antigo criava três `TextEditingController` no método
`_editPosition` e os descartava imediatamente após o retorno
de `showDialog`, mesmo com a rota ainda em animação de fechamento.
Esse padrão pode provocar falhas de dependências no Flutter como
`_dependents.isEmpty`. A edição X/Z/altura da **borda inferior**
agora utiliza `Solar3dPositionDialog`, com `TextFormField`
próprios e sem descarte prematuro. A edição de string de estudo
também não descarta controlador antecipadamente.
Teste: editar borda inferior para **5,5 m**, confirmar, voltar
e editar novamente sem exceção ou alteração de MPPT.

### Faces volumétricas e perspectiva

A pintura anterior ordenava objetos inteiros pelo maior valor de
profundidade, mas um obstáculo possui frente/topo/laterais que podem
ficar em posições diferentes em relação à placa em ângulo inclinado.
Agora o editor transforma e projeta as **seis faces de cada volume**
individualmente, ordena as faces pelo valor médio de profundidade
e pinta de trás para a frente. O seletor calcula a profundidade no
ponto tocado usando interpolação baricêntrica, coerente com a câmera
ortográfica. O cálculo físico por raio **não foi alterado**.

Regressões: obstáculo de 5 m, placa acima com borda a 5,5 m,
placa abaixo do topo do obstáculo, vista superior e vistas
oblíquas. A prévia não implementa z-buffer rasterizado; geometrias
intersectadas/com faces que cruzam podem ainda precisar de um
renderizador 3D com profundidade por pixel.

### Menos poluição visual e ano meteorológico

O visor mantém botões +/−, bússola e setas de movimentação, mas
remove os três atalhos redundantes abaixo da imagem. O ícone
da vista superior fica junto do N. As seções **Trajetória solar**,
**Objetos/MPPTs**, **Auditoria elétrica**, **Calcular perdas ópticas**
e **Aplicar correção** podem ser recolhidas/expandidas.

A consulta óptica é **sempre anual**, mês a mês de janeiro a
dezembro. A seleção padrão do período é **Mais recente completo
(automático)**: a API HSP decide o último ano UTC coberto
integralmente. O aplicativo valida que todas as requisições mensais
usaram o **mesmo ano** e mostra aquele retornado pelo servidor.
Com a configuração padrão da fonte NASA POWER, o ano completo mais
recente é **2024**; assim que a fonte for ampliada, pode avançar
automaticamente. Não usa um 2026 incompleto.

## Homologação pós-teste Android: GlobalKey, MPPTs e autosave (08/11/2026)

### Erros observados no Android

- Ao editar MPPTs de placas e calcular perdas ópticas, o Flutter
  reportou `A GlobalKey was used multiple times inside one widget's
  child list`, citando duas `NotificationListener<ScrollNotification>`.
  Em seguida, ocorreu `_dependents.isEmpty` ao desmontar a árvore.
- Para não tentar "consertar" a física por causa de um erro visual,
  a correção atua no ciclo de vida dos controles: o grupo recolhível
  deixa de reter `Scrollable`/formulários enquanto está fechado e
  deixa de usar `ExpansionTile` com estado oculto persistente.
  O seletor de MPPT usa `DropdownButton<int>` com chave de identidade
  da placa, sem `DropdownButtonFormField` temporário e chave alterada
  por cada MPPT. Os dados da seleção permanecem no documento da cena.
- Nova regressão de widgets combina mudança de MPPT, seção com
  `SingleChildScrollView` horizontal, fechamento e reabertura
  sem exceção.
- A análise óptica de 12 meses e os limites reais por inversor
  permanecem inalterados; reatribuição de MPPT vale apenas
  para o estudo 3D e requer MPPT existente no próprio inversor.

### Navegação e persistência

- **MOVER VISTA**: setas esquerda/direita foram invertidas para
  corresponder ao movimento percebido no Android. As setas
  cima/baixo já tinham sido corrigidas e foram preservadas.
- Removidos os botões de salvamento manual do cabeçalho e da
  lista de objetos. Agora toda modificação válida (obstáculo,
  altura, posição, azimute, inclinação, MPPT, string, visibilidade
  e exclusão) gera um salvamento local automático após 350 ms
  sem edições, com gravações **serializadas** para impedir
  sobrescritas fora de ordem. Ao sair da tela, a última
  alteração pendente é gravada. O comando **Resetar análise 3D**
  continua apagando o documento local após concluir operações
  anteriores.
- O salvamento automático guarda **a cena**. Os fatores
  ópticos dos 12 meses são salvos somente ao confirmar
  **APLICAR CORREÇÃO ÓPTICA NA GERAÇÃO**, vinculados à cena
  e à assinatura do dimensionamento/HSP. Uma mudança de geometria
  ou MPPT invalida o ajuste; não persiste ligação elétrica física.

### Cenário de microinversores

- Regressão com **3 microinversores**, **4 placas por arranjo** e
  **MPPT 1 em cada inversor**. Parte das placas é remapeada
  para o MPPT 2 do **mesmo** microinversor (quando cadastrado);
  verifica que as doze placas são contabilizadas exatamente uma
  vez e que o fator óptico não é misturado entre inversores.
- O teste óptico não certifica a ligação elétrica de microinversores
  físicos, especialmente se o datasheet não permite esse
  agrupamento ou possui somente um MPPT.

**Smoke Android pendente:** trocar MPPT das placas em três inversores,
abrir/calcular 12 meses, expandir/recolher seções e aplicar a
correção; não pode haver exceções de `GlobalKey` ou
`_dependents.isEmpty`. Reabrir a tela **sem** botão de salvar
e conferir todas as posições e os MPPTs remapeados.

## Persistência da correção óptica aplicada (08/11/2026)

A causa da perda ao reabrir o editor era a limpeza incondicional de
`widget.project.opticalCorrection` ao navegar, além da ausência de
arquivo para os fatores mensais. O problema foi corrigido em dois pontos:

1. **Abrir e fechar o 3D sem modificar nada** preserva os fatores
   ópticos e a geração ajustada.
2. **Aplicar correção** confirma a auditoria e os 12 meses, força
   a gravação da cena em `scene-<hash>.json` e persiste um
   `optical-<hash>.json` local vinculado à mesma cena.
3. A persistência óptica inclui o ano UTC, a assinatura dos
   equipamentos/arranjos/HSP, contagem de módulos e, para cada
   **inversor e MPPT**, potência, HSP de referência e 12 fatores.
4. Ao abrir novamente o projeto, restaura os valores **sem consultar
   novamente a API HSP**, desde que o projeto ainda possua os mesmos
   sistemas e HSP de referência, a cena seja idêntica e os MPPTs
   mantenham a contagem de placas esperada.
5. Qualquer modificação de geometria, MPPT, string ou visibilidade
   limpa a correção antiga; o próximo ajuste exige novo cálculo dos
   12 meses. **Remover correção** apaga apenas os fatores.
   **Resetar Análise 3D** elimina também a cena.

O arquivo salvo não representa engenharia elétrica homologada
(curvas I–V, diodos bypass, mismatch ou perdas DC/AC).

**Regressão:** aplicar, voltar, abrir 3D de novo e voltar sem
alterar nada (geração igual); reabrir um projeto com os mesmos
sistemas (restaura); alterar MPPT e sair (invalida fatores, preserva
cena); remover correção (mantém obstáculos); invalidar projeto
por alteração de arranjos/HSP (recusa o arquivo).

## Regressão: listas editáveis na criação de inversores (08/11/2026)

Depois da restauração de correção óptica, `SolarProjectDesignerPage.initState`
passou a atribuir a lista `project.systems` diretamente a `systems`.
Um projeto recém-criado tinha `SolarProject.systems = const []`, portanto
a ação **CRIAR SISTEMA** falhava com `Unsupported operation: Cannot add to
an unmodifiable list`. O mesmo risco existia para
`SolarSystem.arrays = const []` no primeiro arranjo.

A página agora usa `List<SolarSystem>.of(project.systems)` e mantém
`project.systems` sincronizado ao adicionar um inversor. Os construtores
de `SolarProject` e `SolarSystem` também copiam as listas fornecidas,
de modo que seus agregados editáveis nunca mantenham uma lista
`const` ou `List.unmodifiable` recebida como argumento.

**Teste manual:** criar um novo projeto → adicionar inversor →
adicionar primeiro arranjo → adicionar segundo inversor →
abrir Análise 3D → voltar. Não deve ocorrer `Unsupported operation`.
A troca de inversores/arranjos invalida qualquer correção óptica
anterior incompatível, mas não interfere com o armazenamento da cena.
