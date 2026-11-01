# ama-local

**ama-local** is a centralized repo that orchestrates the local development stack for the `ama-app`, `ama-api`, and `ama-infra` repositories. It defines `mise` tasks that delegate to the actual scripts and package.json scripts in those repos, allowing you to launch the entire stack from a single location.

## Directory Structure

This repo **must be cloned in the same parent directory** as the other `ama-*` repos:

```
/home/username/git/ask-me-anything/
├ ama-local/       <- this repo (mise config + tasks)
├ ama-api/         <- API server (Go + Firebase emulators)
├ ama-app/         <- Expo/React Native frontend
└ ama-infra/       <- CDKTF infrastructure
```

The tasks in `ama-local` use relative paths (`../ama-api/`, `../ama-app/`, `../ama-infra/`) so they work regardless of the absolute path, as long as the repos are siblings.

## What's Included

- **Go API** - managed via `ama-api/go.mod` and launched via `ama-api/build.sh`
- **Firebase Emulators** - configured in `ama-api/firebase.json`, launched via `ama-api/build.sh db/run`
- **Expo/React Native** - dependencies managed via `ama-app/package.json`, launched via Expo CLI
- **CDKTF/CDK** - dependencies managed via `ama-infra/package.json`, launched via `cdktf` CLI
- **Docker** - required as a prerequisite for some workflows (ensure `docker` is installed and running)

**Tool versions are NOT pinned in this repo.** Instead, they are managed by the sub-repos' own files:
- Go version → `ama-api/go.mod`
- Node.js/expo version → `ama-app/package.json`
- CDKTF version → `ama-infra/package.json`

Run `mise install` in each sub-repo to install their respective tool versions, or ensure the required tools are available globally.

## Available Mise Tasks

| Task | What it does | Delegates to |
|------|-------------|-------------|
| `mise run api-db` | Start Firebase emulators (auth, firestore, ui) | `../ama-api/build.sh db` |
| `mise run api-run` | Start Firebase emulators + Go API server | `../ama-api/build.sh run` |
| `mise run expo-start` | Start Expo development server (Metro + RN) | `cd ../ama-app && npx expo start` |
| `mise run expo-android` | Start Expo with Android emulator/device | `cd ../ama-app && npx expo start --android` |
| `mise run expo-ios` | Start Expo with iOS simulator | `cd ../ama-app && npx expo start --ios` |
| `mise run expo-web` | Start Expo web development server | `cd ../ama-app && npx expo start --web` |
| `mise run cdktf-synth` | Synthesize CDKTF infrastructure | `cd ../ama-infra && npx cdktf synth` |
| `mise run cdktf-get` | Fetch CDKTF dependencies | `cd ../ama-infra && npx cdktf get` |

## Getting Started

1. Clone `ama-local` alongside the other `ama-*` repos:
   ```bash
   git clone <url> git@github.com:yourorg/ask-me-anything.git
   cd ask-me-anything
   ```

2. Install all dependencies (tools + project deps) from one location:
   ```bash
   mise run install
   ```
   This runs `mise install` to install tool versions (Go, Node), then installs project dependencies in each sub-repo by reading their manifest files:
   - `npm install` in `ama-app` (reads `ama-app/package.json` - pnpm is not used in sub-repos)
   - `go mod tidy` in `ama-api` (reads `ama-api/go.mod`)
   - `npm install` in `ama-infra` (reads `ama-infra/package.json`)
   
   Alternatively, install tools separately per sub-repo:
   ```bash
   cd ama-api && mise install    # installs Go
   cd ama-app && mise install    # installs Node.js
   cd ama-infra && mise install  # installs TypeScript + cdktf deps
   ```

3. Start the full local stack with one or more tasks:
   ```bash
   # Start just the API with emulators
   mise run api-run

   # Start just the Firebase emulators
   mise run api-db

   # Start the Expo dev server
   mise run expo-start

   # Start CDKTF synth
   mise run cdktf-synth
   ```

4. For React Native development with simulator/emulator:
   ```bash
   mise run expo-android   # opens Expo with Android
   mise run expo-ios       # opens Expo with iOS simulator
   ```

## How It Works

The `mise.toml` file defines tasks that use **relative paths** to delegate to the actual scripts in the sub-repos. This means:

- No tool versions are hardcoded in `ama-local` - they are managed by the sub-repos
- Tasks dynamically reference `../ama-api/`, `../ama-app/`, `../ama-infra/` so they work from any machine as long as the repos are cloned as siblings
- The actual `build.sh`, `package.json` scripts, and `cdktf` commands run in their respective repo contexts, ensuring the correct versions and configurations are used