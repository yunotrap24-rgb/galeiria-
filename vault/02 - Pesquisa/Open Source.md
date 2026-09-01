# Pesquisa Open Source

## Estratégia

Antes de implementar um módulo grande, comparar projetos existentes por: maturidade, licença, manutenção, compatibilidade, possibilidade de integração e custo de adaptação.

## Candidatos iniciais

### Immich
- Excelente referência para galeria self-hosted, mobile, thumbnails, backup/sync e machine learning.
- Licença atual: AGPL-3.0.
- Consequência: reutilizar/incorporar código diretamente exige análise cuidadosa das obrigações da AGPL.
- Ação: estudar arquitetura e componentes reutilizáveis/independentes antes de decidir fork.

### PhotoPrism
- Referência forte para indexação e organização de fotos self-hosted.
- Ação: revisar licença e separação dos componentes antes de incorporar código.

### HomeGallery / LocalLens / rclip
- Candidatos para pesquisa visual/semântica e similaridade.
- Ação: revisar licença, modelos usados e maturidade.

### Componentes independentes
- Pillow/OpenCV: processamento de imagem.
- CLIP/SigLIP: embeddings e busca semântica.
- Qdrant/alternativa: índice vetorial se SQLite não for suficiente.
- bibliotecas de perceptual hash: quase duplicatas.
- OCR local: Tesseract ou alternativa moderna.

## Regra

Não copiar código de terceiros antes de registrar licença e justificativa em uma decisão arquitetural.
