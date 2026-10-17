#!/bin/bash
# Install Headroom (https://github.com/headroomlabs-ai/headroom) and run it as a
# persistent local compression proxy on port 8787.
#
# Kept out of install.sh for the same reason as install-skills.sh: it hits the
# network, builds a Python env, and registers a launchd service. install.sh only
# makes symlinks.
#
# The per-agent wiring itself is NOT done here — it lives in the tracked config
# files and lands via install.sh:
#   claude/settings.json     ANTHROPIC_BASE_URL + ANTHROPIC_CUSTOM_HEADERS
#   opencode/opencode.json   provider.9router.options.baseURL + headers
#   pi/models.json           providers.9router.baseUrl + headers
#   omp/models.yml           providers.anthropic + providers.9router
#
# Usage:
#   ./install-headroom.sh          # install + start the service
#   ./install-headroom.sh --check  # only verify an existing install
set -e

PORT=8787

if [ "$1" != "--check" ]; then
  # uv keeps the CLI in its own env. Python 3.13 on purpose: LiteLLM has no
  # 3.14 wheel, and without it the dashboard's "$ saved" tile stays $0.00.
  command -v uv >/dev/null || brew install uv
  uv tool install --python 3.13 "headroom-ai[all]"

  # persistent-service = launchd agent at ~/Library/LaunchAgents/com.headroom.default.plist.
  # scope=provider with providers=manual and no --target: install the service only,
  # and do not let the installer rewrite shell rc files or agent configs — this
  # repo owns those.
  headroom install apply \
    --preset persistent-service \
    --scope provider \
    --providers manual \
    --port "$PORT"
fi

echo
echo "== headroom install status"
headroom install status
echo
echo "== proxy health"
curl -fsS -m 5 "http://127.0.0.1:$PORT/readyz" >/dev/null && echo "ready on $PORT" || {
  echo "NOT ready — check: headroom install start / tail ~/.headroom/logs/proxy.log"
  exit 1
}
echo
echo "Verify a real round trip through the proxy, then read the numbers:"
echo "  claude   -p 'reply with exactly: pong'"
echo "  omp      -p 'reply with exactly: pong'"
echo "  pi       -p --model 9router/cx/gpt-5.4-mini 'reply with exactly: pong'"
echo "  opencode run --model 9router/xai/grok-4.6 'reply with exactly: pong'"
echo "  headroom savings"
echo
echo "Undo: headroom install remove   (service)"
echo "      headroom unwrap omp       (restores ~/.omp/agent/models.yml from its backup)"
