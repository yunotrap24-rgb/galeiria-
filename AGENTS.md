# AGENTS.md — Regras para qualquer IA que trabalhe no Galeiria

## Antes de trabalhar

Leia, nesta ordem:

1. `README.md`
2. `vault/00 - Projeto/Visão Geral.md`
3. `vault/00 - Projeto/Roadmap.md`
4. `vault/01 - Arquitetura/Arquitetura Geral.md`
5. `vault/03 - Desenvolvimento/Tarefas.md`
6. `vault/05 - Decisões/`
7. sessões recentes em `vault/06 - Sessões/`

## Regras

- Não apagar nem mover fotos do usuário sem confirmação explícita.
- Não versionar mídia do usuário, bancos locais, tokens ou chaves de API.
- O app deve funcionar sem IA externa.
- Reutilizar bibliotecas/projetos open source maduros antes de recriar funcionalidades.
- Verificar licença antes de incorporar código de terceiros.
- Duplicata exata, quase duplicata e similaridade visual devem permanecer conceitos separados.
- PC é a autoridade principal da biblioteca; celular é cliente sincronizado.
- Preferir mudanças pequenas, testáveis e reversíveis.

## Ao terminar uma tarefa

Atualize:

- `vault/03 - Desenvolvimento/Tarefas.md`
- `vault/03 - Desenvolvimento/Implementações.md`
- uma nota em `vault/06 - Sessões/AAAA-MM-DD - <IA>.md`

Se houver decisão arquitetural, crie/atualize um ADR em `vault/05 - Decisões/`.

## Handoff

Toda sessão deve registrar:

- objetivo;
- contexto lido;
- arquivos modificados;
- testes executados;
- problemas encontrados;
- decisões propostas/tomadas;
- próximo passo recomendado.
