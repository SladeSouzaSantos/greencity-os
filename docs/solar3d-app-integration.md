# Solar 3D — integração no GreenCity OS

**Revisão:** 08/11/2026 · [PR #14](https://github.com/SladeSouzaSantos/greencity-os/pull/14).

## Contratos implementados

- `Solar3dPlanFactory` expande arrays Isar em placas com IDs estáveis
  por projeto e MPPT inicial. As posições iniciais são **ilustrativas**.
- `Solar3dEditorPage` oferece prévia 3D Flutter, câmera independente,
  trajetória solar, sombras diretas por placa, obstáculos, edição
  X/Z/Y e MPPTs/strings de estudo. O editor WebGL/Three.js do
  HSP **não** é embutido no aplicativo.
- `Solar3dBulkMove` implementa seleção múltipla **temporária**
  de placas/obstáculos, movimentação rígida com preservação de
  distâncias e alturas, e alinhamento de borda/base por valor
  absoluto. A operação é atômica e não altera conexões elétricas.
- `Solar3dSceneStorage` guarda a cena automaticamente e,
  após confirmar a aplicação da correção óptica, persiste
  `optical-<hash>.json` vinculado à cena e à assinatura
  elétrica/HSP. Reabrir sem modificar a cena preserva os fatores.
- **Alturas na UI:** módulo pela borda inferior; obstáculo pela base,
  com `0 m` no solo. Ambos são convertidos para centro geométrico
  para persistir sem alterar o formato JSON ou o raycasting.
- `SolarResourceHourlyDataSource` usa a API HSP opt-in
  `POST /api/recurso-solar/horario`; implantada e verificada em
  **DEV**, não confirmada em produção. A rota convencional
  `/api/calcular-arranjo` continua independente.
- `Solar3dGeometricShading` aplica máscara à irradiância **direta**
  e preserva parcelas difusa e refletida.
- `Solar3dOpticalCorrection` agrupa por `systemId/mpptIndex`,
  calcula os **12 meses** e aplica/reverte uma estimativa óptica
  persistida localmente, sem recálculo ao apenas reabrir o editor.
  Alterações no projeto, HSP, cena ou MPPTs invalidam o snapshot.
  O MPPT de estudo não altera `SolarArray.mpptIndex` e não
  persiste nova topologia física.
- `Solar3dElectricalAudit` verifica limites STC por string/MPPT:
  `Imp` operacional excedido gera aviso, `Isc` absoluto excedido
  gera bloqueio. Não modela curvas I–V, bypass ou perdas elétricas.

## Gates e dependências

A PR #14 entrega exclusivamente o **MVP óptico**. Não usar o
percentual de HSP sombreado como perda de potência DC/AC.
Não transferir automaticamente ao fluxo HSP convencional os
obstáculos do estudo 3D — isso duplicaria a perda.
O fluxo Android, incluindo a manipulação múltipla, foi confirmado
pelo usuário. O deploy da API HSP horária no destino final deve
ser conferido operacionalmente. O APK distribuído pelo CI é
**debug**, não uma release assinada, e usa `.env.example`
sem credenciais reais.

- [Status, evidências e checklist do merge](solar3d-release-readiness.md)
- [Guia de testes](solar3d-local-test.md)
- [Riscos/contrato elétrico](solar3d-electrical-homologation.md)
- [#15: WebGL/persistência real](https://github.com/SladeSouzaSantos/greencity-os/issues/15)
- [#16: epic elétrica, fases #17–#19](https://github.com/SladeSouzaSantos/greencity-os/issues/16)

## Distribuição e qualidade

- CI [#42514096789](https://github.com/SladeSouzaSantos/greencity-os/actions/runs/42514096789): analyze, testes, build Windows e build APK Android aprovados no escopo funcional da PR.
- O workflow `.github/workflows/flutter-checks.yml` agora publica o APK debug como artefato `greencity-os-android-debug-apk` na execução da `main`.
- Download: GitHub **Actions → Flutter Analyze and Tests → execução → Artifacts**. O ZIP contém `app-debug.apk`.
- O pipeline utiliza `cp .env.example .env`; não colocar chaves reais no app de distribuição. APK/AAB release assinado é trabalho posterior.
