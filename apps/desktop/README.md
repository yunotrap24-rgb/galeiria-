# Galeiria Desktop

Aplicativo real para PC (Windows primeiro), escrito em Flutter.

## Responsabilidades

- escolher e administrar a biblioteca local;
- iniciar/acompanhar o servidor local;
- acompanhar indexação;
- navegar na galeria;
- revisar duplicadas e semelhantes;
- configurar IA;
- gerenciar dispositivos móveis e sincronização.

## Arquitetura

A UI é Flutter e conversa com o serviço Python em `services/api`. No desenvolvimento, o servidor pode ser iniciado com `galeiria-api`/Uvicorn. No empacotamento Windows, ele será distribuído como sidecar/serviço gerenciado pelo app desktop.

O app usa `packages/galeiria_client` para compartilhar os contratos REST com o Android.

## Estado atual

O primeiro shell já oferece conexão com a API, caminho da biblioteca, disparo de scan e painel de estatísticas. O runner nativo Windows será gerado com o Flutter SDK; veja `scripts/bootstrap-flutter.ps1`.
