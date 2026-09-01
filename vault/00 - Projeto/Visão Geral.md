# Visão Geral — Galeiria

## Missão

Criar uma galeria inteligente local-first especializada em referências para modelagem/impressão 3D, imagens geradas por IA, fotos de peças, produção e produtos finais.

## Arquitetura de produto

- **PC app**: servidor local, armazenamento, indexação, pesquisa, duplicadas, IA e sincronização.
- **Mobile app Android**: galeria, captura/importação, pesquisa e sincronização automática com o PC na mesma rede Wi-Fi.
- **Obsidian Vault**: memória compartilhada do desenvolvimento para múltiplas IAs.

## Fluxo principal

```text
imagem nova
  -> metadados
  -> SHA-256
  -> perceptual hash
  -> OCR
  -> embeddings
  -> duplicadas/semelhantes
  -> contexto/classificação local
  -> confiança
  -> IA externa somente se necessário
  -> tags/projetos/biblioteca
```

## Categorias iniciais

- Referências
- Imagens geradas por IA
- Modelagem 3D
- Impressão 3D
- Produção
- Produtos
- Favoritos

## Regra de segurança

A organização inicial é lógica. O aplicativo não move, renomeia ou apaga originais automaticamente.
