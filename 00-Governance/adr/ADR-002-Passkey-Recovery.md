# ADR-002: Recuperación de Passkeys y Manejo de MFA

## Estado
Aprobado

## Fecha
2025-10-21

## Autores
Arquitectura de Seguridad

## Contexto
Es necesario establecer una estrategia de recuperación segura para passkeys y un manejo adecuado de MFA que proteja a los usuarios contra fraudes y pérdida de acceso.

## Decisión
Implementar un sistema de recuperación basado en múltiples factores de confianza, incluyendo mecanismos alternativos seguros y procesos de validación con tiempo limitado.

## Consecuencias
- Mejora la experiencia del usuario al permitir recuperación de acceso
- Mantiene altos estándares de seguridad
- Requiere desarrollo adicional de mecanismos de verificación
- Aumenta la complejidad de los flujos de autenticación