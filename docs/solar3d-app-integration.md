# Planejamento de cena 3D GreenCity OS

`Solar3dPlanFactory` expande cada `SolarScenario.quantityPvModule` em
placas físicas com IDs distintos e MPPT herdado do `SolarArray`, usando
os modelos de módulos e inversores do Isar. As coordenadas iniciais são
**apenas uma grade provisória**; o projeto não possui medições do telhado.
O identificador `stringId` permanece `null`: a estrutura atual do
GreenCity OS não representa strings individuais.

`SolarResourceHourlyDataSource` implementa um cliente Dio opt-in para
`/api/recurso-solar/horario` e valida séries UTC, sem obstáculos e sem
estimativa elétrica. O fluxo existente continua usando
`/api/calcular-arranjo`; nenhuma nova chamada é ativada antes do
deploy da API correspondente.

O motor `Solar3dGeometricShading` aplica máscaras geométricas ao POA
**direto** por placa/horário e calcula HSP/percentual de perda de
irradiância. Não estima desempenho elétrico de strings ou MPPTs.

Pendências para o editor WebGL: salvar posições persistentes, cadastrar
obstáculos, atribuir strings reais e validar a plataforma Windows/Android.
Para energia por MPPT, calibrar curvas de equipamento e usar perfis
temporais; não agregar percentuais mensais ópticos como perda elétrica.
