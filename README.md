# Chronos Mobile — FIWARE Charts

App Flutter (Android-first) para visualizar séries históricas de **sensores FIWARE** (STH-Comet) com interface simples e dois fluxos: **Gráficos** e **Configurações**.

<p align="center">
  <img src="https://github.com/user-attachments/assets/4d5ef89b-4ce7-4b1b-8f5b-66833de7cbae" width="30%" />
  <img src="https://github.com/user-attachments/assets/67732884-0edf-453e-b5f6-9f1bed70d770" width="30%" />
  <img src="https://github.com/user-attachments/assets/dcd211d0-75cb-4864-b0ff-f2065a6d280d" width="30%" />
</p>

---

## Funcionalidades

- **2 abas com navegação inferior**: Gráficos e Configurações.
- **Gráficos por atributo** da entidade selecionada (ex.: `temperature`, `humidity`), com:
  - **Cabeçalho com KPIs**: “Último” valor e “Total” de registros (obtido do STH-Comet);
  - **“Atualizado em …”** com a data/hora da última leitura;
  - Eixos com **padding** (os pontos não colam nas bordas);
  - Rótulos dos eixos **não exibem os extremos** (evita sobreposição);
  - **Linha reta com pontos visíveis** nas medições (sem suavização exagerada);
  - **Ordem estável** dos gráficos seguindo a ordem dos atributos do device.

- **Atualização sob demanda**: as requisições só ocorrem quando o usuário clica em:
  - **Atualizar dados** (gráficos);
  - **Atualizar lista** (devices).

- **Carregamento**: botões ficam **desabilitados com spinner** enquanto carregam (sem overlay).
- **Configurações persistentes** (SharedPreferences):
  - IP do servidor;
  - Device/entidade do IoT Agent;
  - `lastN` (1–100) e, opcionalmente, intervalo por data (ISO 8601, UTC `Z`).

- **Desempenho/UX**:
  - tema com ripple clássico (`InkRipple`) para evitar compilação de shader na 1ª interação.

- **Personalização nativa**:
  - Splash screen (**flutter\_native\_splash**), incluindo Android 12+;
  - Ícone do app (**flutter\_launcher\_icons**);
  - Nome de exibição “**Chronos Mobile**”.

---

## Arquitetura

```
lib/
│
├── app.dart
├── main.dart
├── core/
│   ├── models/     # Device, SeriesPoint, AppSettings
│   ├── services/   # FiwareApi (IoT Agent + STH-Comet)
│   ├── state/      # AppState (Provider)
│   ├── storage/    # SettingsStorage (SharedPreferences)
│   └── utils/      # Validators
└── ui/
    ├── pages/      # charts_page.dart, settings_page.dart
    └── widgets/    # chart_card.dart (KPIs + gráfico), empty_state.dart
```

- **Gerência de estado**: `provider` (`AppState`).
- **Persistência**: `shared_preferences`.
- **HTTP**: `http`.
- **Gráficos**: `fl_chart`.
- **Formatação**: `intl`.

---

## Endpoints FIWARE usados

### 1) Lista de devices (IoT Agent UL)

```
GET http://{ip}:4041/iot/devices
Headers:
  fiware-service: smart
  fiware-servicepath: /
```

### 2) Série histórica (STH-Comet)

Últimos N:

```
GET http://{ip}:8666/STH/v1/contextEntities/type/{entityType}/id/{entityId}/attributes/{attr}?lastN={N}&count=true
Headers:
  fiware-service: smart
  fiware-servicepath: /
```

- O app envia **`count=true`** e lê o header **`Fiware-Total-Count`** para exibir o **Total** por atributo.
- Os headers `fiware-service` e `fiware-servicepath` estão fixos no `FiwareApi` (ajuste se necessário).

---

## Executar

Requisitos: Flutter 3.9+.

```bash
flutter pub get
flutter run --release
```

---

## Uso no app

1. **Configurações**

- Informe **IP** e toque no botão de **atualizar** ao lado do dropdown para carregar os devices.
- Selecione o **device** (a entidade/URN vem junto).
- Defina **Últimos N** (1–100).
- **Atalho**: ao tocar **OK** no teclado no campo `lastN`, o formulário é **enviado**.
- Toque em **Salvar configurações**.

2. **Gráficos**

- Toque em **Atualizar dados** para buscar as séries no STH-Comet.
- Para cada atributo:
  - **Último** valor e **Total** (do `Fiware-Total-Count`) no cabeçalho do card;
  - **Atualizado em …** com a data/hora da última leitura;
  - gráfico de linha com **pontos** nas medições.

---

## Personalização (splash, nome e ícone)

### Splash nativo (inclui Android 12+)

Gerar:

```bash
dart run flutter_native_splash:create
```

### Ícones (adaptive + monochrome)

Gerar:

```bash
dart run flutter_launcher_icons
```

---

## Validações & Comportamentos

- `lastN` **entre 1 e 100**.
- **Sem requisições automáticas** na abertura: somente por **ação do usuário**.
- **Ordem dos gráficos** segue `settings.attributes` (ordem do device, independente da ordem de chegada das requisições).
- Botões exibem **spinner** e ficam **desabilitados** durante chamadas.
- **Formulário envia ao “OK”** do teclado (fecha o teclado e valida antes de salvar).

---

## Dependências

`http`, `provider`, `shared_preferences`, `fl_chart`, `intl`,
(opcionais) `flutter_native_splash`, `flutter_launcher_icons`.
