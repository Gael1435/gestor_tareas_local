# Gestor de Tareas Local con SQLite Multiplataforma

Aplicación Flutter para la administración de tareas con persistencia **SQLite local** sin servidor, diseñada para funcionar con una misma base de código en los tres entornos requeridos (**Web**, **Móvil** y **Escritorio**).

---

## Etapa 1: Preparación y Diseño de Persistencia

### 1. Tecnología de persistencia seleccionada: `drift` + `drift_flutter`

Para cumplir con el requisito de persistencia SQLite real en **Android, iOS, Windows, Linux, macOS y Web** desde un solo proyecto Flutter, se eligió la biblioteca **[Drift](https://drift.simonbinder.eu/)** acompañada del paquete oficial **[`drift_flutter`](https://pub.dev/packages/drift_flutter)**.

**Justificación técnica:**
- **Soporte multiplataforma unificado:** A diferencia de `sqflite` (que originalmente solo cubre Android/iOS/macOS y requiere configuraciones manuales separadas con `sqflite_common_ffi` y `sqflite_common_ffi_web`), `drift_flutter` provee la función `driftDatabase()`, que abstrae automáticamente la apertura de la base de datos según el entorno:
  - **Móvil (Android / iOS) y Escritorio (Windows / Linux / macOS):** Ejecuta SQLite nativo mediante `NativeDatabase` y FFI (`sqlite3` + `sqlite3_flutter_libs`) en un `Isolate` en segundo plano, guardando el archivo `.sqlite` en el directorio de documentos de la aplicación (`path_provider`).
  - **Web (Navegadores):** Ejecuta SQLite compilado a **WebAssembly** (`sqlite3.wasm`) dentro de un **Web Worker** (`drift_worker.dart.js`), persistiendo los bloques de datos en el almacenamiento local del navegador (Origin Private File System / IndexedDB) asociado al origen y perfil activo.
- **Seguridad de tipos y generación de código (`build_runner`):** Mediante `drift_dev` y `build_runner`, las tablas definidas en Dart generan clases seguras en tiempo de compilación (`Companion`, `Entity` y consultas tipadas), evitando errores de sintaxis SQL en tiempo de ejecución.
- **Consultas asíncronas y reactivas:** Permite tanto lecturas puntuales (`Future`) como flujos reactivos (`Stream`) fuera del método `build()`.

---

### 2. Diseño de la tabla `tareas` e identificación de registros

Cada tarea se almacena en la tabla **`tareas`** dentro del archivo SQLite local `gestor_tareas_db`.

| Columna | Tipo en Drift (Dart) | Tipo real en SQLite | Restricciones | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| **`id`** | `IntColumn` (`int`) | `INTEGER` | `PRIMARY KEY AUTOINCREMENT NOT NULL` | Identificador único incremental asignado automáticamente por SQLite al insertar (`INSERT`). Se utiliza como clave primaria para localizar sin ambigüedad el registro al actualizar (`UPDATE WHERE id = ?`) o eliminar (`DELETE WHERE id = ?`). |
| **`titulo`** | `TextColumn` (`String`) | `TEXT` | `NOT NULL`, longitud `1..200` | Texto descriptivo de la tarea. Antes de guardarse se valida con `.trim()` para rechazar cadenas vacías o compuestas únicamente por espacios. |
| **`completada`** | `BoolColumn` (`bool`) | `INTEGER` (`0` o `1`) | `NOT NULL DEFAULT 0` | Estado de la tarea. SQLite no posee un tipo booleano nativo separado, por lo que almacena `0` para pendiente (`false`) y `1` para completada (`true`). |

#### Esquema SQL equivalente:

```sql
CREATE TABLE IF NOT EXISTS tareas (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  titulo TEXT NOT NULL CHECK (LENGTH(titulo) >= 1 AND LENGTH(titulo) <= 200),
  completada INTEGER NOT NULL DEFAULT 0 CHECK (completada IN (0, 1))
);
```

---

## Comandos de preparación inicial

```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
