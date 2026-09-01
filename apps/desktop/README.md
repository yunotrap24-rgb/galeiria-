# Galeiria Desktop

Aplicativo real para PC (Windows primeiro).

## Responsabilidades

- escolher e administrar a biblioteca local;
- iniciar/parar o servidor local;
- acompanhar indexação;
- navegar na galeria;
- revisar duplicadas e semelhantes;
- configurar IA;
- gerenciar dispositivos móveis e sincronização.

## Arquitetura provisória

A interface desktop será empacotada separadamente do backend. Tauri + frontend web é o candidato inicial, mas a decisão final depende da Fase 0 de comparação open source.

O backend em `services/api` deve continuar executável independentemente da interface desktop.
