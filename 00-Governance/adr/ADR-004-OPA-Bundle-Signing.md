# ADR-004: Firma de Bundles OPA

## Estado
Aprobado

## Fecha
2025-12-02

## Autores
Arquitectura de Seguridad

## Contexto
Necesitamos asegurar la integridad y autenticidad de los bundles de políticas OPA que se distribuyen a través del sistema para garantizar la seguridad del control de acceso basado en políticas (PBAC).

## Decisión
Implementar un sistema de firma digital de bundles OPA utilizando criptografía asimétrica para garantizar integridad y autenticidad.

## Consecuencias
- Asegura que las políticas no puedan ser modificadas maliciosamente
- Habilita verificación criptográfica en tiempo de evaluación
- Aumenta la seguridad del sistema de control de acceso
- Requiere gestión de claves criptográficas