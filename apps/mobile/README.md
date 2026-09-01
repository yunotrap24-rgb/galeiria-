# Galeiria Mobile

Aplicativo Android real em Flutter, separado do app de PC.

## Responsabilidades

- visualizar a biblioteca do PC;
- visualizar/importar fotos locais;
- enviar fotos e vídeos novos;
- pesquisar e abrir projetos;
- favoritos e tags;
- detectar o servidor Galeiria na mesma rede local;
- sincronizar automaticamente conforme regras do usuário.

## Regras de sincronização

- PC é a autoridade principal;
- identificar conteúdo por IDs/hashes, não só nomes;
- suportar retomada de transferência;
- nunca sobrescrever conflito silenciosamente;
- opções futuras: somente Wi-Fi, somente carregando, manter original ou cache otimizado.

## Tecnologia

Flutter foi escolhido para Android e Windows. Os apps são separados, mas usam `packages/galeiria_client` para o contrato REST.

## Estado atual

O shell Android permite informar o endereço do PC, testar conexão e navegar pelas thumbnails. Descoberta LAN, upload e background sync entram nas próximas etapas. O runner Android será gerado com o Flutter SDK; veja `scripts/bootstrap-flutter.ps1`.
