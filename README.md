# Gestor de Tareas Local con SQLite Multiplataforma (`gestor_tareas_local`)

Aplicación Flutter para la administración de tareas mediante una base de datos **SQLite local** sin servidor ni conexión a internet, diseñada para ejecutarse en los tres entornos requeridos (**Web**, **Móvil** y **Escritorio**) con soporte arquitectónico para las seis plataformas de Flutter (**Android, iOS, Windows, Linux, macOS y Web**).

---

## 1. Tecnología de Persistencia y Justificación (`drift` + `drift_flutter`)

Se implementó la capa de persistencia con **[Drift](https://drift.simonbinder.eu/)** y **[`drift_flutter`](https://pub.dev/packages/drift_flutter)**:

- **Persistencia multiplataforma con una sola base de código:** La función `driftDatabase()` abre la conexión SQLite adecuada en cada entorno sin depender de código condicional `dart:io`:
  - **Móvil (Android / iOS) y Escritorio (Windows / Linux / macOS):** Utiliza SQLite nativo vía FFI (`sqlite3`) dentro de un `Isolate` en segundo plano y almacena el archivo `gestor_tareas_db.sqlite` en el directorio de documentos de la aplicación (`path_provider`).
  - **Web (Navegadores):** Ejecuta SQLite compilado a **WebAssembly** (`web/sqlite3.wasm`) dentro de un **Web Worker** (`web/drift_worker.dart.js`), guardando los datos localmente en el navegador mediante *Origin Private File System (OPFS)* o *IndexedDB*.
- **Generación de código segura (`build_runner` + `drift_dev`):** El archivo `lib/data/app_database.g.dart` contiene el mapeo tipado de columnas (`$TareasTable`), la entidad inmutable (`TareaEntity`) y el objeto de inserción/actualización (`TareasCompanion`).
- **Calidad técnica (F8):** Ninguna consulta SQL se ejecuta dentro de `build()`. Las operaciones asíncronas se invocan desde eventos de usuario e `initState()`, manejando errores mediante `SnackBar` y liberando el controlador de texto y la conexión SQLite (`_db.close()`) en `dispose()`.

---

## 2. Diseño de la Tabla `tareas`

| Columna | Definición en Drift | Tipo en SQLite | Restricciones | Propósito |
| :--- | :--- | :--- | :--- | :--- |
| **`id`** | `integer().autoIncrement()()` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Identificador único de cada registro para consultas, edición (`UPDATE`) y eliminación (`DELETE`). |
| **`titulo`** | `text().withLength(min: 1, max: 200)()` | `TEXT` | `NOT NULL` (`1..200` caracteres) | Descripción de la tarea. Se limpia con `.trim()` y se rechazan entradas vacías o de solo espacios. |
| **`completada`** | `boolean().withDefault(const Constant(false))()` | `INTEGER` | `NOT NULL DEFAULT 0` (`0` o `1`) | Estado de la tarea (`0` = pendiente, `1` = completada). |

---

## 3. Estructura del Proyecto

```text
gestor_tareas_local/
├── lib/
│   ├── main.dart                  # Punto de entrada (permite inyectar AppDatabase en pruebas)
│   ├── models/
│   │   └── tarea.dart             # Modelo de dominio Tarea (id, titulo, completada)
│   ├── data/
│   │   ├── app_database.dart      # Tabla Tareas, conexión driftDatabase y operaciones CRUD
│   │   └── app_database.g.dart    # Código generado por drift_dev / build_runner
│   └── screens/
│       └── tareas_page.dart       # Interfaz de usuario, validaciones, diálogo de edición y ciclo de vida
├── web/
│   ├── index.html
│   ├── sqlite3.wasm               # Binario WebAssembly oficial de SQLite (v3.9.1)
│   └── drift_worker.dart.js       # Web Worker precompilado de Drift (v2.35.4)
├── test/
│   └── widget_test.dart           # Suite de pruebas automatizadas (UI + CRUD SQLite en memoria)
├── android/ ios/ windows/ linux/ macos/
└── pubspec.yaml
```

---

## 4. Instrucciones de Ejecución y Reproducción

### 4.1 Instalar dependencias y verificar análisis estático

```bash
git clone <URL_DEL_REPOSITORIO>
cd gestor_tareas_local
flutter pub get
flutter analyze
```

*(Nota: el archivo generado `lib/data/app_database.g.dart` y los activos web `web/sqlite3.wasm` y `web/drift_worker.dart.js` ya están incluidos en el repositorio. Si se modifica la definición de la tabla, se puede regenerar con `dart run build_runner build --delete-conflicting-outputs`).*

### 4.2 Ejecutar en los 3 entornos (Web, Escritorio y Móvil)

- **Entorno Web (Chrome / Edge):**
  > Se recomienda fijar un puerto (p. ej. `--web-port=8080`) para conservar el mismo **origen (`http://localhost:8080`)** entre ejecuciones y comprobar la persistencia en el navegador:
  ```bash
  flutter run -d chrome --web-port=8080
  ```
- **Entorno Escritorio (Windows / Linux / macOS):**
  ```bash
  flutter run -d windows
  ```
- **Entorno Móvil (Android / iOS):**
  ```bash
  flutter run -d android
  ```

---

## 5. Pruebas Automatizadas (`flutter test`)

Ejecuta la suite de pruebas con:

```bash
flutter test
```

Casos cubiertos en `test/widget_test.dart` (utilizando `NativeDatabase.memory()` para validar SQLite real de forma aislada):
1. **Renderizado inicial:** Comprueba que la pantalla principal carga sin errores y muestra el estado vacío inicial.
2. **Validación de entradas (P5 / F1):** Verifica que intentar registrar un título vacío o compuesto solo por espacios muestra el mensaje de error en pantalla, no inserta filas en SQLite y lanza `ArgumentError` en la capa de datos.
3. **Persistencia CRUD en SQLite (P1–P4 / F1–F5):** Comprueba inserción de tres tareas (`INSERT`), consulta ordenada (`SELECT`), cambio de estado completada/pendiente (`UPDATE`), edición de título (`UPDATE`) y eliminación por ID (`DELETE`).
4. **Integración UI + SQLite:** Simula el flujo completo desde la interfaz gráfica (escribir tarea, presionar *Agregar tarea*, marcar el `Checkbox` y eliminar con el botón de papelera), verificando la sincronización con la base de datos.

---

## 6. Matriz de Comprobación Técnica Obligatoria (P1–P6)

| ID | Acción | Resultado esperado | Estado |
| :--- | :--- | :--- | :--- |
| **P1** | Agregar tres tareas, cerrar completamente la app y abrirla de nuevo. | Permanecen las tres. | Cumplido |
| **P2** | Marcar una como completada y reiniciar. | Se conserva el estado. | Cumplido |
| **P3** | Cambiar el título de una tarea y reiniciar. | Aparece el nuevo título. | Cumplido |
| **P4** | Eliminar una tarea y reiniciar. | No reaparece. | Cumplido |
| **P5** | Intentar agregar un título vacío o de solo espacios. | No se registra la tarea. | Cumplido |
| **P6** | Ejecutar en navegador, recargar y cerrar/abrir la pestaña en el mismo origen y perfil. | Los datos permanecen. | Cumplido |

### Plataformas verificadas y previstas
- **Verificadas:** Entorno **Web** (Chromium/Edge con WebAssembly), entorno **Escritorio** (Windows) y entorno **Móvil** (Android), además de pruebas automatizadas sobre motor SQLite nativo en memoria.
- **Previstas por arquitectura:** **iOS, macOS y Linux** cuentan con sus carpetas nativas configuradas y soporte mediante `drift_flutter` (iOS y macOS requieren compilación con Xcode en macOS; Linux requiere compilación desde Linux).
