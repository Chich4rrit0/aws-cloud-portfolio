\# Proyecto 01 — Arquitectura de red y seguridad



\- Estado: Diseño aprobado

\- Región: `us-east-1`

\- Recursos desplegados: ninguno



\## Diagrama lógico



```mermaid

flowchart TB

&#x20;   Internet((Internet))



&#x20;   Internet --> ALB\[Application Load Balancer<br/>Public edge subnets]

&#x20;   ALB -->|TCP 3000| AppA\[EC2 / Node.js<br/>Public app subnet AZ 1a]

&#x20;   ALB -->|TCP 3000| AppB\[EC2 / Node.js<br/>Public app subnet AZ 1b]



&#x20;   AppA -->|TCP 5432| RDS\[(RDS PostgreSQL<br/>Private database subnets)]

&#x20;   AppB -->|TCP 5432| RDS



&#x20;   Internet -. Frontend planned .-> CF\[CloudFront]

&#x20;   CF -. Static assets planned .-> S3\[S3]



&#x20;   classDef public fill:#e8f4ff,stroke:#1f77b4;

&#x20;   classDef private fill:#eef7ea,stroke:#2e7d32;

&#x20;   class ALB,AppA,AppB public;

&#x20;   class RDS private;

