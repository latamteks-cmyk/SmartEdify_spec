# 🧪 Plan de Pruebas: Tenancy Service (3003)

## 1. Objetivos de las Pruebas

Este plan de pruebas busca validar que el `tenancy-service` funcione como la "raíz de confianza organizacional" de SmartEdify. Las pruebas se centrarán en la correcta gestión de la jerarquía, el aislamiento de datos, la resiliencia ante fallos y la correcta integración con los demás servicios del ecosistema, basándose en los SLOs y escenarios definidos en su SAD.

---

## 2. Tipos de Pruebas

### 2.1. Pruebas Unitarias

- **Objetivo:** Validar la lógica de negocio interna y las restricciones del modelo.
- **Cobertura Mínima:** 85%.
- **Escenarios Clave:**
  - Validación de la profundidad máxima de la jerarquía (Tenant → Condo → Building → Unit → Subunit).
  - Lógica de validación de códigos de jurisdicción y moneda.
  - Correcta construcción de los payloads para los eventos de Kafka.
  - Lógica de parseo y validación de la configuración de `data_residency`.

### 2.2. Pruebas de Integración

- **Objetivo:** Validar la correcta interacción del `tenancy-service` con la base de datos, el bus de eventos y otros servicios.
- **Escenarios Clave:**
  - **Aislamiento de Datos (RLS):**
    - Simular dos tenants (A y B) con sus propias jerarquías.
    - Ejecutar una serie de operaciones CRUD (ej. `GET /v1/tenants/{id}/condominiums`) con un token del Tenant A.
    - **Verificar** que solo se devuelven los datos del Tenant A y que cualquier intento de acceder a los datos del Tenant B resulta en un error `404` o una lista vacía, pero nunca en una fuga de datos.
  - **Publicación de Eventos en Kafka:**
    - Crear un nuevo condominio a través de la API (`POST /v1/condominiums`).
    - **Verificar** que se publica un evento `CondominiumCreated` en el topic `tenancy.events` con el schema y los datos correctos.
    - Modificar una unidad y verificar la emisión del evento `UnitUpdated`.
  - **Consumo por Otros Servicios:**
    - Simular al `identity-service` llamando al `tenancy-service` para validar el contexto de un usuario. Verificar que la respuesta es rápida y precisa.

### 2.3. Pruebas de Seguridad

- **Objetivo:** Identificar y mitigar vulnerabilidades relacionadas con el acceso y la manipulación de la jerarquía organizacional.
- **Escenarios Clave:**
  - **Escalada de Privilegios Horizontal (Cross-Tenant):** El escenario principal de las pruebas de integración RLS. Intentar que un administrador de un tenant modifique o vea datos de otro tenant.
  - **Manipulación de Jerarquía:** Intentar crear una entidad (ej. `Unit`) bajo un `Building` que no pertenece al mismo `Condominium` o `Tenant`.
  - **Inyección de Datos:** Probar todos los endpoints de la API contra ataques de inyección (SQLi, etc.), aunque el uso de un ORM y queries parametrizadas debería mitigar esto en gran medida.

### 2.4. Pruebas de Rendimiento y Carga

- **Objetivo:** Asegurar que el servicio cumple con sus SLOs de latencia y disponibilidad bajo carga.
- **Escenarios Clave:**
  - **SLO de Lectura:** Cargar el endpoint `GET /v1/tenants/{id}` con un alto volumen de peticiones concurrentes. **Objetivo: P95 ≤ 100 ms**.
  - **SLO de Escritura:** Realizar una prueba de carga sobre el endpoint `POST /v1/condominiums` para medir la latencia de creación, incluyendo la publicación del evento en Kafka. **Objetivo: P95 ≤ 500 ms**.
  - **Prueba de Estrés:** Incrementar la carga hasta que el servicio comience a degradarse para validar los umbrales de auto-escalado.

### 2.5. Pruebas de Resiliencia (Chaos Engineering)

- **Objetivo:** Validar la capacidad del servicio para sobrevivir a fallos en su infraestructura y dependencias, conforme a los escenarios del SAD.
- **Escenarios Clave:**
  - **Fallo de Región Primaria:** Ejecutar el playbook de DRP. Simular la caída de la región `sa-east-1` y **verificar** que el tráfico conmuta a `us-east-1` en menos de 30 segundos y que el RTO se cumple.
  - **Partición de Red:** Bloquear la comunicación entre regiones y **verificar** que el servicio opera en modo degradado usando el caché local firmado.
  - **Fallo de KMS:** Simular la caída del KMS y **verificar** que el servicio puede seguir operando para lecturas y que las escrituras se bloquean de forma controlada.
  - **Fallo de Kafka:** Simular la caída del bróker de Kafka y **verificar** que los eventos se almacenan localmente (patrón Outbox) para ser enviados una vez se restablezca el servicio, evitando la pérdida de datos.

---

## 3. Herramientas y Entorno

- **Pruebas Unitarias/Integración:** JUnit 5, Mockito, Testcontainers (para PostgreSQL, Kafka, Redis).
- **Pruebas de API:** Postman/Newman, k6.
- **Pruebas de Carga:** k6, Grafana k6-dashboard.
- **Chaos Engineering:** Gremlin, Istio Fault Injection.
- **Entorno:** Pipeline de CI/CD en GitLab que despliega en un entorno de `staging` para la ejecución de pruebas automatizadas.


---

## ✅ Actualizaciones según Arquitectura de Base de Datos v2.2 (2025-10-13)

### 🔐 Validación Extendida de RLS
- Se incorporan pruebas para verificar que `tenant_id` y `condominium_id` estén presentes y correctamente aplicados en todas las entidades descendientes (`buildings`, `units`, `subunits`).
- Se validan vistas, funciones y materialized views bajo contexto RLS.

### 📡 Eventos Kafka Adicionales
- Se añaden pruebas para verificar la publicación de eventos:
  - `UnitCreated`
  - `TenantUpdated`
  - `JurisdictionChanged`
  - `SubunitAssigned`

### 🧪 Pruebas de Metadatos Extendidos
- Se validan los campos extendidos en `data_residency`:
  - `complianceFrameworks`
  - `retentionPolicy`
  - `replicationRegions`
- Se verifica que estos metadatos estén presentes en los payloads y se respeten en las respuestas de la API.

### 🧩 Pruebas de Integración con OpenAPI
- Se valida que el campo `updatedAt` esté presente en el esquema `Tenant`.
- Se verifica que los contratos estén sincronizados con el modelo DBML.

---

## ✅ Estado Final
Este plan de pruebas ha sido actualizado para reflejar completamente la arquitectura de base de datos v2.2 y está listo para ejecución en entorno de staging.
