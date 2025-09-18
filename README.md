# Docker Container Updater

A (mostly) useless PS script to update all Docker containers located in `./Containers` subdirectories (assuming they have compose files). If you need to do that. And don't want to use watchtower. For some reason. Which I can't think of.

## Usage

1. Place your Docker containers in subdirectories under `./Containers/`
2. Run the script:
```powershell
./update-containers.ps1
```
