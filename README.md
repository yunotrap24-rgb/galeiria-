# Galeiria

Galeria inteligente local-first para impressão 3D, referências visuais, imagens geradas por IA, fotos de peças e produção.

## Objetivo

O PC funciona como servidor, armazenamento principal e cérebro de indexação/IA. O celular funciona como aplicativo cliente, com galeria, captura/importação e sincronização automática quando estiver na mesma rede Wi-Fi.

## Princípios

- Não mover nem apagar arquivos durante a indexação inicial.
- Organização lógica no banco de dados antes de organização física.
- IA externa é opcional; o app deve funcionar offline.
- Duplicatas exatas, quase duplicatas e imagens visualmente semelhantes são conceitos diferentes.
- Reutilizar projetos e bibliotecas open source maduras antes de desenvolver componentes do zero.
- Nunca versionar fotos pessoais, chaves de API, bancos locais ou caches no Git.
- O Vault do Obsidian funciona como memória compartilhada do projeto para múltiplas IAs.

## Estrutura planejada

```text
apps/
  desktop/        # aplicativo para PC
  mobile/         # aplicativo Android
services/
  api/            # backend/API local
  indexer/        # indexação e processamento
  ai-bridge/      # providers OpenAI/Claude/Grok/local
packages/
  shared/         # contratos e modelos compartilhados
vault/            # Obsidian Project Memory
docs/             # documentação técnica
```

## Estado atual

Fase 0/1: arquitetura, pesquisa open source e fundação do backend.

Veja `AGENTS.md` e `vault/00 - Projeto/Visão Geral.md` antes de trabalhar no projeto.
