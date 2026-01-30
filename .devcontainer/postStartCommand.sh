#!/bin/bash

# ----- Headless Mode Detection -----
# When running headless (without VS Code), auto-enable development mode
if [ "${HEADLESS_MODE}" = "true" ]; then
    echo "Headless mode detected. Auto-enabling development mode..."
    export ENABLE_DEVELOPMENT_MODE=true
    # Use bash instead of zsh for headless (zsh may not be default shell)
    SHELL_RC="$HOME/.bashrc"
    SHELL_HOOK='eval "$(direnv hook bash)"'
else
    SHELL_RC="$HOME/.zshrc"
    SHELL_HOOK='eval "$(direnv hook zsh)"'
fi

# Clear up /tmp directory
sudo rm -rf /tmp/duckietown/*

# Configure mDNS for fast .local resolution
sudo sed -i 's/^hosts:.*/hosts: files mdns4_minimal [SUCCESS=return] mdns6_minimal [SUCCESS=return] dns/' /etc/nsswitch.conf
sudo grep -q "single-request-reopen" /etc/resolv.conf || sudo echo "options timeout:1 attempts:1 single-request-reopen" | sudo tee -a /etc/resolv.conf
# Install duckietown-shell
pipx install duckietown-shell

# Start dbus daemon
sudo dbus-daemon --system --fork

# Start avahi daemon
sudo avahi-daemon -D

# Docker credentials fix
export DOCKER_CONFIG="$(mktemp -d)"
printf '{}' > "$DOCKER_CONFIG/config.json"

# Add DOCKER_CONFIG to shell rc for persistent access
if ! grep -q "export DOCKER_CONFIG=" "$SHELL_RC"; then
	echo "export DOCKER_CONFIG=\"$DOCKER_CONFIG\"" >> "$SHELL_RC"
fi

# Check if development mode is enabled and run direnv allow
if [ "${ENABLE_DEVELOPMENT_MODE}" = "true" ]; then
	echo "Development mode enabled. Setting up direnv..."
	
	# Add direnv hook to shell rc if not already present
	if ! grep -q "$SHELL_HOOK" "$SHELL_RC"; then
		echo "$SHELL_HOOK" >> "$SHELL_RC"
		echo "Direnv hook added to $SHELL_RC"
	fi
	
	# Run direnv allow
	cd /workspaces/dt-env-developer || { echo 'Error: Cannot change to workspace directory'; exit 1; }
	direnv allow
	echo "Direnv setup complete."
else
	echo "Development mode not enabled (set ENABLE_DEVELOPMENT_MODE=true in .devcontainer/.env to enable)."
	
	# Remove direnv hook from shell rc if present
	if grep -q "$SHELL_HOOK" "$SHELL_RC"; then
		sed -i "\|$SHELL_HOOK|d" "$SHELL_RC"
		echo "Direnv hook removed from $SHELL_RC"
	fi

	sudo rm -rf /tmp/vscode-ssh-auth-* # This is a workaround to disable SSH agent forwarding in devcontainers
	unset SSH_AUTH_SOCK
	eval "$(ssh-agent -s)"
	echo "SSH agent started. The container will not have access to your host's SSH keys."
fi

echo "Setup complete. Please open a new terminal."