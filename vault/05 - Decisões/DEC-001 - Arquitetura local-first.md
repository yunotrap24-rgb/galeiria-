# DEC-001 — Arquitetura local-first com dois aplicativos

Data: 2026-09-01
Status: APROVADA

## Decisão

O Galeiria terá dois aplicativos reais:

1. aplicativo de PC (Windows inicialmente), que hospeda servidor, banco, indexador, armazenamento e IA;
2. aplicativo Android, que acessa a galeria e sincroniza com o PC, especialmente na mesma rede Wi-Fi.

O PC é a autoridade principal da biblioteca.

## Motivos

- aproveitar HDD/SSD/NAS do usuário;
- reduzir dependência de nuvem;
- processamento de IA mais pesado no PC;
- sincronização LAN rápida;
- preservar funcionamento offline;
- permitir app móvel simples e focado.

## Consequências

- será necessário protocolo de descoberta/autenticação/sync;
- conflitos devem ser versionados e nunca sobrescritos silenciosamente;
- operações de organização são lógicas por padrão;
- a camada de IA externa permanece opcional.
