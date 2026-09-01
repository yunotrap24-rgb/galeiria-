# Pesquisa Open Source

## Resultado da Fase 0 inicial

A prioridade é reutilizar **componentes** maduros e permissivos, e não transformar Galeiria em um fork difícil de manter.

| Projeto/componente | Função útil | Licença verificada | Decisão inicial |
|---|---|---|---|
| Immich | referência de galeria, mobile, backup, CLIP, arquitetura | AGPL-3.0 | estudar arquitetura; não incorporar diretamente nesta fase |
| PhotoPrism | referência de indexação/organização self-hosted | AGPL-3.0 | estudar ideias; não usar como base direta |
| HomeGallery | reverse image lookup e galeria local | MIT | forte referência; avaliar componentes/algoritmos isolados |
| Syncthing | transporte P2P e descoberta/sync | MPL-2.0 | referência e possível transporte opcional; não será banco/estado do Galeiria |
| Syncthing-Fork Android | wrapper Android atual para Syncthing | MPL-2.0 | referência para background Android; integração não decidida |
| Qdrant | busca vetorial | Apache-2.0 | candidato para fase de embeddings, somente se SQLite/local não bastar |
| PaddleOCR | OCR local | Apache-2.0 | candidato preferencial para OCR avançado |
| Flutter | Windows + Android | SDK/ecossistema | escolhido para os dois apps, em projetos separados |

## Immich

Pontos que valem aproveitar como desenho:

- cliente-servidor via REST;
- clientes gerados a partir de OpenAPI;
- app móvel Flutter;
- jobs de processamento separados do request HTTP;
- busca por metadados/objetos/CLIP;
- prevenção de duplicação e backup móvel.

Não será base direta porque a arquitetura e licença adicionariam complexidade desnecessária ao objetivo local-first desktop do Galeiria.

## PhotoPrism

É uma ótima referência para biblioteca self-hosted e indexação. O projeto principal também declara AGPL-3.0. Portanto permanece referência, não dependência direta.

## HomeGallery

Tem licença MIT e declara reverse image lookup. É um candidato melhor para estudar abordagens de busca semelhante sem assumir todo o produto.

## Sincronização

Syncthing é maduro e MPL-2.0. Porém o Galeiria precisa sincronizar não apenas arquivos, mas também favoritos, tags, projetos, versões e conflitos de maneira controlada. Por isso o protocolo Galeiria continuará próprio. Syncthing pode futuramente ser oferecido como transporte/backup opcional.

## Componentes independentes

- Pillow: processamento e thumbnails no bootstrap.
- SHA-256: duplicatas exatas.
- dHash implementado localmente: quase duplicatas iniciais.
- CLIP/SigLIP: futura similaridade semântica.
- Qdrant: futuro índice vetorial opcional.
- PaddleOCR: futuro OCR local.

## Fontes

- https://github.com/immich-app/immich
- https://docs.immich.app/developer/architecture/
- https://github.com/photoprism/photoprism
- https://github.com/xemle/home-gallery
- https://github.com/syncthing/syncthing
- https://github.com/Catfriend1/syncthing-android
- https://github.com/qdrant/qdrant
- https://github.com/PaddlePaddle/PaddleOCR
- https://docs.flutter.dev/reference/supported-platforms

## Regra

Nenhuma IA deve copiar código de terceiros sem registrar a licença e justificar a integração em um ADR.
