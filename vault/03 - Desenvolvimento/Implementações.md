# Implementações

## Bootstrap V1 — 2026-09-01

Criada a fundação do backend local:

- SQLite em `~/.galeiria/galeiria.sqlite3` por padrão;
- scanner recursivo de imagens;
- SHA-256 por arquivo;
- extração básica de largura, altura e formato;
- geração de thumbnails JPEG em cache local;
- reindexação simples que pula arquivos sem alteração de tamanho/mtime;
- endpoints FastAPI para saúde, scan, listagem e thumbnail;
- teste automatizado do fluxo inicial.

Nenhuma operação move, renomeia ou apaga arquivos originais.
