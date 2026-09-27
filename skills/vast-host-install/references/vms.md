# Optional Vast VM profile

VM support is a separate qualification. Container success is not VM evidence. This package contains an assessment/recovery procedure; it does not establish a successfully validated VM profile.

## Decide the profile

At the source check on 2026-09-27, Vast described VM hosting as optional, recommended considering it for single-GPU and suitable RTX 40-series hosts, and advised against multi-GPU datacenter enablement because of P2P/NVLink concerns. Recheck this recommendation for the target hardware and software. [Vast VM guidance](https://docs.vast.ai/host/vms)

For a new container-only build, establish a supported way to suppress automatic VM testing before running the installer. Inspect downstream updater/cron behavior too. After installation, inspect the installed helper before using its documented `check`/`off` interface; verify `off` rather than `pending`. Apply a mode change only within the authorized build/maintenance scope. For existing hosts, assessment alone does not authorize switching a working mode.

Documented status examples, after local helper review:

```bash
python3 /var/lib/vastai_kaalia/enable_vms.py check
```

`pending` can mean an attempt will occur when idle; it is not a stable disabled state. Do not force enablement to clear a generic dashboard warning.

## Preflight for a requested VM attempt

Resolve VM-specific authorization and an idle window with independent console recovery. Record what happens on helper failure before starting it. Preserve existing definitions/data and inventory all domains, including stopped ones.

Inspect:

- CPU virtualization, KVM device/modules and hardware IOMMU support.
- Genuine IOMMU groups for every proposed GPU and associated functions; any other device sharing a group must be accounted for in the isolation plan. Never use ACS override to manufacture tenant isolation.
- Current NVIDIA DRM modeset, display managers, GPU processes and native device bindings. A generic IOMMU warning can actually originate from DRM modeset validation.
- Compatible QEMU/libvirt package versions and origins. Resolve exact dependency conflicts narrowly; do not install arbitrary older packages or broad pin overrides.
- The reviewed helper's selection logic, VM image, guest agent and cleanup behavior. Identical model strings must not collapse distinct GPUs; verify expected BDFs and VM XML host-device assignments before launching a guest.
- The baseline all-GPU container/NCCL result, so a VM change cannot silently damage normal hosting.

Only add vendor-appropriate IOMMU or DRM boot parameters if a demonstrated prerequisite is missing. Record current and proposed settings, preserve unrelated boot options, verify generated boot entries and reboot within scope. Do not import an AMD flag into an Intel host or assume a setting took effect without reading back its runtime state.

## Execute and verify

Use the current provider-supported procedure after reviewing its side effects. The historical/documented enable command is:

```bash
sudo python3 /var/lib/vastai_kaalia/enable_vms.py on -f
```

This can detach GPUs and launch guests; it is never a discovery command. Do not run it until every preflight gate is satisfied. Record helper hash, expected GPU BDF/UUID set and pre-run driver bindings. Arrange bounded monitoring and service restoration even on failure, while ensuring restoration cannot re-expose an unhealthy host.

Acceptance requires the requested device assignment, guest boot, guest-agent health, GPU enumeration and CUDA correctness inside the guest, networking, expected isolation and clean guest teardown. For a multi-GPU promise, verify actual multi-GPU assignment and appropriate in-guest collective correctness. A one-GPU guest cannot validate an eight-GPU capability.

After teardown, compare **every** host GPU BDF/UUID and bound driver against baseline, then rerun native, container and applicable all-rank NCCL checks. Verify the resulting VM status, services and provider state independently. Repeat relevant checks after the agreed reboot; record that firmware/group changes can affect container performance too.

## Failure and recovery

Check for incomplete GPU selection, failed guest enumeration and incomplete device reattachment. Repeated model names must not collapse distinct GPUs into one assignment. VM mode reverting to off does not prove that host devices are bound correctly.

If selection or cleanup is wrong, stop repeated attempts. Preserve the hash and minimal redacted diagnostics for the owner to escalate; do not locally patch provider integrity-managed daemon/helper code as a generic fix. Disable further automatic attempts through the supported interface within the approved recovery scope. Remove only the exact owned test guest and restore only the services/settings changed by this run.

An `off` result does not prove host recovery. If devices remain missing/unbound, use the approved recovery plan, potentially including a controlled reboot after rechecking occupancy. Require all original bindings and native/container/NCCL checks before returning the host to service. Hold VM readiness until a supported corrected path and successful target-specific acceptance exist. Container service may resume only after its own recovery gates pass and the intended exposure is authorized.
