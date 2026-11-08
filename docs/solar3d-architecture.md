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
- Um mesmo modelo de catálogo pode aparecer em várias placas físicas
  com IDs de cena independentes: `Solar3dPlanFactory` já expande
  quantidades em placas individuais e a persistência JSON reconcilia
  seus IDs com o catálogo Isar. A atribuição de string é **de estudo**,
  não um circuito real aprovado.
- A UI refere-se à **borda inferior** da placa e à **base** do
  obstáculo. O motor geométrico mantém o **centro** internamente,
  preservando o formato JSON de cenas antigas.
- A nova rota horária está **implantada e verificada em HSP DEV**,
  mas não está comprovada em produção. A aplicação principal mantém
  a chamada convencional `/api/calcular-arranjo` sem mudanças.

**Fases seguintes independentes:** WebGL/Three.js e persistência
do circuito físico (issue #15) e modelagem elétrica calibrada I–V,
bypass e DC/AC (epic #16, subissues #17–#19). Não confundir perda
óptica HSP com perda elétrica de energia por MPPT.
Ver [checklist de integração](solar3d-release-readiness.md).

O limite de trabalho síncrono é deliberado para evitar travar a UI;
uma produção anual com dezenas de painéis exigirá processamento em
isolate/worker e aceleração espacial. `blockedFraction` pressupõe
objetos retangulares opacos e não inclui terreno/vegetação/difusa.
