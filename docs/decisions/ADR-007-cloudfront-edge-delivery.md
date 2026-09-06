\# ADR-007 — Entrega edge mediante CloudFront



\- Estado: Aceptado

\- Fecha: 2026-09-06



\## Contexto



El Task Manager necesita distribuir un frontend estático y una API sin exponer directamente S3 ni, en su estado final, el Application Load Balancer.



\## Decisión



CloudFront será el punto público de entrada con dos orígenes:



\- S3 privado para la ruta por defecto `/\*`.

\- Application Load Balancer para la ruta `/api/\*`.



El bucket S3 tendrá Block Public Access habilitado y CloudFront accederá mediante Origin Access Control.



No se configurará Route 53 ni se comprará un dominio durante la primera fase. Se utilizará el dominio predeterminado de CloudFront.



\## Consecuencias



\- Frontend y API compartirán un único origen, evitando configuración CORS inicial.

\- La ruta `/api/\*` no tendrá caché de respuestas dinámicas.

\- La configuración final del ALB restringirá entrada a tráfico proveniente de CloudFront.

\- El dominio propio, certificado ACM y Route 53 quedan como mejora posterior.

