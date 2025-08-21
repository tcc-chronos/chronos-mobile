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

  - eixos com **padding**;
  - rótulos dos eixos **sem sobrepor nos extremos**;
  - **linha com **pontos visíveis** nas medições;
  - **ordem estável** dos gráficos seguindo a ordem dos atributos do device.
- **Atualização sob demanda**: as requisições só ocorrem quando o usuário clica em:
  - **Atualizar dados** (gráficos);
  - **Atualizar lista** (devices).

- **Carregamento**: botões ficam **desabilitados com spinner** enquanto carregam (sem overlay).
- **Configurações persistentes** (SharedPreferences):
  - IP do servidor;
  - Device/entidade do IoT Agent;
  - `lastN` (1–100) e, opcionalmente, intervalo por data (ISO 8601, UTC `Z`).

- **Desempenho**:
  - tema usando ripple clássico (evita compilação de shader na 1ª interação).

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
    └── widgets/    # chart_card.dart, empty_state.dart
```

- **Gerência de estado**: `provider` (`AppState`).
- **Persistência**: `shared_preferences`.
- **HTTP**: `http`.
- **Gráficos**: `fl_chart`.
- **Formatação**: `intl`.

---

## Endpoints FIWARE usados

### Lista de devices (IoT Agent UL)

```
GET http://{ip}:4041/iot/devices
Headers:
  fiware-service: smart
  fiware-servicepath: /
```

### Série histórica (STH-Comet)

Intervalo de registros:

```
GET http://{ip}:8666/STH/v1/contextEntities/type/{entityType}/id/{entityId}/attributes/{attr}?lastN={N}
Headers:
  fiware-service: smart
  fiware-servicepath: /
```

> Os headers `fiware-service`/`fiware-servicepath` estão fixos em `FiwareApi`. Ajuste se necessário.

---

## Executar

Requisitos: Flutter 3.9+.

```bash
flutter pub get
flutter run
```

---

## Uso no app

1. **Configurações**

   - Informe **IP** e clique no botão de **atualizar** ao lado do dropdown para carregar os devices.
   - Selecione o **device** (a entidade/URN vem junto).
   - Defina o **Intervalo de Coleta** (1–100).
   - Clique **Salvar configurações**.

2. **Gráficos**

   - Clique em **Atualizar dados** para buscar as séries no STH-Comet.
   - Um gráfico por **atributo** do device; pontos marcam medições reais.

---

## Personalização (splash, nome e ícone)

### Splash nativo (inclui Android 12+)

Gerar:

```bash
dart run flutter_native_splash:create
```

### Ícones

Gerar:

```bash
dart run flutter_launcher_icons
```

---

## Validações & Comportamentos

- `lastN` **entre 1 e 100**.
- **Sem requisições automáticas** na abertura: somente por **ação do usuário**.
- **Ordem dos gráficos** segue `settings.attributes` (ordem do device).
- Botões exibem **spinner** e ficam **desabilitados** durante chamadas.

---

## Dependências

`http`, `provider`, `shared_preferences`, `fl_chart`, `intl`,
(opcionais) `flutter_native_splash`, `flutter_launcher_icons`.
