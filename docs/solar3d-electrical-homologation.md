# Homologação Solar3D — etapas óptica, DC e AC

**Revisão:** 08/11/2026
**Branch:** `feature/solar3d-shading-analysis`
**Status:** pré-homologação automatizada; **não é homologação elétrica de projeto
para instalação**. Não promover resultados experimentais a propostas com
geração AC garantida. PR #14 permanece draft, sem merge.

## 1. Contrato das três etapas

| Etapa | O que calcula | Situação | Onde |
| --- | --- | --- | --- |
| Óptica | HSP `sem sombra` vs `com sombra` por placa, mês e MPPT | Implementada e testada | `solar3d_geometric_shading.dart`, `solar3d_optical_correction.dart` |
| DC elétrico: viabilidade | Voc/Vmp/Isc/Imp de strings em série/paralelo, mínimo de partida/MPPT, limites de corrente e Voc frio preliminar | Implementada como **auditoria** — não como yield | `solar3d_electrical_audit.dart` |
| DC elétrico: mismatch/bypass | Curva I-V real por módulo/substrings; corrente compartilhada nas séries; tensão comum nas strings paralelas por MPPT | **Não calibrado**, não deve ser descontado na geração comercial | Futuro modelo físico, dependendo de datasheets completos/ensaio |
| Conversão AC | Eficiência nominal usada pelo dimensionamento original | Já incluída na geração-base, **não aplicar novamente** | `SolarSystem.calculateSystemGenerationForMonth` |
| Perdas AC avançadas | Curva de eficiência em função de DC/V/T, clipping/partida reais, perdas de cabo AC | **Não modeladas** | Exige modelo/curva de inversor + dados horários + validação |

Fórmulas de referência para a próxima etapa elétrica, **não implementadas
como resultados certificados**:

- Série: para uma corrente comum I, a tensão total da string é
  `V_string(I) = Σ V_module_j(I)`.
- Paralelo no mesmo MPPT: para uma tensão comum V, a corrente total é
  `I_mppt(V) = Σ I_string_s(V)`.
- MPPT idealizado: `Pdc,max = max_{V permitido}[V × I_mppt(V)]`.
- AC, apenas depois de conhecer curva de rendimento: 
  `Pac = min(Pac_nominal, eta(Pdc,V,T) × Pdc)`.

Os quatro valores STC Voc/Vmp/Isc/Imp **não definem uma curva I-V física
única**; tampouco fornecem layout de células, diodos de bypass ou
coeficiente de Vmp. Não inferir topologia half-cut/TOPCon genérica.

## 2. Auditoria elétrica implementada

No laboratório Flutter, selecione cada placa e informe uma string explícita
(ex.: `S1`) no MPPT do **seu próprio inversor**. Use
**VALIDAR STRINGS E LIMITES DO INVERSOR**.

A auditoria:
- agrega tensões Voc/Vmp **em série** e aplica a corrente limitada pelo
  módulo de menor Imp/Isc nessa string para inspeção em STC;
- agrega correntes **das strings em paralelo** no MPPT;
- verifica faixa Vmp STC, tensão de partida, limite Voc absoluto, estimativa
  de Voc frio quando existe temperatura mínima climática do projeto,
  correntes Impp/Isc por rastreador (detalhes por MPPT quando fornecidos),
  potência DC recomendada e contagem de entradas especificadas;
- sinaliza strings sem ID, usadas em dois MPPTs de um mesmo inversor,
  módulos não identificados, modelos sem dados STC utilizáveis;
- separa chaves de MPPT por `SolarSystem.id`, para não misturar inversores
  diferentes usando os mesmos nomes `MPPT 1` e `S1`.
- não usa o coeficiente de potência como se fosse coeficiente térmico de Vmp;
  por isso, mesmo sem bloqueios STC, **não declara tensão hot-cell validada**.

**Atenção térmica:** Voc frio calculado com temperatura mínima ambiente
é apenas um indicador; o dimensionamento definitivo deve verificar a
mínima temperatura de célula de projeto. Máxima tensão real, proteção
e aterramento precisam de revisão de engenharia.

A auditoria tem resultados:
- **Bloqueio:** incompatibilidade clara com limite documentado em STC
  (ex.: apenas 1 módulo de Vmp 41 V em MPPT com Vmin 50 V).
- **Aviso:** dados incompletos, entradas DC, paralelismo ou pressupostos
  ainda não revisados.
- **Informativo:** variáveis físicas não calculadas.

Uma cena com bloqueios pode continuar sendo **comparada apenas como cenário
óptico**, mediante aviso, mas **não** deve ser considerada viável eletricamente
ou usada como previsão AC de projeto executável.

## 3. Critérios automatizados de aceite

- [x] Fluxo de projeto não depende da API HSP para mover/visualizar 3D.
- [x] HSP / recurso horário permanece sem obstáculos e resultados ópticos
  podem ser revertidos sem duplicar perdas antigas.
- [x] MPPT 1 de dois inversores diferentes é isolado por `systemId`.
- [x] Quatro placas originalmente num array podem ser alocadas 3+1
  no cenário 3D, sem modificar `SolarArray.mpptIndex`.
- [x] Auditoria recusa inferir string elétrica sem atribuição explícita.
- [x] Auditoria detecta Vmp STC inferior ao mínimo MPPT,
  corrente paralela excessiva, string atravessando dois MPPTs.
- [x] Múltiplos inversores podem ter a mesma ID de string sem
  interconexão acidental.
- [x] Flutter Analyze + testes rodados em Linux no CI.
- [x] Compilação e testes Windows de CI: aprovada no SHA `0a175922`.
- [ ] Compilação APK Android de CI: aguardando validação do manifesto
  compatível com AGP no `isar_flutter_libs 3.1.0+1`.
- [ ] Smoke manual Windows em hardware real para salvar/resetar/analisar
  com tela grande e arrasto/zoom.
- [ ] Smoke manual Android (toque, pinça, persistência, desempenho).
- [ ] Benchmark de motor elétrico calibrado versus PVsyst/ensaios e
  medição de sombreamento real (não disponível).

## 4. Smoke manual recomendado no Windows

1. `flutter pub get`, `flutter analyze`, `flutter test`,
   `flutter run -d windows` em `feature/solar3d-shading-analysis`.
2. Abra um projeto com dois inversores, ambos com MPPT 1.
   Ajuste posições, salve, feche e reabra: IDs, strings e obstáculos
   devem ser recuperados corretamente.
3. Configure em um inversor apenas **uma placa em MPPT 2**, com
   `String = S2`. A auditoria deverá apontar subtensão caso Vmp
   nominal do módulo seja inferior à tensão mínima do MPPT.
4. Ligue duas strings paralelas ao MPPT 1; confira soma de Impp/Isc e
   alertas de sobrecorrente, conforme os limites dos **datasheets reais**.
5. Repita `String = S1` em outro inversor: não deve haver conflito.
6. Calcule HSP anual óptico via nova API HSP local e aplique para
   comparar **somente** valores ópticos, sem declará-los perdas DC/AC.
7. Restaure geração original e use `RESETAR ANÁLISE 3D`;
   confira ausência de resíduos no cenário salvo.
8. Alterar/inserir módulos deve invalidar os resultados anteriores
   e exigir nova análise.

## 5. Itens ainda necessários para a homologação elétrica

- Datasheet oficial das placas: curva I-V, topologia de células
  e substrings/diodos bypass, coeficiente de Vmp ou modelo de diodo
  ajustado a vários pontos/condições.
- Dados do inversor: MPPTs/entradas, tensões/correntes por tracker,
  eficiência versus carga/tensão/temperatura, potência nominal e clipping.
- Arranjo real: identificação das strings em série e paralelo,
  azimute/inclinação, altitude do centro, geometria dos obstáculos.
- Modelo horário fisicamente consistente do mesmo sistema com/sem sombra;
  ensaio contra PVsyst e campo. O protótipo HSP F5.2 atual usa
  **três substrings genéricas** e ainda não é calibrado.
- Homologação funcional da integração visual Three.js/WebGL no Android
  e Windows. A UI nativa Flutter é funcional, mas a paridade com o
  laboratório web permanece issue #15.

**Decisão de release:** manter PR #14 em draft até aprovação manual
do smoke Windows/Android, build Windows, e fechamento do escopo
**óptico**. A fase **elétrica** permanece identificada separadamente
na issue #16; nenhuma perda elétrica não validada será embutida
automaticamente na geração estimada.

## Correção de referência de altura e strings sugeridas (08/11/2026)

O formulário de adicionar módulos e a tela 3D passam a apresentar
**altura da borda inferior ao solo** para placas, convertendo
internamente para a altura do **centro** exigida pelo backend HSP.
Não altera posições de projetos/cenas antigos sem ação explícita.
O HSP de produção permanece intacto.

Mensagens `UNASSIGNED_STRING` são avisos de preenchimento, não falhas
de simulação. `Solar3dStudyStringSuggestions` propõe apenas
**ligações hipotéticas de estudo**, com aceite manual e revisão
posterior da auditoria. Nenhuma recomendação automática estabelece
o número real de strings do sistema.

## Compatibilidade Isar/Android — correção em homologação

O Android Gradle Plugin exige namespace explícito e não aceita mais o
atributo `package` dentro do manifesto de bibliotecas. O Isar 3.1.0+1
possui manifesto de biblioteca vazio (exceto namespaces XML e o atributo
`package="dev.isar.isar_flutter_libs"`). O arquivo versionado
`android/compat/isar_flutter_libs/AndroidManifest.xml` fornece o
manifesto vazio equivalente sem o atributo obsoleto. O projeto Android
registra `namespace` e redireciona somente `main.manifest` desse plugin
via callback `com.android.library`; não altera o pub-cache.

Critério de aceite: job `Android debug APK build` inteiramente verde,
seguida de smoke em Android físico. A correção não prova, por si só, que
persistência Isar, seleção 3D ou gesto pinça funcionem no dispositivo.
