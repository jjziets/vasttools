# Installation and commissioning

Use this procedure in order; reuse passing evidence only while its underlying state remains unchanged. Current authenticated Vast setup instructions govern the selected installer. These steps add local acceptance gates rather than promise compatibility with every future release.

## 1. Discover and prepare the change

Collect only necessary fields: OS/kernel/architecture, system/chassis identity, disk serials/WWNs and ancestry, mounts/swap/arrays/pools, GPU UUIDs/BDFs, NIC identities, network route, firmware, boot mode, recovery access, and workload inventory. Read logs through a secret-filtering boundary. Full `ps aux`, process argv, Docker inspect JSON, service environment, installer logs and provider JSON may expose credentials or tenant data; select safe fields.

Record which actions are already authorized and what remains undecided. For a reused host, provider state and local state must agree. Stopped rentals and retained volumes still matter. Coordinate automation that could relist the host or launch jobs during maintenance; scope any pause to this machine and record restoration policy.

Prove an independent console/recovery route. A target providing its own installer media, VPN, jump access or another host's boot media is a dependency to resolve before stopping it. Verify changed SSH host keys via a trusted console; do not disable host-key checking to continue.

## 2. OS and storage

Select a currently supported OS/architecture combination using Vast and hardware vendor guidance. Existing healthy installations can skip OS reinstall; an example release is not a requirement for every architecture.

### Confirm the preferred disk layout

Before partitioning, formatting, assembling a new array, migrating data or changing persistent storage mounts, show the user a concrete layout based on live disk inventory. In the private plan, map each disk by serial/WWN and capacity to its intended role, partition sizes, RAID/independent-disk arrangement, filesystem, mountpoint and preserved contents. Include boot redundancy, usable capacity, failure consequences, spare/free-space allocation and the Docker/containerd storage paths. Offer only alternatives supported by the actual inventory, with their capacity/resilience tradeoffs; keeping a suitable existing layout is a valid choice.

Ask the user to confirm their preferred layout and wait before those storage changes. Record their selection and the exact plan it approves. If an earlier explicit confirmation already covers the same target, inventory, layout and execution scope, reuse it without asking again. A generic installation request, permission to wipe disks or preference for maximum capacity is not confirmation of a specific layout. Never default to RAID0 or allocate every available disk without that confirmation.

Revalidate the selected disk identities before the first write. If the inventory or proposed layout changes, return the revised plan for confirmation; do not substitute disks or silently change RAID level, sizes or OS/data placement. Read-only discovery may continue while the choice is pending. Keep the completed plan and confirmation private.

For reinstall, verify the official ISO against its signed checksum manifest. Generate a host-specific layout matching exact disk serials, preserve excluded devices and validate autoinstall against the schema for that ISO. A YAML parse alone is insufficient. Immediately before the first destructive confirmation, recheck hardware identity and storage consumers from trusted live media. A changed or ambiguous mapping stops the write.

Choose the layout deliberately: dedicated OS disks plus a data tier, or a reviewed shared-disk layout. RAID0's capacity advantage includes complete array loss if a member fails; it is not a universal default. Record the selected failure tolerance, backup/retention decision, boot redundancy and available space.

Prepare real XFS storage for the selected Docker data root, normally `/var/lib/docker`, with `ftype=1` and project quota accounting **and enforcement**. Do not mount over existing Docker data without a reviewed migration. If the effective approved data root differs, substitute it throughout the following checks and startup dependencies; do not qualify an unused default directory. Verify:

```bash
findmnt --mountpoint /var/lib/docker -o TARGET,SOURCE,FSTYPE,OPTIONS,UUID
xfs_info /var/lib/docker
sudo xfs_quota -x -c 'state -p' /var/lib/docker
```

`findmnt --target` can return the root filesystem for a missing mount. Require the exact intended mountpoint and UUID; reject loopback fallback. Recognize both `pquota` and `prjquota`. Check array health and resolve every member to the approved disks.

Use UUID-based persistent mounting. Make Docker depend on the intended mount and validate its identity before daemon start. `RequiresMountsFor=/var/lib/docker` supplies ordering but alone does not prove the right filesystem is mounted. A host-specific root-owned `ExecStartPre` validator can compare UUID, type and quota state, failing startup on mismatch. Validate its negative behavior on an isolated fixture/test host before deployment; never unmount a rented host to test it. Do not rely solely on `nofail` or a directory-exists test.

Inventory the actual storage backend too: `DockerRootDir` alone is insufficient. Fresh Docker Engine 29+ installations default to a containerd image store, whose data path is separate from Docker's data root. Inspect the effective Docker driver/status and the containerd instance/configuration used by this daemon, including image content and snapshot roots. Record every persistent write path and its backing filesystem, capacity and startup dependency. Prevent fallback writes to an unintended root filesystem. [Docker image-store documentation](https://docs.docker.com/engine/storage/containerd/)

Require current Vast support and demonstrated per-container quota enforcement for the selected backend; XFS mount options alone do not prove a snapshotter enforces the intended limit. If this combination is unsupported or unknown, HOLD installation/qualification. Do not silently switch storage backends, migrate containerd data or downgrade Docker to pass a test. Storage migrations and version changes need a reviewed data-preserving plan; a backend switch can hide existing containers and invalidate an idle-state check. Removing user-namespace remapping or weakening privilege isolation to gain compatibility is prohibited, including as part of such a plan; hold an incompatible configuration instead.

Preserve an independent login while applying SSH changes; verify effective configuration and a second connection before closing recovery access. Record a controlled package-maintenance policy with an owner/window for security updates. Prevent unscheduled kernel/driver upgrades or reboots during rentals without silently abandoning security updates.

## 3. Driver and native GPU checks

Select a supported production driver for the actual GPU and kernel. Record package origins and exact versions. Avoid mixing runfile and distro installations. Verify the module for both the running kernel and the next default boot kernel, including DKMS or the applicable precompiled-module path and Secure Boot signing where enabled.

After a controlled reboot, require every expected GPU UUID, healthy storage and working access. Record temperatures, power limits, PCIe width/speed, ECC/recovery counters where supported, and new Xid/SXid/AER errors. Unsupported telemetry is NOT APPLICABLE with its reason, not zero. On NVSwitch systems verify compatible Fabric Manager, all expected links and the topology. A visible GPU alone does not establish a working fabric.

## 4. Network before registration

Allocate a continuous, non-overlapping TCP/UDP range meeting current Vast requirements and the intended GPU density. Use current provider guidance rather than copying an old twenty-port example. Verify the public address belongs to this host's service path; outbound NAT discovery alone is insufficient.

Prove same-number public-to-host port delivery across the advertised range. Use authorized external probes and bounded temporary listeners with per-port nonces; record sent/received sets for TCP and UDP. `open|filtered` is not UDP proof. Test private-IP, external-public-IP and host-to-own-public-IP paths separately; the latter checks reflection where the workflow needs it.

Never replace an occupied service to fit the test harness. Classify its owner, test that endpoint safely where possible and report any unproven port. Preserve management access when modifying firewall/NAT rules. Remove only this run's listeners. Repeat affected proofs after network changes and after commissioning reboot.

## 5. Review and run the Vast installer

Apply [privileges.md](privileges.md) to the installer and installed runtime policy. Separate authorized host administration from daemon permissions and tenant identity. Stop if installation would elevate an intended non-root rental, broaden tenant daemon/device access, or weaken isolation. Do not run a downloaded permission-fix script without checking those effects.

Confirm the intended host account and agreement status. Hosting and renting identities must follow Vast's current account rules. Obtain the fresh setup command only after prerequisites pass.

Download official installer bytes without executing them. Inspect argument parsing and the downstream actions: driver/storage replacement, Docker/toolkit installation, package holds, service starts, cron/timers, VM tests, automatic listing/self-tests, log destinations and failure uploads. Inspect code before using even `--help` if top-level execution is unclear. Privileged executable scripts fetched downstream must match reviewed hashes at execution or resolve to reviewed immutable artifacts with verified integrity. A mutable URL and a previously recorded hash are not enough. If the bootstrap cannot enforce this boundary, HOLD that execution path until a supported controlled path exists. Resolve approved repository packages through authenticated package metadata/signatures and record selected versions; do not conflate normal package resolution with executing arbitrary mutable shell/Python payloads. Separately record the installed updater policy and its trust/authorization boundary.

For already prepared driver/storage, use preservation options only if this exact installer supports them. Historical versions accepted `--no-driver`, `--no-partitioning` and a two-value `--ports`; these are evidence to check, not an unconditional current command. Avoid interactive buffered port prompts. Do not preinstall a competing Docker/runtime stack when the approved installer supplies it.

Some reviewed installers launched detached self-tests that could list machines. If that conflicts with the authorized outcome, hold execution until a supported opt-out or narrowly reviewed, owner-authorized adjustment exists. Review and hash any adjusted installer, preserve its diff privately, and verify there is no equivalent later launch. Never assume stopping the daemon immediately after install prevents registration or marketplace exposure. Resolve automatic VM testing too; a post-install `off` command cannot undo a test already launched.

Run in a controlled administrative session with restricted log permissions (`umask 077`), no shell tracing, no recording of secrets and no unattended upload of secret-bearing logs. A hidden input prompt prevents terminal echo but does not hide an argv credential from process/audit capture. If the installer requires argv secrets, evaluate that exposure before proceeding and use an operator-controlled secure session where necessary. Keep diagnostic logs private; sanitize copies for reporting. Do not delete system audit records to hide an exposure. Rotate/revoke affected credentials through the owner's credential workflow when needed.

On completion, reconcile installer exit status, new machine ID, services, controller heartbeat, provider listing state and background tasks. Verify exact port-range/address values from the installed files and provider advertisement. Do not overwrite an address from an unrelated outbound-IP probe. Inspect actual service names rather than assuming a unit from another build.

## 6. Container commissioning

First complete [cgroups.md](cgroups.md) using the actual Vast GPU allocation path. Test a trusted, digest-pinned image compatible with the driver, with bounded resource/time/disk limits and only the allocated GPUs. Record the digest and allocation method. Do not use privileged mode or unrestricted device access to conceal a failure.

Require:

- The privilege baseline is preserved. A deliberately non-root diagnostic workload completes CUDA correctness without root-user overrides, privileged mode or confinement bypass; the installed provider launch policy does not silently elevate it.
- Docker data root and every image/snapshot/volume storage path match their approved filesystems; a bounded scratch-container storage-limit test demonstrates enforcement with the actual backend and provider launch path.
- A scratch write exceeding its agreed small limit is rejected without consuming the whole filesystem; remove only that scratch container/data. Configure bytes/time bounds before starting it.
- Each intended GPU completes compute correctness, and selected-GPU containers cannot access unallocated GPUs. Compare UUIDs, not only counts.
- On multi-GPU hosts, required peer-copy and all-rank NCCL correctness pass with recorded topology, image and message sizes. Do not hide P2P defects with disabled transports and label that a full pass.
- Sustained load covers every advertised GPU for an agreed bounded duration, with power/cooling observations and no new faults. Record test duration and limits; a finite acceptance run is not a guarantee of long-term reliability.
- Disk/network results identify the exact target, test method and limits. Never use raw-device write benchmarks. Treat vendor speed-test helpers as potentially mutating maintenance tools until reviewed.

For VM requests follow [vms.md](vms.md); retain separate container and VM results.

## 7. Reboot, self-test and release

Perform the agreed unattended boot test while idle, with independent recovery access. Verify storage UUID/quota enforcement, every GPU UUID/binding, cgroup/runtime tuple, service dependencies, controller connection, networking and new diagnostic-container behavior after boot. Restarting a service is not a reboot test.

Run the current normal `vastai self-test machine MACHINE_ID` only after reviewing the installed CLI's behavior and authorizing any required temporary offer, rental/test instance, costs, capacity and duration. Configure credentials securely outside the transcript. If listing is required but not authorized, mark this gate HOLD; retain the completed local qualification. `--ignore-requirements` is diagnostic evidence only and cannot satisfy normal acceptance.

Inspect the test's actual coverage and independently verify its cleanup and final provider state. A successful default test may not scan every port and does not award a verification badge. Do not automatically destroy an unexpected instance; distinguish the owned test resource from a renter.

Release only the requested profile after its gates pass and the owner has authorized terms/availability. Read back the final listing state, GPU count, storage, ports and terms. For an unlisted handoff, confirm no delayed job or pricing automation can silently relist it. Eject installation media, clear temporary boot overrides, remove only owned helpers, restore agreed monitoring/automation and retain a sanitized outcome record.

## Recovery boundaries

Before each change, record exact backups, ownership and the inverse operation. Roll back only settings changed by this run; preserve concurrent changes. Storage formatting has no configuration rollback—recovery needs the approved backup/restore path. On SSH/network failure use the independent console; on GPU loss preserve evidence and check bindings before considering a scoped reboot. Do not broaden into firmware changes, blanket Docker prune, mass container deletion or automatic reinstall.
