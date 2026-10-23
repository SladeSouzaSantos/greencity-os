/// Contrato único de extração para OpenRouter e Ollama.
class DatasheetExtractionPrompt {
  static const String text = '''
Analise o PDF de datasheet fotovoltaico e devolva SOMENTE JSON
com duas listas: "modules" e "inverters" (listas vazias se não houver).
Extraia TODOS os modelos exatos e variações, um objeto por modelo, SEM
agrupar várias potências em um único objeto. Se o PDF listar 600, 605 e
610 W, gere três módulos, cada um com seus próprios dados STC.

ATENÇÃO A DATASHEETS DE INVERSORES COM TABELAS MULTICOLUNAS:
- Cada COLUNA de modelo é um inversor separado, inclusive quando o título
  do PDF contém apenas o nome de uma família de produtos.
- Leia cada linha de potência nominal CA e potência máxima recomendada CC
  por COLUNA. Não confunda kVA, kW nominais e máxima recomendada CC.
- Uma especificação exibida em célula mesclada pode valer para um GRUPO
  de colunas, não para a linha toda: associe o valor somente aos modelos
  cobertos pela célula. MPPT, corrente, peso e dimensões podem variar
  entre os grupos.
- A linha "Quantidade MPPT" define mpptCount (RASTREADORES).
  "Número de Entradas do Inversor" define totalDcInputs (CONECTORES):
  são quantidades distintas. Exemplo AUXSOL ASN-10SL: 2 MPPTs e 3
  entradas; NUNCA registre mpptCount=3 por causa das entradas.
- Se o datasheet exibir correntes "32A/16A" para dois MPPTs,
  registre mpptInputCurrentsA=[32,16] e maxInputCurrentPerMppt=16
  apenas como compatibilidade conservadora, sem SOMAR as correntes.
  Para corrente de curto "40A/20A", registre
  mpptShortCircuitCurrentsA=[40,20] e maxShortCircuitCurrent=20.
  Não presuma quantos conectores existem em cada rastreador.
- "Monofásico", "1F/N/PE" e "F+N" são gridConnection=monophasic.
- Preserve rigorosamente os nomes exatos, incluindo sufixo "-G2",
  e não crie modelos inexistentes por extrapolação.
- Em inversores, eficiência enviada em porcentagem (97.5), e não
  fração (0.975). Replique dados comuns apenas quando declarados.
Extraia apenas o que estiver explícito no documento. NÃO estime, NÃO
extrapole valores de tabelas, NÃO invente dimensões, eficiência, tipo ou
garantias. Para cada campo não informado retorne null. Use números JSON
sem unidade, ponto decimal e booleanos JSON. Mantenha a potência de
módulos em Wp, de inversores em kW; dimensões de módulos em mm, peso
em kg, temperatura em °C, tensão em V, corrente em A.
Eficiência de módulo em porcentagem (ex: 22.8) e eficiência de
inversor em porcentagem (ex: 98.2). Coeficientes térmicos em %/°C.
GARANTIAS: "30 years performance warranty" indica SOMENTE garantia
linear de desempenho (efficiencyWarranty), NUNCA garantia física.
physicalWarranty requer menção EXPLÍCITA a product/material warranty.
"less than 10%" ou "<10%" NÃO significa perda exata de 10%:
efficiencyLoss=null se não houver degradação final exata declarada.
Consulte "Maximum Series Fuse", "Operating Temperature" e
"Corrente Máx. de Saída" mesmo quando as outras propriedades existem.
Use parâmetros de STC, não NMOT. Preserve o fabricante e o código
integral do modelo (incluindo sufixos); repita dados compartilhados
da família para cada variante SOMENTE se estiverem no documento.

Estrutura:
{
 "modules": [{
   "manufacturer": "string", "modelName": "string",
   "powerWp": null, "efficiency": null,
   "cellTechnology": "TOPCON|PERC|AL_BSF|HJT",
   "isBifacial": null, "isTier1": null,
   "length": null, "width": null, "weight": null,
   "vOc": null, "iSc": null, "vMp": null, "iMp": null,
   "maxSystemVoltage": null, "tempCoefPmax": null,
   "tempCoefVoc": null, "tempCoefIsc": null,
   "minOperatingTemp": null, "maxOperatingTemp": null,
   "fuseCurrent": null, "physicalWarranty": null,
   "efficiencyWarranty": null, "efficiencyLoss": null
 }],
 "inverters": [{
   "manufacturer": "string", "modelName": "string",
   "inverterType": "string|microInverter|optimizer",
   "gridConnection": "monophasic|biphasic|triphasic",
   "isHybrid": null, "nominalPowerKw": null,
   "maxInputPowerKw": null, "maxEfficiency": null,
   "euroEfficiency": null, "mpptCount": null,
   "totalDcInputs": null, "mpptInputCurrentsA": null,
   "mpptShortCircuitCurrentsA": null,
   "maxInputVoltage": null, "nominalVoltageDc": null,
   "startVoltage": null, "minMpptVoltage": null,
   "maxMpptVoltage": null, "maxInputCurrentPerMppt": null,
   "maxShortCircuitCurrent": null, "maxOutputCurrent": null,
   "nominalVoltageAc": null, "dimensions": null,
   "weight": null, "minOperatingTemp": null,
   "maxOperatingTemp": null, "protectionDegree": null,
   "warrantyYears": null
 }]
}

Se o documento não permitir identificar modelos distintos, devolva
listas vazias. Não crie modelos por interpolação ou intervalo.
''';
}
