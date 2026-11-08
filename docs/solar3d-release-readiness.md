# Release readiness — Solar3D óptico (PR #14)

**Consolidação em 08/11/2026**  
**Baseline funcional do MVP:** `87138b97f8d7c271f1d518c0bd18dcb84c699ad8`  
**Branch:** `feature/solar3d-shading-analysis`  
**Destino proposto:** `main` (ainda **sem merge**).

## Escopo aprovado para a etapa óptica

Editor Flutter 3D nativo, câmera/sol e sombra geométrica do feixe
direto, obstáculos e placas com altura definida pela base/borda,
persistência de cena local, reatribuição hipotética de MPPT por placa,
consulta HSP horária, comparação sem/com sombra por placa/MPPT
e overlay óptico **opt-in e reversível** sobre a geração estimada.

O dimensionamento original, os equipamentos Isar e as ligações
elétricas físicas não são reconfigurados por essa ferramenta. Dados
de irradiância e o fator HSP **não são perdas DC/AC certificadas**.

## Evidência rastreável

| Gate | Evidência | Status |
| --- | --- | --- |
| Flutter analyze, testes, Isar schema | [GitHub Actions #42441894386](https://github.com/SladeSouzaSantos/greencity-os/actions/runs/42441894386) | **Aprovado** |
| Build e testes Windows | Mesmo run (Windows desktop build and tests) | **Aprovado** |
| Build APK Android debug | Mesmo run (Android debug APK build) | **Aprovado** |
| Teste funcional Windows | Usuário informou em 08/11/2026 que todas as correções funcionaram | **Aprovado por relato**, não certificado |
| HSP API horária DEV | [GitHub Actions #42438742622](https://github.com/SladeSouzaSantos/hsp_simulator/actions/runs/42438742622) com deploy e healthcheck | **Aprovado** |
| Testes manuais Android físico | Sem confirmação | **Pendente** |
| Disponibilidade de API horária em produção | Sem confirmação | **Pendente** |
| Curvas I–V/bypass/clipping AC | Fora do escopo óptico | **Fase 2 separada** |

## Checklist para encerrar PR #14

- [x] CI funcional, Windows e APK no baseline óptico.
- [x] Windows testado pelo usuário.
- [x] HSP DEV com rota horária verificada via proxy.
- [x] Altura da placa medida pela borda inferior.
- [x] Altura do obstáculo medida pela base, `0 m` = solo.
- [x] Cena salva e reconstruída com coordenadas internas de centro v1.
- [x] MPPTs e correntes Imp/Isc por inversor diferenciadas.
- [x] Documentação atualizada e Fase 2 desacoplada.
- [ ] Executar smoke Android físico ou documentar decisão explícita
  de aceitar o risco residual antes de disponibilizar essa experiência.
- [ ] Validar/decidir o endpoint HSP horário no ambiente de produção:
  sem ele, o usuário deve configurar URL local ou DEV.
- [ ] Fazer revisão final do diff e aprovar merge.
- [ ] Após merge, conferir CI de `main`, funcionamento do
  dimensionamento convencional e reversibilidade da estimativa óptica.

**Decisão:** preparar PR #14 para revisão técnica, sem executar merge
automaticamente enquanto persistirem os gates pendentes. Esse escopo
pode ser entregue **sem concluir** as perdas elétricas DC/AC.

## Backlog independente

- [#15](https://github.com/SladeSouzaSantos/greencity-os/issues/15):
  paridade WebGL/Three.js, vínculo físico e persistência avançada.
- [#16](https://github.com/SladeSouzaSantos/greencity-os/issues/16):
  epic da **Fase 2 — modelagem elétrica**.
- [#17](https://github.com/SladeSouzaSantos/greencity-os/issues/17):
  curvas I–V/P–V calibradas de módulo/string.
- [#18](https://github.com/SladeSouzaSantos/greencity-os/issues/18):
  substrings/diodos bypass e máscaras por célula.
- [#19](https://github.com/SladeSouzaSantos/greencity-os/issues/19):
  energia DC/AC horária, eficiência, clipping e perdas de condutores.
- [HSP Solar3D Lab PR #3](https://github.com/SladeSouzaSantos/hsp_simulator/pull/3):
  laboratório elétrico exploratório, sem merge no HSP estável.

## Recuperação no Windows

```powershell
git fetch origin
git switch feature/solar3d-shading-analysis
git pull --ff-only origin feature/solar3d-shading-analysis
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d windows
```

Para HSP local, usar `uvicorn api:app` na branch `dev` do
`hsp_simulator` e configurar no editor o endpoint
`http://127.0.0.1:8000/recurso-solar/horario`.
Em emulador Android, `127.0.0.1` aponta para o emulador, não o PC.

## Regra de evolução

O motor DC/AC da Fase 2 deverá usar a mesma irradiância horária com
e sem sombra; perdas por mismatch/bypass/clipping só podem ser aplicadas
após modelagem elétrica real. **Não descontar novamente o HSP óptico.**
