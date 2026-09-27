# Private host execution record template

Copy outside the public repository. Replace fields with observed values or an explicit unknown; do not execute the template. Never include credentials, setup commands containing tokens, tenant content or complete raw environment/process dumps.

## Scope

- Run ID and UTC start/window:
- Requested outcome: assess / prepare / install / commission / list:
- Profile: containers / containers plus VMs:
- Opening network answer: user-specified public address, inclusive start/end TCP/UDP range, direct/NAT path, firewall owner and allowed change scope:
- Target system/chassis/UUID and trusted-access evidence:
- Expected GPU model, count, UUID/BDF set:
- Current workloads, stopped rentals, retained volumes and infrastructure dependencies:
- Authorized actions, approver, timestamp, scope, expiry and source:
- Data retention/backup decision; destructive disk serial/WWN allowlist if applicable:
- Excluded devices, services, hosts and data:
- Independent recovery route and tested access:

## Selected configuration

- OS/architecture, source ISO/signature/checksum if rebuilt:
- Kernel running / next boot; NVIDIA driver/module coverage:
- Storage topology/failure tolerance; member serials, XFS UUID/mount, ftype and quotas:
- Preferred disk-layout plan: per-disk roles/partitions, RAID or independent disks, usable capacity, reserves/spares and preserved contents:
- User's explicit layout selection/confirmation, timestamp, exact plan reference and approved target/scope:
- Docker data root/storage driver; fail-closed startup guard:
- Image-store backend; containerd instance/content/snapshot roots where applicable; all persistent paths, mounts/capacity, startup guards and backend-specific quota proof:
- Docker/containerd/runc/toolkit versions and package origins:
- Linux cgroup hierarchy / Docker cgroup driver / actual Vast GPU injection path:
- Docker daemon identity, rootful/rootless and user-namespace policy; socket/API access baseline:
- Intended workload UID/GID, capabilities, confinement, mounts and device allocation:
- Boot parameters relevant to cgroups/IOMMU/DRM:
- Fabric/NVLink/NCCL expectations where applicable:
- Fabric Manager applicability, installed/full upstream release versus loaded driver, companion components, initialization and boot verification:
- Final Docker workload: image digest, tool commit/CUDA/NCCL versions, nonzero UID/GID, exact GPU set, resource budgets, active duration/deadline, watchdog and owned-resource cleanup:
- Network/public address, exact TCP/UDP range, mapping and reflection path:
- Network configuration backup/change/readback; host/provider advertised-range comparison; external per-protocol expected/attempted/passed/failed/untested sets and probe source:
- Post-install/reboot container-publication path, nonce/mapping proof for allocatable ports, separate provider-reserved endpoint evidence and owned test-resource cleanup:
- Host-account identity reference, agreement status, machine ID; no credential values:
- Installer origin, capture time, reviewed/executed hashes, non-secret options:
- Downstream installer artifacts and automatic listing/VM/test behavior:
- Desired VM mode, observed mode and automatic-test prevention:
- Update/monitoring/alert policy and maintenance owner:

## Change ledger

| UTC | Target and exact action | Authorization reference | Previous state / backup | Result | Inverse / recovery |
|---|---|---|---|---|---|
| | | | | | |

For destructive operations, state explicitly that rollback is backup restoration, not undo. Before first write, attach the fresh identity/serial/consumer check. Record failed attempts rather than replacing them with later successful results.

## Acceptance

Use PASS / FAIL / HOLD / NOT TESTED / NOT APPLICABLE with reason and timestamped evidence.

| Gate | Status | Evidence / limit |
|---|---|---|
| Exact host identity and authorized scope | | |
| Workloads/data/dependencies resolved | | |
| Preferred disk layout explicitly confirmed; fresh inventory still matches | | |
| Recovery access and storage/driver preparation | | |
| Installer side effects controlled; registration verified | | |
| XFS quota accounting and enforcement; scratch limit | | |
| Correct mount on boot; missing/wrong-mount guard | | |
| Native GPU health, kernel coverage and fabric | | |
| Required Fabric Manager installed/version-matched; service and fabric healthy after reboot | | |
| Container compute and GPU isolation | | |
| Non-root workload stays non-root; daemon/tenant privilege boundaries preserved | | |
| CPU/memory effective cgroup limits | | |
| Same-container GPU survival after daemon-reload | | |
| Same-container live limit update where required | | |
| Multi-GPU peer/NCCL correctness where applicable | | |
| Sustained load/power/thermal/fault observations | | |
| Full-range external TCP/UDP and required reflection | | |
| User-specified range configured in firewall/NAT and Vast; advertisement matches after reboot | | |
| Actual reboot and fresh container acceptance | | |
| Final Docker compute/NCCL workload completed with all expected GPUs, correctness, bounded active load and clean exit | | |
| VM policy or separately requested VM qualification | | |
| Normal Vast self-test and its actual coverage | | |
| Owned test resources removed; provider state reconciled | | |
| Monitoring and final release/listing policy | | |

## Handoff

- Completed checkpoint / qualified profile:
- Current provider listing, rentals/volumes and VM state:
- Outstanding holds and untested behavior:
- Recovery completed / remaining changes and rollback references:
- Final automation/monitoring state:
- Next permitted action and anything requiring a new decision:
- Sanitized public summary location (if requested):
