# Solar 3D no GreenCity OS — fundação de domínio

Esta branch contém **editor 3D Flutter funcional** com cenário local,
posição solar, obstáculos, MPPT por placa, HSP horário e correção óptica
experimental reversível na geração estimada. Preserva o cadastro Isar
e a API HSP de produção. O mecanismo 3D é nativo Flutter, não um
WebView/React Three.js; a paridade WebGL continua pendente.

A partir de 08/11/2026 há auditoria **prévia** de strings/MPPT
(`solar3d_electrical_audit.dart`) com limites do datasheet. A auditoria
NÃO calcula perdas DC/AC por sombreamento e não certifica circuito.

- `SolarResourceHour` e `HourlySolarResource` validam o retorno da nova
  `/api/recurso-solar/horario`, inclusive ano completo, UTC, horas
  consecutivas, campos físicos e modelo `sem_obstaculos=true`.
- `Solar3dScene` é uma coleção de objetos opacos identificados:
  edifícios, obstáculos e **placas individuais**. Cada placa pode ter
  `moduleModel`, `stringId` e `mpptIndex`. São posições em metros,
  com X=leste, Y=altura, Z=norte (como no editor Three.js).
- `Solar3dGeometricShading` executa raycasting geométrico por amostras
  na face frontal do módulo; subtrai do POA apenas o feixe **direto**
  bloqueado, preservando difusa e refletida. Calcula o HSP e percentual
  de perda de irradiância da placa, ponderado pelas horas e irradiância.
  Não é motor elétrico; não atribui perdas de string/MPPT pela média dos
  HSPs individuais.
- Um mesmo modelo de catálogo pode aparecer em várias placas físicas,
  cada uma com posição e ligação próprias. **Modelo Isar e quantidades de
  cenário não equivalem a IDs individuais.** A futura UI deverá expandir
  cada quantidade em `PanelPlacement` e preservar um ID persistente.
- A nova rota de recurso solar **não está em produção**. Não chamar sem
  que o backend HSP seja homologado/deployado. O aplicativo atual
  continua consumindo `/api/calcular-arranjo`.

**Fases seguintes:** criar tela 3D WebGL compartilhada com Solar 3D Lab,
fazer persistência da cena e das atribuições explícitas placa/string/MPPT,
transferir perfil temporal para motor de cálculo elétrico com datasheet
validado, e comparar cenários por MPPT. Não confundir o percentual de
perda HSP por placa com o percentual de perda de energia DC/AC por MPPT.

O limite de trabalho síncrono é deliberado para evitar travar a UI;
uma produção anual com dezenas de painéis exigirá processamento em
isolate/worker e aceleração espacial. `blockedFraction` pressupõe
objetos retangulares opacos e não inclui terreno/vegetação/difusa.
