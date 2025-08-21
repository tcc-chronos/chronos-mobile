# Chronos Mobile — FIWARE Charts

App Flutter (Android-first) para visualizar séries históricas de **sensores FIWARE** (STH-Comet) com interface simples e dois fluxos: **Gráficos** e **Configurações**.

## Funcionalidades

* **2 abas com navegação inferior**: Gráficos e Configurações.
* **Gráficos por atributo** da entidade selecionada (ex.: `temperature`, `humidity`), com:

  * eixos com **folga nas bordas** (padding);
  * rótulos dos eixos **sem sobrepor nos extremos**;
  * **escala “bonita”** no eixo Y (ticks arredondados/inteiros quando possível);
  * **linha sem suavização exagerada** (reta) e **pontos visíveis** nas medições;
  * **ordem estável** dos gráficos seguindo a ordem dos atributos do device.
* **Atualização sob demanda**: as requisições só ocorrem quando o usuário clica em:

  * **Atualizar dados** (gráficos);
  * **Atualizar lista** (devices).
* **Carregamento**: botões ficam **desabilitados com spinner** enquanto carregam (sem overlay).
* **Configurações persistentes** (SharedPreferences):

  * IP do servidor;
  * Device/entidade do IoT Agent;
  * `lastN` (1–100) e, opcionalmente, intervalo por data (ISO 8601, UTC `Z`).
* **Desempenho**:

  * construção preguiçosa (**lazy**) da aba de Configurações;
  * tema usando ripple clássico (evita compilação de shader na 1ª interação).
* **Personalização nativa**:

  * Splash screen (**flutter\_native\_splash**), incluindo Android 12+;
  * Ícone do app (**flutter\_launcher\_icons**);
  * Nome de exibição “**Chronos Mobile**”.

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

* **Gerência de estado**: `provider` (`AppState`).
* **Persistência**: `shared_preferences`.
* **HTTP**: `http`.
* **Gráficos**: `fl_chart`.
* **Formatação**: `intl`.

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

Últimos N:

```
GET http://{ip}:8666/STH/v1/contextEntities/type/{entityType}/id/{entityId}/attributes/{attr}?lastN={N}
Headers:
  fiware-service: smart
  fiware-servicepath: /
```

Com intervalo:

```
GET ...attributes/{attr}?lastN={N}&dateFrom=2025-08-21T02:29:04.162Z&dateTo=2025-08-21T02:34:23.697Z
```

> Os headers `fiware-service`/`fiware-servicepath` estão fixos em `FiwareApi`. Ajuste se necessário.

---

## ▶Executar

Requisitos: Flutter 3.4+.

```bash
flutter pub get
flutter run
```

---

## Uso no app

1. **Configurações**

   * Informe **IP** e clique no botão de **atualizar** ao lado do dropdown para carregar os devices.
   * Selecione o **device** (a entidade/URN vem junto).
   * Defina **Últimos N** (1–100) e/ou **datas ISO 8601** (com `Z`).
   * Clique **Salvar configurações**.

2. **Gráficos**

   * Clique em **Atualizar dados** para buscar as séries no STH-Comet.
   * Um gráfico por **atributo** do device; pontos marcam medições reais.

---

## Personalização (splash, nome e ícone)

### Splash nativo (inclui Android 12+)

`pubspec.yaml` (trecho):

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.1

flutter_native_splash:
  android: true
  ios: false
  color: "#FFFFFF"
  color_dark: "#0B1320"
  image: assets/images/splash.png
  image_dark: assets/images/splash_dark.png
  android_12:
    image: assets/images/splash_android12.png
    image_dark: assets/images/splash_android12_dark.png
    icon_background_color: "#FFFFFF"
    icon_background_color_dark: "#0B1320"
```

Gerar:

```bash
dart run flutter_native_splash:create
```

### Ícones

`pubspec.yaml` (trecho recomendado):

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path_ios: assets/images/app_icon.png
  adaptive_icon_foreground: assets/images/app_icon_fg.png
  adaptive_icon_background: "#0B1320"
  adaptive_icon_monochrome: assets/images/app_icon_mono.png
```

Gerar:

```bash
dart run flutter_launcher_icons
```

---

## Validações & Comportamentos

* `lastN` **entre 1 e 100**.
* Datas em **ISO 8601 UTC** (terminadas em `Z`) quando usadas.
* **Sem requisições automáticas** na abertura: somente por **ação do usuário**.
* **Ordem dos gráficos** segue `settings.attributes` (ordem do device).
* Botões exibem **spinner** e ficam **desabilitados** durante chamadas.

---

## Dicas de desempenho

* **IndexedStack** com criação **preguiçosa** da `SettingsPage` (instancia apenas ao abrir a aba).
* `splashFactory: InkRipple.splashFactory` no tema (evita compilação de shader `InkSparkle`).
* Evite trabalho pesado síncrono no `main()`/`initState()`.

---

## Troubleshooting

* **Build falha em Windows com acentos no caminho**
  Mova o projeto para um diretório ASCII (ex.: `C:\dev\chronos_mobile`).
  Alternativa: `android.overridePathCheck=true` em `android/gradle.properties` (pode não resolver todos os casos).

* **Erro de shader (`ink_sparkle.frag`)**
  Está ligado ao splash/efeitos do Material 3; mude o `splashFactory` ou rode em release.

* **Dropdown: “There should be exactly one item with DropdownButton’s value”**
  Garanta identidade do `Device` (igualdade por `entityName`) e resolva o selecionado **dentro** da lista atual ao atualizar.

* **Valores salvos não aparecem na Config.**
  Com `IndexedStack`, crie a `SettingsPage` somente ao abrir a aba e “hidrate” os campos quando `AppState` carregar as preferências.

---

## Dependências

`http`, `provider`, `shared_preferences`, `fl_chart`, `intl`,
(opcionais) `flutter_native_splash`, `flutter_launcher_icons`.

---

## Licença

Defina a licença do projeto aqui (ex.: MIT).

---

## Contribuição

Issues e PRs são bem-vindos. Sugestões: gráfico de barras, seleção de unidade por atributo, agregações (média/hora), e suporte a múltiplas entidades.
