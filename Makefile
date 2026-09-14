SHELL := /bin/bash
ROOT := $(shell pwd)
NVM := source $$HOME/.nvm/nvm.sh >/dev/null 2>&1; nvm use 24 >/dev/null 2>&1
PNPM := $(NVM); pnpm
NODE := $(NVM); node
VERSAO_ATUAL := $(shell python3 -c "import json; print(json.load(open('desktop/src-tauri/tauri.conf.json'))['version'])" 2>/dev/null)
SETUP := desktop/dist-bundle/Agent Hub_$(VERSAO_ATUAL)_x64-setup.exe

.DEFAULT_GOAL := ajuda

.PHONY: ajuda dev daemon parar token build teste tipos limpar ollama-gpu ollama-parar windows windows-instalar linux instalar-deb pacote pacote-testar versao

ajuda:
	@echo "Subir e usar"
	@echo "  make dev               sobe ollama e o daemon servindo a interface em http://127.0.0.1:47311"
	@echo "  make daemon            so o daemon, em segundo plano, log em /tmp/daemon.log"
	@echo "  make parar             derruba daemon e web"
	@echo "  make servico           instala o daemon como servico do systemd, sobe com a maquina"
	@echo "  make reiniciar         reinicia o daemon (usa o servico quando instalado)"
	@echo "  make token             mostra o token, so necessario para outro dispositivo"
	@echo ""
	@echo "Desenvolvimento"
	@echo "  make build             compila core, daemon e web"
	@echo "  make teste             roda os testes do core"
	@echo "  make tipos             typecheck de core, daemon, relay, channels e web"
	@echo ""
	@echo "Modelo local"
	@echo "  make ollama-gpu        sobe o container do ollama com a GPU"
	@echo "  make ollama-parar      derruba o container do ollama"
	@echo ""
	@echo "Empacotar"
	@echo "  make windows           gera o instalador NSIS em desktop/dist-bundle"
	@echo "  make windows-instalar  gera e instala no Windows em modo silencioso"
	@echo "  make linux             gera deb e rpm em desktop/dist-bundle"
	@echo "  make instalar-deb      instala o deb gerado no WSL (pede sudo)"
	@echo "  make pacote            gera o pacote instalavel agent-hub-VERSAO.tgz em dist-pacote"
	@echo "  make pacote-testar     instala o pacote num container limpo e confere a saude"
	@echo ""
	@echo "Versao"
	@echo "  make versao VERSAO=X.Y.Z  troca a versao em todos os pacotes, cria a tag nos nove repositorios e dispara a Release"

dev:
	bash dev.sh

daemon: build
	@pkill -f "[d]ist/cli.js start" || true
	@sleep 1
	@$(NVM); setsid nohup env OLLAMA_BASE_URL=$${OLLAMA_BASE_URL:-http://127.0.0.1:11434/v1} node daemon/dist/cli.js start > /tmp/daemon.log 2>&1 < /dev/null &
	@sleep 4
	@tail -3 /tmp/daemon.log


servico:
	bash daemon/scripts/instalar-servico.sh

reiniciar:
	@if systemctl --user is-enabled agent-hub.service >/dev/null 2>&1; then \
		systemctl --user restart agent-hub.service && echo "daemon reiniciado pelo systemd"; \
	else \
		$(MAKE) --no-print-directory daemon; \
	fi
parar:
	@pkill -f "[d]ist/cli.js start" || true
	@pkill -f "[v]ite preview" || true
	@echo "daemon e web encerrados"

token:
	@echo "arquivo: $$HOME/.agent-hub/token"
	@echo "no Windows, pelo Explorer: \\\\wsl.localhost\\ubuntu\\home\\$(USER)\\.agent-hub\\token"
	@cat $$HOME/.agent-hub/token
	@echo
	@$(NODE) daemon/dist/cli.js pair --web http://127.0.0.1:47311 --no-qr

build:
	@$(PNPM) -C core build
	@$(PNPM) -C daemon build
	@$(PNPM) -C web exec vite build

teste:
	@$(PNPM) -C core test

tipos:
	@for p in core daemon relay channels; do echo "== $$p"; $(PNPM) -C $$p exec tsc --noEmit; done
	@echo "== web"; $(PNPM) -C web exec vue-tsc --noEmit

limpar:
	@rm -rf core/dist daemon/dist web/dist relay/dist channels/dist
	@echo "dist removidos"

ollama-gpu:
	@docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d ollama
	@curl -s -m 5 http://127.0.0.1:11434/api/tags > /dev/null && echo "ollama no ar em 11434"

ollama-parar:
	@docker compose down

windows: build
	bash desktop/scripts/build-windows-docker.sh
	@ls -la desktop/dist-bundle

windows-instalar: windows
	@powershell.exe -NoProfile -Command "Start-Process -FilePath '$$(wslpath -w "$(ROOT)/$(SETUP)")' -ArgumentList '/S' -Verb RunAs -Wait"
	@echo "instalado em C:\Users\$$(powershell.exe -NoProfile -Command '$$env:UserName' | tr -d '\r')\AppData\Local\Agent Hub"

linux: build
	bash desktop/scripts/build-linux-docker.sh
	@ls -la desktop/dist-bundle

instalar-deb:
	@sudo apt install -y ./desktop/dist-bundle/*.deb

pacote: build
	@$(NVM); bash daemon/scripts/pacote.sh

pacote-testar: pacote
	@bash daemon/scripts/testar-pacote.sh

versao:
	@$(NVM); bash scripts/versao.sh "$(VERSAO)"
