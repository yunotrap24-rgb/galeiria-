# Galeiria Mobile

Aplicativo Android real, separado do app de PC.

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

Flutter e React Native são candidatos. A escolha será registrada após comparar reutilização de componentes open source e requisitos de sincronização em background no Android.
