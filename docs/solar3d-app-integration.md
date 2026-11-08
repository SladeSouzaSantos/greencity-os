# Solar 3D — integração no GreenCity OS

**Revisão:** 08/11/2026 · [PR #14](https://github.com/SladeSouzaSantos/greencity-os/pull/14).

## Contratos implementados

- `Solar3dPlanFactory` expande arrays Isar em placas com IDs estáveis
  por projeto e MPPT inicial. As posições iniciais são **ilustrativas**.
- `Solar3dEditorPage` oferece prévia 3D nativa Flutter, câmera,
  percurso solar, sombras geométricas por placa, obstáculos, edição
  X/Z/Y, strings/MPPTs de estudo e arquivos locais JSON v1.
  O editor WebGL/Three.js do HSP ainda **não** é embutido no app.
- **Alturas na UI:** módulo pela borda inferior; obstáculo pela base,
  com `0 m` no solo. Ambos são convertidos para centro geométrico
  para persistir sem alterar o formato JSON ou o raycasting.
- `SolarResourceHourlyDataSource` usa a API HSP opt-in
  `POST /api/recurso-solar/horario`; implantada e verificada em
  **DEV**, não confirmada em produção. A rota convencional
  `/api/calcular-arranjo` continua independente.
- `Solar3dGeometricShading` aplica máscara à irradiância **direta**
  e preserva parcelas difusa e refletida.
- `Solar3dOpticalCorrection` agrupa por `systemId/mpptIndex` e
  permite aplicar/reverter uma estimativa óptica na sessão após os
  12 meses completos. A atribuição MPPT de estudo não altera
  `SolarArray.mpptIndex` e não persiste topologia física.
- `Solar3dElectricalAudit` verifica limites STC por string/MPPT:
  `Imp` operacional excedido gera aviso, `Isc` absoluto excedido
  gera bloqueio. Não modela curvas I–V, bypass ou perdas elétricas.

## Gates e dependências

A PR #14 entrega exclusivamente o **MVP óptico**. Não usar o
percentual de HSP sombreado como perda de potência DC/AC.
Não transferir automaticamente ao fluxo HSP convencional os
obstáculos do estudo 3D — isso duplicaria a perda.
A release deve validar endpoint HSP do ambiente de destino e
smoke Android físico ou aceitar explicitamente esse risco.

- [Status, evidências e checklist do merge](solar3d-release-readiness.md)
- [Guia de testes](solar3d-local-test.md)
- [Riscos/contrato elétrico](solar3d-electrical-homologation.md)
- [#15: WebGL/persistência real](https://github.com/SladeSouzaSantos/greencity-os/issues/15)
- [#16: epic elétrica, fases #17–#19](https://github.com/SladeSouzaSantos/greencity-os/issues/16)
