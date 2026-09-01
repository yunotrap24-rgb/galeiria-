# Galeiria API

Backend local inicial da Galeiria.

## Rodar

```bash
cd services/api
python -m venv .venv
# Windows: .venv\Scripts\activate
# Linux/macOS: source .venv/bin/activate
pip install -e ".[dev]"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8765
```

Teste de saúde:

```text
GET http://127.0.0.1:8765/health
```

Indexar uma pasta:

```json
POST /api/v1/libraries/scan
{
  "path": "D:\\Fotos"
}
```

Listar fotos indexadas:

```text
GET /api/v1/photos
```

Thumbnail:

```text
GET /api/v1/photos/{id}/thumbnail
```

## Estado

Esta é a V1 inicial. A varredura é não destrutiva e já suporta retomada simples: arquivos cujo tamanho e `mtime` não mudaram são pulados na próxima varredura.

Próximos passos: jobs em background, perceptual hash, duplicadas, EXIF completo, vídeos e embeddings.
