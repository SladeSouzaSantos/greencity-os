# Solar 3D — consolidação do MVP óptico

**Revisão:** 08/11/2026  
**Integração:** [PR #14](https://github.com/SladeSouzaSantos/greencity-os/pull/14), branch `feature/solar3d-shading-analysis` → `main`  
**Homologação:** o usuário confirmou o funcionamento no Android, inclusive a seleção múltipla, e autorizou o merge.

## Funcionalidades entregues

- Editor 3D Flutter nativo, vistas superior e inclinada, câmera
  independente da edição de objetos, bússola N/S/L/O, zoom e pan.
- Placas e obstáculos posicionados por X/Z, com alturas da **borda
  inferior** e da **base**, respectivamente.
- Seleção múltipla temporária de placas/obstáculos; arrasto do conjunto,
  deslocamento numérico relativo X/Z/Y e alinhamento em altura comum,
  sem alterar MPPTs e distâncias relativas.
- Sombra direta geométrica e análise HSP de **12 meses completos**,
  retornando perdas ópticas por placa, inversor e MPPT.
- Atribuição **hipotética** de MPPT por placa, mantendo inversores
  independentes. Auditoria elétrica preliminar Voc/Vmp/Isc/Imp.
- Autosave local da cena e salvamento explícito dos fatores mensais
  ao **Aplicar correção óptica na geração**; abrir sem editar não
  remove o efeito. Mudanças na cena/MPPT/HSP invalidam fatores
  incompatíveis.
- Correções Android: conflito de `GlobalKey`, desmontagem
  `_dependents.isEmpty`, direção do pan, seletor de ano em telas
  pequenas e listas imutáveis de sistemas/arranjos.
- API HSP horária externa configurável; a API convencional do
  dimensionamento é mantida separada.

## Evidências de qualidade

| Gate | Evidência | Resultado |
| --- | --- | --- |
| Flutter analyze, testes e esquema Isar | [CI #42514096789](https://github.com/SladeSouzaSantos/greencity-os/actions/runs/42514096789) | Aprovado |
| Build Windows desktop | Mesmo CI | Aprovado |
| Build Android debug APK | Mesmo CI | Aprovado |
| Validação Android da manipulação 3D | Confirmação do usuário em 08/11/2026 | Aprovado por relato |
| HSP horário em DEV | [CI HSP #42438742622](https://github.com/SladeSouzaSantos/hsp_simulator/actions/runs/42438742622) | Aprovado em DEV |
| Disponibilidade do HSP no destino final | Conferência do endpoint configurado | Dependência operacional |
| Curvas I–V, bypass, mismatch, perdas DC/AC | [Fase 2 / issue #16](https://github.com/SladeSouzaSantos/greencity-os/issues/16) | Fora desta entrega |

**O que o gate comprova:** os testes passam e o APK debug é
compilável; não é certificação elétrica de uma instalação ou
garantia de disponibilidade do serviço HSP externo.

## Entrega na main e APK

1. Atualizar README, contratos e instruções de testes.
2. Confirmar o CI verde no **HEAD da PR #14** antes do merge.
3. Mesclar a PR em `main` com SHA esperado, sem reescrever histórico.
4. Conferir a execução `push/main` em GitHub Actions, incluindo
   testes Flutter, Windows e build Android.
5. No job Android, publicar o `app-debug.apk` como artefato
   `greencity-os-android-debug-apk` usando
   `actions/upload-artifact@v4`. Baixar seu ZIP na seção
   **Artifacts** da execução.
6. Para uma distribuição pública, preparar um **APK/AAB release
   assinado** e credenciais fora dos assets.

### Build Android local equivalente

~~~powershell
git switch main
git pull --ff-only origin main
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
# Saída: build/app/outputs/flutter-apk/app-debug.apk
~~~

O artefato debug é para instalação e teste, não uma release
assinada para lojas. O workflow cria `.env` com base em
`.env.example` (sem chaves); nunca publicar `.env` com segredos.

## Limitações e backlog

- A renderização das faces 3D ainda não implementa z-buffer
  por pixel nas interseções complexas.
- Grupo múltiplo é **estado temporário da interface**; posições
  persistidas continuam no documento JSON v1, com centros internos.
- Mudar MPPT na análise 3D não modifica fisicamente o arranjo.
- Perdas ópticas HSP não devem ser descontadas novamente no
  dimensionamento convencional; não representam perdas elétricas.
- Disponibilidade de `POST /api/recurso-solar/horario` depende
  da configuração e do deploy do HSP no ambiente de execução.

Backlog separado: [#15 — WebGL e integração avançada](https://github.com/SladeSouzaSantos/greencity-os/issues/15),
[#16 — Fase 2 elétrica](https://github.com/SladeSouzaSantos/greencity-os/issues/16),
[#17 — curvas I–V](https://github.com/SladeSouzaSantos/greencity-os/issues/17),
[#18 — bypass](https://github.com/SladeSouzaSantos/greencity-os/issues/18)
e [#19 — perdas DC/AC](https://github.com/SladeSouzaSantos/greencity-os/issues/19).

Ver também [integração técnica](solar3d-app-integration.md),
[runbook](solar3d-local-test.md) e
[homologação elétrica](solar3d-electrical-homologation.md).
