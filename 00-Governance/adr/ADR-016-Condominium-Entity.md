# ADR-016: Modelo de Entidad Condominio

## Estado
Aprobado

## Fecha
2025-10-08

## Autores
Arquitectura de Dominio

## Contexto
Necesitamos establecer el modelo de datos estándar para representar entidades condominio que permita la jerarquía Tenant → Condominio → Edificio → Unidad → Espacio.

## Decisión
Definir un modelo de entidad condominio con soporte para múltiples jurisdicciones legales y aislamiento mediante RLS por tenant_id y condominium_id.

## Consecuencias
- Habilita el modelo de negocio multi-condominio
- Garantiza aislamiento de datos entre tenants
- Facilita cumplimiento normativo por jurisdicción
- Requiere implementación de RLS en todas las capas de acceso a datos