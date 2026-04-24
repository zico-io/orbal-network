# Local LLM (Ollama)

## Overview

Opt-in local LLM server via [Ollama](https://ollama.com) (llama.cpp under the hood), exposing an OpenAI-compatible `/v1` API on the tailnet. Lives in `modules/local-llm.nix`, enabled per-host via `orbal.local-llm.enable = true`. The API is reachable from any tailnet device and not from the public internet.

## Option surface

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `orbal.local-llm.enable` | bool | `false` | Master toggle. |
| `orbal.local-llm.acceleration` | enum `[ "cpu" "cuda" ]` | `"cpu"` | CUDA requires a GPU host with `nixpkgs.config.cudaSupport = true`. |
| `orbal.local-llm.models` | listOf str | `[ ]` | Models to pre-pull at activation, e.g. `[ "llama3.2:3b" "mistral:7b" ]`. |
| `orbal.local-llm.port` | port | `11434` | TCP port for the HTTP API. |
| `orbal.local-llm.webui.enable` | bool | `false` | Open WebUI chat front-end, pre-wired to the local Ollama. |
| `orbal.local-llm.webui.port` | port | `8080` | TCP port the Open WebUI HTTP server listens on. |

`host` and `openFirewall` are intentionally not exposed (on both Ollama and Open WebUI) — they are hardcoded to `0.0.0.0` and `false` respectively so the tailscale-only invariant cannot be broken by host config.

## Security model

Tailscale-only exposure is an emergent property of three things, all of which must hold:

1. The service binds to `0.0.0.0` (module, forced).
2. `services.ollama.openFirewall = false` (module, forced).
3. `modules/base.nix` trusts `tailscale0` via `networking.firewall.trustedInterfaces`.

If (3) ever changes, the API becomes publicly reachable. Audit with the verification steps below whenever base.nix or the module are touched.

## Currently enabled

In `hosts/forge/default.nix`:

```nix
orbal.local-llm = {
  enable = true;
  webui.enable = true;
  models = [ "llama3.2:3b" ];
};
```

- `llama3.2:3b` — Meta's small general-purpose model, CPU-friendly (~2 GB).
- Open WebUI is on; chat UI at `http://<forge-tailscale-ip>:8080`.

On a future GPU host, add `acceleration = "cuda";`.

## How it works

- Wraps the upstream `services.ollama` NixOS module from nixpkgs.
- Models are pre-pulled by upstream's `ollama-model-loader.service`, which runs after `ollama.service`, is idempotent (skips already-present models), and retries with bounded exponential backoff (1s → 2h, 10 steps) on network failure.
- Ollama runs as a systemd `DynamicUser`, state under `/var/lib/ollama` via `StateDirectory=ollama`.
- When `webui.enable = true`, wraps `services.open-webui` from nixpkgs: runs as a hardened `DynamicUser` with state at `/var/lib/open-webui`, pre-configured with `OLLAMA_API_BASE_URL=http://127.0.0.1:${ollama-port}` and telemetry opt-out env vars (`SCARF_NO_ANALYTICS`, `DO_NOT_TRACK`, `ANONYMIZED_TELEMETRY=False`). User accounts and chat history persist across rebuilds in the state dir.

## Verification

After `rebuild switch` on a host with the module enabled:

```sh
systemctl status ollama.service                 # active (running)
systemctl status ollama-model-loader.service    # succeeded, after initial pull
ss -ltnp | grep 11434                           # 0.0.0.0:11434
ollama list                                     # declared models present
```

From another tailnet device:

```sh
curl http://<tailscale-ip>:11434/api/tags       # JSON of loaded models
curl http://<tailscale-ip>:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"llama3.2:3b","messages":[{"role":"user","content":"hi"}]}'
```

If `webui.enable = true`:

```sh
systemctl status open-webui.service             # active (running)
curl -I http://<tailscale-ip>:8080/             # 200 OK from the webui
```

Then open `http://<tailscale-ip>:8080` in a browser on a tailnet device; create the first admin account, chat against a loaded model.

From outside the tailnet (e.g. cellular):

```sh
curl --max-time 5 http://<public-ip>:11434/api/tags   # must fail (timeout / refused)
```

Do the public-unreachability check once per new host.

## Uninstall

Set `orbal.local-llm.enable = false;` and rebuild. Models under `/var/lib/ollama` and Open WebUI state under `/var/lib/open-webui` (user accounts, chat history) are not cleaned up automatically — delete those state dirs manually if you want the disk back.

## Notes

- ROCm is not wired. Add to the `acceleration` enum when an AMD-GPU host appears.
