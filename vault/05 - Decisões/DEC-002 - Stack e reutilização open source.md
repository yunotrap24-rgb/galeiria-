# DEC-002 — Stack e estratégia de reutilização open source

Data: 2026-09-01
Status: APROVADA

## Decisão

O Galeiria terá núcleo próprio e modular, reutilizando bibliotecas permissivas quando isso reduzir trabalho, mas **não será um fork direto do Immich ou PhotoPrism**.

### Interface

- **Flutter** para o app Windows e para o app Android.
- Os dois continuam sendo aplicativos separados (`apps/desktop` e `apps/mobile`), mas compartilham contratos/API em `packages/galeiria_client`.

### PC / servidor

- Python + FastAPI como serviço local/sidecar.
- SQLite para metadados e estado inicial.
- Arquivos originais permanecem nas pastas escolhidas pelo usuário.

### Duplicadas

- SHA-256 para duplicata exata.
- dHash local para candidatos a quase duplicatas no bootstrap.
- Embeddings CLIP/SigLIP serão uma camada separada para semelhança semântica.

### Componentes candidatos futuros

- Qdrant (Apache-2.0) caso seja necessário índice vetorial dedicado.
- PaddleOCR (Apache-2.0) para OCR local.
- HomeGallery (MIT) como referência técnica para busca de imagens semelhantes.
- Syncthing (MPL-2.0) como referência/transportador opcional, não como fonte de verdade do protocolo de sincronização do Galeiria.

## Por que não fork direto do Immich/PhotoPrism

Ambos são excelentes projetos e referências, porém usam AGPL-3.0. Além da questão de licença, o Galeiria tem requisitos diferentes: PC desktop como produto principal, biblioteca existente sem migração obrigatória, organização específica de produção/impressão 3D e sincronização de metadados/projetos própria.

Immich também adota arquitetura de servidor maior (Postgres, Redis e serviço de machine learning) e seu app móvel usa Flutter; aproveitaremos as ideias de arquitetura, não o código diretamente nesta fase.

## Fontes verificadas

- Immich: https://github.com/immich-app/immich
- Arquitetura Immich: https://docs.immich.app/developer/architecture/
- PhotoPrism: https://github.com/photoprism/photoprism
- HomeGallery: https://github.com/xemle/home-gallery
- Syncthing: https://github.com/syncthing/syncthing
- Flutter platforms: https://docs.flutter.dev/reference/supported-platforms
- Qdrant: https://github.com/qdrant/qdrant
- PaddleOCR: https://github.com/PaddlePaddle/PaddleOCR

## Consequências

- evitamos dependência forte de um projeto AGPL grande;
- mantemos liberdade para trocar OCR, embeddings e IA;
- Flutter reduz duplicação entre Windows e Android sem transformar os dois em um único aplicativo;
- sync continuará sendo desenhado especificamente para biblioteca + metadados do Galeiria.
