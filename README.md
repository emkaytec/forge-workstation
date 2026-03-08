# Forge Workstation

This repository contains the infrastructure and workstation management code for remote development environments, including Ansible host configuration and a reusable GCP workstation Terraform module.

## Assumptions

- Workstations already exist and are bootstrapped by Terraform.
- Each workstation is reachable by its Tailscale hostname.
- The `forge` user exists on each host and has sudo access.
- Secrets stay outside this repository for now.

## Repository Layout

- `Makefile` - top-level command entrypoint that runs Ansible from `ansible/`
- `README.md` - repository documentation and operational notes
- `ansible/ansible.cfg` - repo-local Ansible defaults
- `ansible/inventory/hosts.yml` - static workstation inventory
- `ansible/inventory/hosts.local.yml` - local untracked workstation inventory overrides
- `ansible/examples/hosts.local.example.yml` - example local inventory with placeholders
- `ansible/inventory/group_vars/all.yml` - shared inventory variables
- `ansible/playbooks/bootstrap.yml` - initial entrypoint playbook
- `ansible/roles/ai_tools/` - agentic AI CLI installers and auth guidance
- `ansible/roles/base/` - baseline workstation configuration
- `ansible/roles/cloud_tools/` - shared cloud and infrastructure CLIs
- `ansible/roles/code_editor/` - browser-based VS Code access with code-server
- `ansible/roles/docker/` - container and Kubernetes CLI tooling
- `ansible/roles/dev_tools/` - shared developer CLI tooling
- `ansible/roles/git/` - shared Git configuration for the primary user
- `ansible/roles/idle_shutdown/` - automatic VM shutdown when the host is idle
- `ansible/roles/kube_tools/` - placeholder for future Kubernetes platform CLIs
- `ansible/roles/mise/` - polyglot runtime manager for developer toolchains
- `ansible/roles/shell/` - shared interactive shell configuration for the primary user
- `terraform/modules/gcp-workstation/` - copied GCP workstation Terraform module source

The Terraform workstation module supports separate names for the GCP instance and the in-guest workstation hostname. By default, the GCP instance name is prefixed as `ws-<workstation_name>`, while the Linux and Tailscale hostnames stay aligned to `workstation_name`.

## Local Inventory

Real workstation names and personal identity values are kept in the untracked file `ansible/inventory/hosts.local.yml`.

To set up a new clone, copy the example file and fill in your real values:

```bash
cp ansible/examples/hosts.local.example.yml ansible/inventory/hosts.local.yml
```

## Quick Start

The preferred interface for common workflows is `make`.

The `Makefile` runs all Ansible commands from inside `ansible/`, so you can continue using the same top-level commands from the repo root.

Show the available commands:

```bash
make help
```

Verify Ansible can reach the workstation:

```bash
make ping
```

Preview changes without applying them:

```bash
make check
```

Apply the base workstation configuration:

```bash
make apply
```

Run against a single host explicitly:

```bash
make ping-host HOST=workstation-name
make check-host HOST=workstation-name
make apply-host HOST=workstation-name
```

## Make Targets

- `make help` - show the available commands
- `make ping` - ping all hosts in the `workstations` group
- `make ping-host HOST=<name>` - ping a single host from local inventory
- `make check` - dry-run the bootstrap playbook with diff output
- `make check-host HOST=<name>` - dry-run the bootstrap playbook for one host
- `make apply` - apply the bootstrap playbook
- `make apply-host HOST=<name>` - apply the bootstrap playbook to one host
- `make syntax` - validate playbook syntax
- `make inventory` - show the inventory graph
- `make inventory-list` - show the resolved inventory as JSON
- `make list-hosts` - list hosts in the `workstations` group
- `make facts HOST=<name>` - gather facts for a single host

## Base Role Scope

The initial `base` role intentionally stays small and focuses on shared, low-risk host configuration:

- apt cache refresh
- baseline package installation
- timezone configuration
- locale configuration
- common user config directory setup

## Cloud Tools Role

The `cloud_tools` role installs shared cloud and infrastructure CLIs used across workstation environments.

- installs `gh` from the official GitHub CLI apt repository
- installs `google-cloud-cli` from the official Google Cloud apt repository
- installs AWS CLI v2 from the standalone upstream zip installer

Terraform is managed through `mise`, which makes it easier to pin versions per workstation or keep them aligned with repo requirements. The current shared default is `1.14.0`, matching `/Volumes/Bolt/Code/emkaytec/forge/terraform.tf`.

## Code Editor Role

The `code_editor` role installs `code-server` so the workstation can be accessed in a browser as a remote VS Code environment.

- installs `code-server` with the upstream standalone installer into `~/.local/bin`
- runs it as a systemd service on port `8443`
- serves the primary workspace directory at `~/code`
- currently uses `auth: none` because access is limited to your Tailscale network
- keeps `code-server` bound locally on `127.0.0.1:8443` over plain HTTP
- exposes it to your tailnet over HTTPS using `tailscale serve`

The idle shutdown role also treats port `8443` as activity so an active browser editor session keeps the workstation awake.

## AI Tools Role

The `ai_tools` role installs standalone AI coding CLIs for the primary workstation user.

- installs `opencode` from upstream release artifacts
- installs `claude` using Anthropic's native installer
- installs `codex` from upstream release artifacts
- installs user-local binaries into `~/.local/bin`
- keeps authentication state out of this repository

### Authentication strategy

For now, keep AI tool authentication user-local and interactive rather than storing secrets in Ansible.

- use each tool's native login flow on the workstation after installation
- let per-user auth state live in the user's home directory
- keep API keys and tokens out of this repo until there is a clear secret-management plan
- use inventory variables only for non-secret install choices like enabled tools or pinned versions

When you are ready to centralize authentication, the likely next step is introducing a secrets backend such as Ansible Vault, 1Password CLI, or another external secret source.

## Idle Shutdown

The bootstrap playbook also installs an idle shutdown timer and checker modeled on the working implementation from the Terraform-managed workstation setup.

- monitors established connections on port `22`
- also treats active interactive user sessions as activity
- ignores detached `tmux` and `screen` sessions
- powers the VM off after `60` minutes of inactivity by default
- checks every `5` minutes by default
- can be paused by creating `/etc/workstation/disable-idle-shutdown`

Current defaults live in `ansible/roles/idle_shutdown/defaults/main.yml`.

To temporarily prevent automatic shutdown during long-running work:

```bash
sudo touch /etc/workstation/disable-idle-shutdown
```

To re-enable automatic shutdown:

```bash
sudo rm /etc/workstation/disable-idle-shutdown
```

Note that detached `tmux` and `screen` sessions do not count as activity, so ad hoc background jobs should either use the guard file or run under a durable service manager such as `systemd`.

## Shell Role

The `shell` role adds a small shared interactive shell baseline for the primary workstation user.

- installs `zsh` and `less`
- sets `zsh` as the default shell for the primary user
- installs `.oh-my-zsh` into the user's home directory
- ensures `~/.local/bin` exists and is added to `PATH`
- manages `~/.zshrc` and `~/.zshrc.local`
- sets common editor, pager, and shell history defaults
- installs a few basic aliases such as `ll`, `la`, and `l`

## Git Role

The `git` role installs a shared `~/.gitconfig` for the primary workstation user.

- sets the default branch name to `main`
- enables `fetch.prune`
- keeps `pull.rebase` disabled by default
- sets shared editor, pager, line-ending, and merge-conflict defaults
- installs a few convenience aliases such as `st`, `co`, `br`, `ci`, and `lg`
- supports optional `git_user_name` and `git_user_email` inventory overrides when you want to set identity

## Dev Tools Role

The `dev_tools` role installs a conservative baseline of common CLI tools for interactive development work.

- installs `build-essential`
- installs `ripgrep`, `fd-find`, `fzf`, and `tree`
- adds compatibility symlinks so `fd-find` is available as `fd`

## Docker Role

The `docker` role installs the local container runtime and core Kubernetes packaging tools.

- installs Docker Engine, CLI, Buildx, and Compose from the official Docker apt repository
- installs `kubectl` as a standalone binary in `/usr/local/bin/kubectl`
- installs `helm` from the official Helm apt repository
- enables and starts the Docker service
- adds the primary workstation user to the `docker` group

## Mise Role

The `mise` role installs the `mise` runtime manager for the primary workstation user and integrates it with `zsh`.

- installs `mise` into `~/.local/bin/mise`
- adds shell activation through `~/.zshrc.d/mise.zsh`
- manages the global config at `~/.config/mise/config.toml`
- installs globally configured runtimes and tools such as `terraform`

## Next Steps

- Add more workstation hosts to `inventory/hosts.yml` as they come online.
- Split additional concerns into focused roles such as `shell`, `git`, `ssh`, `dev_tools`, and `services`.
- Keep personal and host-specific values in `ansible/inventory/hosts.local.yml` and shared policy in role defaults or `ansible/inventory/group_vars/all.yml`.
