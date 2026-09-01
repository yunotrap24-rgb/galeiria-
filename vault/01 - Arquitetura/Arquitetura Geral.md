# Arquitetura Geral

## Visão

```text
Android App <---- LAN/HTTPS ----> PC App / Local Server
                                  |
                                  +-- Library Storage (HDD/SSD/NAS)
                                  +-- SQLite
                                  +-- Thumbnail cache
                                  +-- Indexer
                                  +-- Duplicate detector
                                  +-- Vector search
                                  +-- AI Bridge
```

## Autoridade dos dados

O PC é a autoridade principal. O celular mantém estado sincronizado e poderá manter originais, cópias otimizadas ou somente cache conforme configuração.

## Separação de responsabilidades

- `apps/desktop`: interface/empacotamento do PC.
- `apps/mobile`: aplicativo Android.
- `services/api`: API local, banco e contratos.
- `services/indexer`: pipeline de processamento de mídia.
- `services/ai-bridge`: integração opcional com provedores de IA.
- `packages/shared`: modelos/contratos compartilhados.
- `vault`: documentação e memória para humanos/IAs.

## Ordem do pipeline

1. inventário do arquivo;
2. metadados e SHA-256;
3. thumbnail;
4. perceptual hash;
5. OCR;
6. embedding;
7. duplicadas e similaridade;
8. contexto/classificação local;
9. score de confiança;
10. IA externa somente se necessário.

## Regra de destruição

Nenhuma etapa de indexação pode apagar/mover o original. Operações destrutivas devem passar por ação explícita do usuário e lixeira/rollback quando implementadas.
