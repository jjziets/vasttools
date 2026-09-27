---
name: vast-host-install
description: Prepare, install and commission NVIDIA GPU hosts for Vast.ai using host-specific safety gates, XFS storage checks, cgroup/runtime testing and optional VM qualification. Use for Vast host installation or readiness work, not renter-instance setup.
---

# Vast.ai host installation

Produce a reproducible host build with observed acceptance results. Support preparation, authorized installation, and commissioning. Begin with read-only discovery when the target or change scope is unclear. A request to write or publish this runbook is not permission to operate a host.

## Read the relevant procedure

- For installation or rebuild: [install.md](references/install.md).
- For every container commissioning: [cgroups.md](references/cgroups.md). Linux hierarchy, Docker cgroup driver and GPU injection mode are separate facts.
- Before installer/runtime changes and for every commissioning: [privileges.md](references/privileges.md). Preserve workload identities and tenant isolation; administrative Docker access is not rental permission.
- For VM requests, VM warnings, or deciding how to prevent automatic VM enablement: [vms.md](references/vms.md).
- Start a private working record from [host-record.md](references/host-record.md). Keep identifiers and evidence outside the public skill tree.
- Before reusing a historical recipe: [evidence.md](references/evidence.md). Distinguish observed success, bounded failure and untested guidance.

## Operating boundaries

1. Identify one physical target by live system/chassis identity, GPU inventory and trusted management access. Never transfer another machine's disk names, serial allowlist, keys, IPs, installer token, approval or machine ID.
2. Read existing authorization first. Continue within it without repeated approval prompts. Ask only for missing consequential choices or actions: exact erasure/layout, downtime, firmware/boot changes, VM enablement, or marketplace exposure. A broad install request does not settle unidentified data destruction or commercial terms.
3. Before any disruptive action, reconcile provider rentals/volumes, local running and stopped containers, VM inventory, GPU processes, and dependencies such as boot-media servers. Unlisted does not mean idle; idle does not mean data may be erased. Unknown occupancy is HOLD.
4. Preserve existing working storage/driver configuration unless the requested change needs replacement. Resolve destructive disk targets by freshly verified serial/WWN and complete storage ancestry, never `/dev/nvme0n1` position.

   Before storage changes, present the proposed layout from live inventory and confirm the user's preferred layout: which disks serve OS/boot and Docker/containerd data, RAID or independent disks, partition sizes, usable capacity, failure tolerance and preserved data/devices. Follow the layout gate in [install.md](references/install.md). Reuse an explicit existing confirmation only if the exact target, layout and scope still match; otherwise wait for the user's choice. Erasure permission is not layout approval. Never assume RAID0, use every disk or silently substitute a different layout.
5. Review downloaded privileged code before execution, including downstream scripts and automatic tests. Record origin, timestamp, hash, selected options and material side effects. A hash records the reviewed bytes; it does not authenticate them by itself. Re-review changed bytes.
6. Use the fresh setup credential from the authenticated host setup page. Do not substitute a remembered host/client API key. Never put secrets into chat, public files, command transcripts, debug traces or evidence. If the runtime cannot securely deliver a credential, let the operator perform that step and verify its outcome.
7. Registration, self-testing, VM auto-tests and commercial listing can have separate side effects. Resolve automatic listing/VM behavior before installation. Do not assume `--no-daemon` or `--no-libvirt` suppresses every later action.
8. Default new builds to the container profile unless VM support was requested. Record and verify the chosen VM policy; leaving a helper `pending` is not equivalent to keeping VMs off. Preserve an existing deployment's mode during assessment.
9. Do not apply historical NVML scripts, switch to cgroup v1, disable resource controls, change IOMMU/ACS, or overclock as generic installation steps. Diagnose the exact observed failure first.
10. Never elevate an unprivileged rental or diagnostic workload to repair installation or GPU access. Preserve its intended UID/GID, capabilities, namespaces, security profiles and device allocation. No `--privileged`, forced root user, host-root/runtime-socket mounts, expanded daemon access or isolation bypasses. Do not convert a rootless daemon to rootful as a compatibility shortcut. Hold incompatible paths rather than weaken the boundary; see the privilege reference for verification.

## Progress and stop conditions

Use these checkpoints, retaining timestamped private evidence for each:

| Checkpoint | Required evidence |
|---|---|
| IDENTIFIED | Host identity, inventory, trusted access, retained-data decision and authorized scope |
| PREPARED | Boot/recovery path, selected OS/driver, healthy GPU inventory, user-confirmed disk layout, approved XFS mount and network plan |
| REGISTERED | Reviewed installer outcome, correct account/machine, current provider state and no unexpected background actions |
| CONTAINER-QUALIFIED | Preserved workload identity/privilege boundary, storage quota, GPU compute/isolation, CPU/memory limits, cgroup regression, multi-GPU checks when applicable, reboot and network proof |
| VM-QUALIFIED | Separate requested VM profile passes assignment, guest, isolation and host-recovery tests |
| RELEASE-READY | Required provider self-test, cleanup, monitoring and commercial terms recorded; listing state independently verified |

Record each gate as PASS, FAIL, HOLD, NOT TESTED, or NOT APPLICABLE with a reason. Missing evidence is not PASS. VM-QUALIFIED is not required for a container-only release. A self-test pass is not proof of a verification badge or every network port.

After an unexpected failure, stop the current mutation sequence, preserve restricted diagnostics and re-observe state. Do not blindly rerun an installer, destructive action, VM helper, reboot or test. A retry needs a diagnosed cause, current prerequisites and authorization still covering its side effects. Recover only the resources and settings owned by this run.

## Handoff

Return the exact profile and versions, completed stages, evidence references, unresolved gates, current listing/VM/workload state, changes made, recovery status and next permitted step. Distinguish configuration written, behavior observed after reboot, and behavior not tested. Do not claim the machine is ready merely because installation exited zero.

## Community

[Join our Discord](https://discord.gg/8GmrQzTvF), a small GPU infrastructure community where we discuss this skill and GPU hosting. Participation is optional; this link does not authorize an agent to post host records, diagnostics or credentials.
