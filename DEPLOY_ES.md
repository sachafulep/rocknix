# Deploying a freshly compiled `emulationstation` to the RG351M

Run after `./rebuild-es.sh` completes successfully. Device: `root@192.168.1.70`.

## Checklist

- [ ] Confirm the build succeeded and note the commit it built:
  ```bash
  cat .last-es-commit
  ```
- [ ] Locate the compiled binary (path uses that commit hash):
  ```bash
  BIN=build.ROCKNIX-RK3326.aarch64/install_pkg/emulationstation-$(cat .last-es-commit)/usr/bin/emulationstation
  ls -l "$BIN"
  ```
- [ ] Copy it to the device's persistent storage (not the read-only system partition):
  ```bash
  scp "$BIN" root@192.168.1.70:/storage/emulationstation-dev
  ```
- [ ] SSH into the device and stop the running UI service:
  ```bash
  ssh root@192.168.1.70
  systemctl stop essway
  ```
- [ ] Remove any existing bind-mount before re-binding (avoids pointing at a stale copy):
  ```bash
  umount /usr/bin/emulationstation 2>/dev/null || true
  ```
- [ ] Make the new binary executable and bind-mount it over the stock one:
  ```bash
  chmod 755 /storage/emulationstation-dev
  mount --bind /storage/emulationstation-dev /usr/bin/emulationstation
  ```
- [ ] Restart the UI service and confirm the new process is running:
  ```bash
  systemctl start essway
  ps aux | grep emulationstation
  ```

## One-time setup (only needed once)

- [ ] Make `/storage/.config/autostart/001-emulationstation-dev` persist the bind-mount across reboots:
  ```bash
  mkdir -p /storage/.config/autostart
  cat > /storage/.config/autostart/001-emulationstation-dev << 'EOF'
  #!/bin/bash
  chmod 755 /storage/emulationstation-dev
  mount --bind /storage/emulationstation-dev /usr/bin/emulationstation
  EOF
  chmod 755 /storage/.config/autostart/001-emulationstation-dev
  ```
- [ ] Set up passwordless SSH so the steps above don't prompt every time:
  ```bash
  ssh-copy-id root@192.168.1.70
  ```

## Notes

- `essway.service` is the active UI service on this device (not `emustation.service` — that one isn't used here).
- The bind-mount is fully reversible: `umount /usr/bin/emulationstation` (or a reboot without the autostart script in place) restores the factory binary.
- New custom resources (fonts, images) go directly on the device at `/storage/.config/emulationstation/resources/` — that path is checked before the exe's own directory, so no rebuild is needed for resource-only changes.
