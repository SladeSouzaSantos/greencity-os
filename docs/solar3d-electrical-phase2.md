# Solar3D — Fase 2: motor elétrico calibrável

**Data:** 08/11/2026  
**Branch de laboratório:** `feature/solar3d-electrical-phase2`  
**PR:** [#20 — draft](https://github.com/SladeSouzaSantos/greencity-os/pull/20)  
**Epic:** [#16](https://github.com/SladeSouzaSantos/greencity-os/issues/16) e subissues
[#17](https://github.com/SladeSouzaSantos/greencity-os/issues/17),
[#18](https://github.com/SladeSouzaSantos/greencity-os/issues/18),
[#19](https://github.com/SladeSouzaSantos/greencity-os/issues/19).

## Objetivo e princípio físico

Estimar energia DC e AC com e sem sombras sob as **mesmas condições
meteorológicas**, respeitando a topologia real de módulos em série,
strings em paralelo, substrings, bypass, limites de cada MPPT e
curvas de eficiência de inversores. A abordagem atual é opt-in e
experimental, **sem tocar na correção óptica homologada**.

Não é correto deduzir parâmetros de um diodo simples de apenas
`Voc/Isc/Vmp/Imp`: esses dados de placa não identificam
inequivocamente a curva física. Fontes de modelagem:

- [pvlib Single Diode Models](https://pvlib-python.readthedocs.io/en/stable/reference/pv_modeling/sdm.html):
  De Soto, CEC e PVsyst, com cinco parâmetros.
- [pvlib calcparams_desoto](https://pvlib-python.readthedocs.io/en/stable/reference/generated/pvlib.pvsystem.calcparams_desoto.html):
  irradiância, temperatura, resistências e corrente de saturação.
- [pvlib Bishop88](https://github.com/pvlib/pvlib-python/blob/main/pvlib/singlediode.py):
  referência para comparação de resultados sob sombra/parcial,
  tensões negativas e bypass.

## Estado da implementação

| Etapa | Código acrescentado | Gate que falta |
| --- | --- | --- |
| F2.1 — curva I–V/P–V | `electrical/solar3d_single_diode.dart`: five-parameter, solver por bissecção, MPP e temperatura | Calibrar módulos de datasheet/ensaio, comparar numericamente com pvlib/SAM |
| F2.1 — strings reais | `electrical/solar3d_string_design.dart`: ordem explícita de placas, MPPT e IDs por inversor | UI para configurar ordem física e importar diagramas reais |
| F2.1 — série/paralelo | `electrical/solar3d_circuit_solver.dart`: corrente comum em série, tensão comum no paralelo, máximo global MPPT e limites I_sc/I_mp | Benchmark elétrico com dispositivos reais, convergência/numerical profiling |
| F2.2 — espacial e bypass | `Solar3dGeometricShading.inspectPanelGrid` e `electrical/solar3d_substring_irradiance.dart`: máscara espacial e substring com bypass documentado | Layout celular exato do fabricante, calibração de diodos e estudos PVsyst |
| F2.3 — DC/AC horários | `electrical/solar3d_hourly_electrical.dart`: mesmo clima na comparação, eficiência por carga, perdas I²R e clipping, agregação parcial | Eficiência/partida real do inversor, modelo térmico, worker anual 8760/8784 horas |
| UI e persistência | Seção `Fase 2 · Motor elétrico experimental`, formulário de parâmetros físicos, registro local versionado por modelo/STC | Catálogo de parâmetros calibrados, dados reais de fabricante e fluxo completo de configuração |

**Os testes atuais são numéricos/sintéticos**, NÃO validação
experimental de um modelo comercial. O campo
`independentlyVerified` não é marcado como verdadeiro por
simples cadastro manual.

## Contrato do modelo de diodo (por módulo ou substring)

Parâmetros *obrigatórios*, obtidos por fitting/ensaio com fonte:

- `ilRefA`: corrente fotogerada `IL_ref` em A.
- `ioRefA`: corrente de saturação `I0_ref` em A.
- `rsOhm`: resistência série em ohms.
- `rshRefOhm`: resistência shunt em ohms.
- `aRefV`: `n × Ns × k × T/q` na condição de referência, em V.
- `seriesCells`: número real de células efetivamente em série.
- `alphaScAperC`: coeficiente `Isc` em A/°C (não %/°C).
- `bandGapEv` com fonte e adequação tecnológica, default 1,121
  eV no exemplo de silício cristalino; não generalizar a outras
  tecnologias.
- `source`: origem/versão/documento rastreável.

Cada perfil é vinculado à identidade do catálogo (modelo, STC,
tecnologia e dimensões). Mudança do registro invalida o lookup
anterior. É guardado em suporte local, **fora do esquema Isar**.

## Topologia e sombreamento

- A ordem física dos módulos em série é **declarada**, não inferida
  a partir de coordenadas 3D. Não misturar placas de inversores
  diferentes ou ligar a mesma placa a dois circuitos.
- O raycast devolve máscara da face por amostras `rows × columns`.
  A repartição dessas amostras entre substrings exige mapeamento
  físico fornecido pelo fabricante. Se há mais de uma substring,
  rejeita bypass ou topologia não documentados.
- A irradiância efetiva de cada substring é aproximada por
  `G = POA_difusa + POA_refletida + POA_direta × (1 - máscara)`.
  IAM, vista de céu, mismatch intramódulo de células, albedo
  obstruído, reflexões e perdas espectrais **ainda não são
  modelados**. Uniformizar a sombra de todo módulo é proxy,
  nunca modelo real de bypass.
- O modelo anual NÃO pode multiplicar novamente os resultados
  de `Solar3dOpticalCorrection`: a perda direta é aplicada à
  irradiância de entrada uma única vez.

## Energia horária (laboratório isolado)

O cálculo compara potência no mesmo instante UTC (sem sombra vs
com sombra) para cada MPPT de cada inversor, com:

- corrente operacional limitada (clipping) e limite Isc absoluto
  tratado como incompatibilidade, não como clipping;
- `P_cabo_DC = I_MPPT² × R_DC` e
  `P_cabo_AC = N_fases × I_fase² × R_fase`, quando as resistências
  reais forem informadas;
- eficiência de inversor interpolada de curva `η(P_DC/P_AC_nom)`,
  partida e limite AC nominal. Nunca supor que `maxEfficiency`
  do catálogo é uma curva completa.
- relatório anual somente com horas contíguas UTC e dados
  meteorológicos completos. Atualmente o modo síncrono limita
  a janela a 24 horas por padrão, **não executa um ano inteiro
  no Android**.

Para projetar temperatura de célula em vez de medi-la, precisamos
de temperatura ambiente, vento, tipo de montagem e um modelo
térmico validado. A rota HSP horária atual é um contrato POA,
não fornece todos esses parâmetros elétricos/térmicos.

## Gates obrigatórios para considerar "finalizado"

1. Selecionar módulos/inversores **reais**, anexar datasheets e
   registrar a extração confiável de coeficientes físicos,
   circuitos de bypass e eficiência, sem estimativa por IA sem
   conferência.
2. Ajustar/identificar curvas I–V em STC e ao menos duas outras
   condições (temperatura/irradiância); comparar erro relativo e
   incerteza contra ensaio, pvlib/SAM ou curva do fabricante.
3. Validar mask → substring e máximos múltiplos em sombra parcial
   com uma referência PVsyst ou dados de campo.
4. Incluir estimativa térmica rastreável e 8760/8784 amostras UTC
   em worker/isolado, cache, cancelamento e progresso.
5. Validar potência DC e AC hora/mês/ano (inclusive clipping),
   separar perdas ópticas das perdas DC/AC e impedir dupla
   penalização de HSP ou eficiência.
6. Rodar benchmarks/CI Flutter, Windows e Android e smoke real;
   comparar contra produção do projeto quando houver medições.

**A decisão permanece:** não fechar #16–#19, não mesclar #20,
não publicar yield elétrico como certificado até os seis
gates terem sido atendidos.
