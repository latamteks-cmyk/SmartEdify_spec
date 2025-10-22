# 🔄 **Diagramas de Secuencia - Ciclo de Vida de Convocatorias**

## 1. **Convocatoria por Administración**

```mermaid
sequenceDiagram
    participant A as Administrador
    participant FE as Frontend
    participant G as Governance Service
    participant C as Compliance Service
    participant T as Tenancy Service
    participant UP as User Profiles
    participant F as Finance Service
    participant N as Notifications Service
    participant DB_G as PostgreSQL Gov
    participant DB_C as PostgreSQL Comp

    A->>FE: Iniciar convocatoria asamblea
    FE->>G: POST /assemblies/draft
    G->>T: GET /condominiums/{id}/config
    T-->>G: config{country_code, entity_type, timezone}
    
    G->>UP: GET /users/me/roles
    UP-->>G: roles[ADMIN, MANAGER]
    
    G->>DB_G: INSERT assembly_draft
    DB_G-->>G: assembly_id
    
    G->>C: POST /validations/agenda
    C->>DB_C: SELECT jurisdiction_configs
    DB_C-->>C: legal_rules{min_notice_days: 5, session_mode: hybrid}
    
    C->>C: validate_agenda_points
    C-->>G: validation_result{valid: true, quorum: majority}
    
    G->>DB_G: UPDATE assembly_status = LEGAL_APPROVED
    G->>N: POST /notifications/convene
    N->>N: send_notifications_all_owners
    N-->>G: notifications_sent
    
    G->>DB_G: UPDATE assembly_status = CONVENED
    G-->>FE: assembly_convened_success
    FE-->>A: ✅ Asamblea convocada exitosamente
```

---

## 2. **Convocatoria por Junta Directiva**

```mermaid
sequenceDiagram
    participant JP as Miembro Junta
    participant FE as Frontend
    participant G as Governance Service
    participant C as Compliance Service
    participant UP as User Profiles
    participant T as Tenancy Service
    participant N as Notifications Service
    participant K as Kafka
    participant DB_G as PostgreSQL Gov

    JP->>FE: Proponer asamblea junta
    FE->>G: POST /assemblies/proposal
    G->>UP: GET /users/me/roles
    UP-->>G: roles[BOARD_MEMBER]
    
    G->>T: GET /condominiums/{id}/board_members
    T-->>G: board_members[U1, U2, U3, U4, U5]
    
    G->>DB_G: INSERT assembly_proposal
    DB_G-->>G: proposal_id
    
    G->>C: POST /validations/board_proposal
    C-->>G: validation{allowed: true, quorum: simple_majority}
    
    G->>N: POST /notifications/board_vote
    N->>N: notify_board_members
    
    loop Espera 48h votación junta
        G->>K: SUBSCRIBE BoardVoteEvent
        K-->>G: vote_received
        G->>DB_G: UPDATE vote_count
    end
    
    G->>DB_G: SELECT vote_results
    DB_G-->>G: votes{yes: 3, no: 1, pending: 1}
    
    alt Mayoría aprobatoria
        G->>DB_G: UPDATE proposal_status = APPROVED
        G->>N: POST /notifications/convene
        G->>DB_G: UPDATE assembly_status = CONVENED
        G-->>FE: assembly_approved_by_board
        FE-->>JP: ✅ Asamblea aprobada por junta
    else Sin mayoría
        G->>DB_G: UPDATE proposal_status = REJECTED
        G-->>FE: proposal_rejected
        FE-->>JP: ❌ Propuesta rechazada por junta
    end
```

---

## 3. **Convocatoria por Propietarios (25% Respaldo)**

```mermaid
sequenceDiagram
    participant PO as Propietario
    participant FE as Frontend
    participant G as Governance Service
    participant C as Compliance Service
    participant UP as User Profiles
    participant F as Finance Service
    participant I as Identity Service
    participant N as Notifications Service
    participant DB_G as PostgreSQL Gov
    participant DB_UP as PostgreSQL Profiles

    PO->>FE: Iniciar propuesta ciudadana
    FE->>G: POST /assemblies/citizen_proposal
    G->>UP: GET /users/me/property_status
    UP-->>G: property{unit: A101, status: active}
    
    G->>F: GET /units/A101/payment_status
    F-->>G: payment{current: true, defaulting: false}
    
    G->>DB_G: INSERT citizen_proposal
    DB_G-->>G: proposal_id
    
    G->>C: POST /validations/citizen_topics
    C-->>G: validation{allowed_topics: [budget, facilities], restricted: [structural_changes]}
    
    G->>UP: GET /condominium/{id}/eligible_owners
    UP->>F: GET /units/payment_status_batch
    F-->>UP: eligible_owners_count
    UP-->>G: total_eligible: 100
    
    G->>DB_G: UPDATE proposal{required_support: 25, expiry_date: +15d}
    G->>N: POST /notifications/proposal_launch
    N->>N: notify_all_owners_new_proposal
    
    loop Período 15 días - Recolección respaldos
        PO->>FE: Firmar respaldo propuesta
        FE->>I: POST /signatures/validate
        I-->>FE: signature_valid
        FE->>G: POST /proposals/{id}/support
        G->>UP: GET /users/me/property_status
        UP-->>G: property_info
        G->>F: GET /payment_status
        F-->>G: payment_ok
        G->>DB_G: INSERT support_signature
        G->>DB_G: UPDATE support_count
        G->>FE: support_registered
    end
    
    G->>DB_G: SELECT support_count
    DB_G-->>G: current_support: 28
    
    alt ≥25% respaldo
        G->>DB_G: UPDATE proposal_status = SUPPORT_ACHIEVED
        G->>C: POST /validations/final_approval
        C-->>G: final_validation_ok
        G->>DB_G: UPDATE assembly_status = CONVENED
        G->>N: POST /notifications/convene_official
        G-->>FE: proposal_converted_to_assembly
        FE-->>PO: 🎉 Propuesta alcanzó 25% - Asamblea convocada
    else <25% respaldo
        G->>DB_G: UPDATE proposal_status = SUPPORT_FAILED
        G->>N: POST /notifications/proposal_expired
        G-->>FE: proposal_expired
        FE-->>PO: 😔 Propuesta no alcanzó respaldo suficiente
    end
```

---

## 4. **Convocatoria Extraordinaria/Urgente**

```mermaid
sequenceDiagram
    participant AU as Actor Autorizado
    participant FE as Frontend
    participant G as Governance Service
    participant C as Compliance Service
    participant UP as User Profiles
    participant T as Tenancy Service
    participant N as Notifications Service
    participant I as Identity Service
    participant DB_G as PostgreSQL Gov

    AU->>FE: Solicitar convocatoria urgente
    FE->>G: POST /assemblies/emergency
    G->>UP: GET /users/me/roles
    UP-->>G: roles[ADMIN, BOARD_MEMBER, EMERGENCY_COMMITTEE]
    
    G->>C: POST /validations/emergency
    C->>C: validate_emergency_criteria
    alt Cumple criterios urgencia
        C-->>G: emergency_approved{reduced_notice: 24h, virtual_allowed: true}
        
        G->>DB_G: INSERT emergency_assembly
        DB_G-->>G: assembly_id
        
        G->>T: GET /condominium/contact_channels
        T-->>G: channels[push, sms, phone, email]
        
        G->>N: POST /notifications/emergency
        N->>N: send_priority_notifications
        
        G->>I: POST /auth/emergency_tokens
        I-->>G: emergency_access_tokens
        
        G->>DB_G: UPDATE assembly_status = EMERGENCY_CONVENED
        G-->>FE: emergency_assembly_created
        FE-->>AU: 🚨 Asamblea de emergencia convocada (24h)
    else No cumple criterios
        C-->>G: emergency_rejected{reason: no_urgency_criteria}
        G-->>FE: emergency_request_denied
        FE-->>AU: ❌ No cumple criterios de emergencia
    end
```

---

## 5. **Flujo Unificado - Estados del Ciclo de Vida**

```mermaid
sequenceDiagram
    participant A as Actor
    participant G as Governance Service
    participant C as Compliance Service
    participant UP as User Profiles
    participant F as Finance Service
    participant N as Notifications Service
    participant DB as PostgreSQL

    Note over A,DB: 📝 Estado: DRAFT
    A->>G: Crear borrador
    G->>C: Validar temas
    C-->>G: temas_válidos
    G->>DB: Guardar borrador
    
    Note over A,DB: ⚖️ Estado: LEGAL_VALIDATION
    G->>C: Validación completa MCP
    C->>C: verificar_quórum_mayoría
    C-->>G: validación_completa
    
    alt Convocatoria Propietarios
        Note over A,DB: 📢 Estado: SUPPORT_COLLECTION
        G->>N: Notificar propuesta
        loop 15 días
            A->>G: Firmar respaldo
            G->>UP: Validar propietario
            G->>F: Verificar habilitación
            G->>DB: Registrar respaldo
        end
        G->>DB: Calcular % respaldo
        alt ≥25% respaldo
            Note over A,DB: ✅ Estado: SUPPORT_ACHIEVED
        else <25% respaldo
            Note over A,DB: ❌ Estado: SUPPORT_FAILED
        end
    end
    
    Note over A,DB: 🎯 Estado: CONVENED
    G->>N: Enviar convocatorias
    G->>DB: Actualizar estado
    
    Note over A,DB: ⏳ Estado: NOTIFICATION_PERIOD
    G->>G: Esperar días mínimos
    
    Note over A,DB: 🔍 Estado: QUORUM_VERIFICATION
    G->>UP: Contar participantes
    G->>F: Verificar habilitados
    G->>DB: Calcular quórum
    
    alt Quórum alcanzado
        Note over A,DB: 🟢 Estado: IN_PROGRESS
    else Quórum no alcanzado
        Note over A,DB: 🔴 Estado: CANCELLED
    end
    
    Note over A,DB: 📊 Estado: COMPLETED
    G->>DB: Registrar resultados
    G->>N: Notificar acta
```

---

## 6. **Validación MCP en Tiempo Real por Punto de Agenda**

```mermaid
sequenceDiagram
    participant G as Governance Service
    participant C as Compliance Service
    participant MCP as Motor Legal MCP
    participant DB_C as PostgreSQL Comp
    participant R as Redis Cache

    loop Por cada punto de agenda
        G->>C: POST /validate/agenda-point
        C->>R: GET cache:legal_rules:{country}:{entity}
        alt Cache Hit
            R-->>C: cached_rules
        else Cache Miss
            C->>MCP: POST /mcp/validate-point
            MCP->>MCP: analizar_marco_legal
            MCP-->>C: validation_result
            C->>DB_C: INSERT legal_validation
            C->>R: SET cache:legal_rules
        end
        
        C->>C: aplicar_validación_específica
        C-->>G: point_validation{
            is_valid: boolean,
            required_quorum: string,
            majority_type: string,
            legal_restrictions: json,
            recommendations: array
        }
        
        G->>G: acumular_resultados_validación
    end
    
    G->>G: determinar_estado_general_agenda
    alt Todos puntos válidos
        G->>G: marcar_agenda_legalmente_aprobada
    else Algunos puntos inválidos
        G->>G: generar_recomendaciones_corrección
    end
```

---

## 🎯 **Resumen de Estados por Tipo de Convocatoria:**

| **Estado** | **Administración** | **Junta** | **Propietarios** | **Emergencia** |
|------------|-------------------|-----------|------------------|----------------|
| **DRAFT** | ✅ | ✅ | ✅ | ✅ |
| **LEGAL_VALIDATION** | ✅ | ✅ | ✅ | ✅ (Acelerado) |
| **BOARD_APPROVAL** | ❌ | ✅ | ❌ | ❌ |
| **SUPPORT_COLLECTION** | ❌ | ❌ | ✅ | ❌ |
| **CONVENED** | ✅ | ✅ | ✅ | ✅ (Inmediato) |
| **NOTIFICATION_PERIOD** | 5-10 días | 5-10 días | 5-10 días | 24-48 horas |
| **QUORUM_VERIFICATION** | ✅ | ✅ | ✅ | ✅ |
| **IN_PROGRESS** | ✅ | ✅ | ✅ | ✅ |

**Cada tipo de convocatoria sigue su propio camino a través del ciclo de vida, con validaciones MCP en tiempo real garantizando el cumplimiento legal en todos los puntos.**

## 📋 Tipos de Roles y Atribuciones

´´´mermaid
mindmap
  root((Roles Organizacionales))
    Junta de Propietarios
      Presidente
        :Firma actas y resoluciones
        :Representación legal
        :Convocatoria asambleas
      Vicepresidente
        :Suple presidente
        :Comisiones especiales
      Secretario
        :Redacción actas
        :Custodia documentación
      Tesorero
        :Fiscalización financiera
        :Informes económicos
    Administración
      Administrador Principal
        :Gestión operativa
        :Ejecución acuerdos
      Administrador Suplente
        :Suple administrador
        :Emergencias operativas
    Comités
      Comité Ética
        :Resolución conflictos
        :Aplicación reglamento
      Comité Emergencia
        :Decisiones urgentes
        :Gestión crisis
    Auditoría
      Auditor Interno
        :Control procesos
        :Verificación cumplimiento
      Revisor Fiscal
        :Auditoría financiera
        :Cumplimiento legal
´´´
