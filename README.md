# Agent Hub

Iniciativa para construir um cliente de agentes de IA multi-provedor, com
controle total de custo, que roda em desktop, web e mobile a partir de uma
unica base, e que executa codigo remotamente na maquina do usuario.

Esta pasta agrupa os repositorios da iniciativa. Cada subpasta e um
repositorio git independente.

| Repositorio | Papel |
|-------------|-------|
| `docs/`     | Planejamento, arquitetura, decisoes (ADRs) e roadmap |
| `core/`     | Biblioteca TypeScript: adaptadores de provedor, loop de agente, ledger de custo, ferramentas e cliente MCP |
| `daemon/`   | Servico local que roda na maquina do usuario. Fonte da verdade das sessoes. Executa ferramentas e expoe a API para os clientes |
| `relay/`    | Servidor de retransmissao para acesso remoto (web e mobile) ao daemon sem expor porta |
| `web/`      | Interface Vue 3 como PWA. Usada pelo desktop, pelo navegador e pelo celular |
| `desktop/`  | Casca Tauri que embute a interface web e sobe o daemon como sidecar |
| `agents/`   | Perfis de agente, skills, workflows, agendamentos, precos, MCP e politicas. Versionado separado para sincronizar entre maquinas |
| `channels/` | Clientes do daemon que vivem em plataformas de mensagem (Telegram primeiro) |

Comece por `docs/README.md`.

## Estado atual

Fases 1 a 3 completas e parte da fase 4, com codigo verificado por testes
e smoke tests: `core` (42 testes), `agents`, `daemon` (inclusive servidor
MCP para o Claude Code), `web`, `relay` e `channels` (Telegram). `desktop`
e um esqueleto Tauri ainda nao compilado. Falta validar com chaves reais
de provedor. Ver `docs/08-roadmap.md`.

## Ambiente de desenvolvimento

No WSL, `nvm use 24` antes de qualquer comando; o pnpm esta instalado
nessa versao. `core`, `daemon`, `relay` e `channels` usam TypeScript 7;
`web` fixa TypeScript 5 por causa do `vue-tsc`.

## Rodar o esqueleto

```bash
cd core && pnpm install && pnpm test && pnpm build
cd ../daemon && pnpm install && pnpm build
node dist/cli.js init
node dist/cli.js agents
```

Depois edite `~/.agent-hub/config.toml` com `agents_dir` apontando para
`agents/` e ao menos um workspace, exporte as chaves de API e use
`node dist/cli.js chat --agent deepseek-dev --workspace /caminho`.

Interface web: `cd web && pnpm install && pnpm dev`, depois conecte em
`http://localhost:5173/connect` com a URL e o token de
`node dist/cli.js pair`. Acesso remoto: suba `relay`, configure
`relay_url` no daemon e use o modo relay na tela de conexao.
