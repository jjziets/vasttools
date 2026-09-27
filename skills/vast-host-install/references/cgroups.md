# Cgroups and NVIDIA runtime acceptance

Run this assessment for every container build. This procedure requires target-specific execution. Record it as NOT TESTED until executed on the target under the required conditions.

## Separate the three settings

| Setting | Examples | What it means |
|---|---|---|
| Linux cgroup hierarchy | v1, v2, hybrid | Kernel resource-control interface |
| Docker cgroup driver | systemd, cgroupfs | How Docker manages those controls |
| GPU injection | legacy NVIDIA hook, CDI, provider wrapper | How assigned GPUs enter the container |

Docker supports v2; switching its driver to `cgroupfs` does not switch the kernel to v1. A working modern host need not acquire the old `systemd.unified_cgroup_hierarchy=false` GRUB flag. Conversely, a host booting v2 is not proof that its complete GPU runtime path is reliable. [Docker cgroup documentation](https://docs.docker.com/engine/containers/runmetrics/)

## Read-only inventory

Cgroups normally already exist on these systems; the question is compatibility, not whether to install them. Do not change hierarchy or Docker driver merely because an older build needed a workaround. Record the current combination, preserve a passing configuration and report untested behavior honestly. Apply [privileges.md](privileges.md) throughout; the test must not turn an unprivileged workload into root.

Use explicit local Docker access; verify the daemon endpoint before collecting evidence. An inherited `DOCKER_HOST` or context can point to another machine. Avoid printing complete context objects containing private endpoints or credentials. The socket examples below apply to an already identified rootful daemon; for an existing rootless deployment, inspect its actual authorized endpoint and provider compatibility without converting it to rootful.

```bash
uname -r
stat -fc %T /sys/fs/cgroup
findmnt -t cgroup,cgroup2 -o TARGET,FSTYPE,OPTIONS
test ! -r /sys/fs/cgroup/cgroup.controllers || cat /sys/fs/cgroup/cgroup.controllers
docker -H unix:///var/run/docker.sock info --format '{{.CgroupVersion}} {{.CgroupDriver}} {{.Driver}} {{.DockerRootDir}}'
docker -H unix:///var/run/docker.sock version --format '{{.Server.Version}}'
containerd --version
runc --version
nvidia-ctk --version
nvidia-container-cli --version
nvidia-smi --query-gpu=uuid,driver_version --format=csv,noheader
```

Missing commands, permissions or format fields are unknowns to resolve, not successful checks. Confirm the local rootful socket is the intended Vast daemon. Detect hybrid layouts rather than guessing from one file. Examine only relevant boot parameters (`systemd.unified_cgroup_hierarchy`, `cgroup_no_v1`) and selected runtime settings (`mode`, `no-cgroups`, Docker `exec-opts`, default runtime and configured GPU runtime). Inspect the wrapper actually used by Vast; a generic `--gpus all` smoke test can bypass it.

Do not publish full daemon/runtime configs. Record effective settings and package versions without secrets. Compare running-kernel behavior with the next boot configuration.

## Why the historical problem matters

NVIDIA documents GPU-access loss when legacy injection is combined with container updates; on affected systemd configurations even `systemctl daemon-reload` can trigger it. The `cgroupfs` workaround addresses that reload trigger, but not explicit container updates. CDI is another documented mitigation. Compatibility must include the provider's actual launch path. [NVIDIA troubleshooting](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/troubleshooting.html)

Do not equate every NVML error with this defect. First distinguish host driver/library mismatch, missing GPU/binding, toolkit/CDI problems, allocation errors, and a container that loses working GPU access after an update.

## Bounded regression procedure

This is a maintenance test, not read-only discovery. Obtain or reuse authorization covering scratch containers, their resource allocation, a global daemon reload and any planned Docker restart/reboot. Verify the host is drained, unlisted if applicable, and retained data is protected. Disable only approved automatic work on this host during the test. `daemon-reload` can affect unrelated GPU containers even though it sounds harmless.

1. Save the effective runtime tuple, workload privilege baseline and safe workload inventory. Select a trusted image by digest, fixed allocation of GPU UUIDs, CPU/memory/PID/disk bounds and deadline. Use a unique run label and record exact created IDs. Include a deliberately non-root test with a known numeric nonzero UID/GID as specified in the privilege reference; do not rely on an image's implicit default user. Keep access unprivileged, without a host-root or Docker-socket mount.
2. Launch a long-lived scratch container through the same supported GPU assignment mechanism as Vast. Run `nvidia-smi` and a bounded CUDA correctness operation. Require exactly the assigned UUID set. Where there are multiple GPUs, also test a subset allocation and denied access to the others; do not merely compare GPU counts.
3. Read that scratch container's effective CPU/memory cgroup limits from the host, selecting its exact cgroup via its PID. For v2, compare `cpu.max`, `memory.max` and relevant cpuset effective files with the requested values; for v1 use the matching controller files. Never assume the container sees the host cgroup root. A Docker config readback alone is insufficient. Keep any bounded enforcement workload within the agreed scratch limits, never on a renter.
4. Record the scratch container ID/PID and successful GPU access. With the host still drained, run **one** `systemctl daemon-reload`. Retest GPU enumeration and CUDA correctness in the **same container without restarting it**. Recreating it would hide the regression.
5. If the intended provider/operations path changes limits on running containers, separately change CPU or memory limits on only that scratch container using the supported operation, preserving adequate working memory. Repeat GPU access and effective-limit checks in that same container. Record unsupported or untested transitions explicitly.
6. Restore any scratch limits changed in step 5; record the before/after results. Remove only the exact owned scratch resources. Then perform any approved runtime restart or host reboot and test a newly launched container through the same allocation path. Verify the selected cgroup driver/hierarchy and GPU inventory after boot.
7. Keep separate results for creation, effective resource limits, GPU isolation, reload survival, live-update survival where required, and post-reboot creation. Recheck workload UID/GID, capabilities, confinement and mounts; no test may silently acquire root or broader access. Record durations, image digest and versions; a single `nvidia-smi` success is not the complete result.

Stop after the first reproduced GPU-access failure. Preserve safe evidence and remove/recreate only owned diagnostic containers as needed for recovery; never repair a renter by deleting it. Observe the unchanged host inventory before proposing a fix.

## Choose a correction from evidence

- Keep a passing supported stack unchanged.
- For a reproduced reload defect, assess current supported driver/toolkit/runc fixes and CDI support in Vast's actual runtime path. Do not assume a local CDI demo proves provider compatibility.
- When the documented Docker `cgroupfs` mitigation is appropriate, replace any existing `native.cgroupdriver=...` entry with exactly one `native.cgroupdriver=cgroupfs` entry in `exec-opts`; retain unrelated entries and daemon settings. Validate daemon config with the installed Docker's supported validation interface, schedule its restart and recreate only owned tests. Repeat reload and update checks independently.
- Changing the Linux hierarchy is a separate boot change with a console recovery plan, exact boot-config backup, package/kernel compatibility check and post-reboot verification. Use it only for a demonstrated requirement, not an old recipe.
- Do not set `no-cgroups=true`, use `--privileged`, expose every GPU device, or disable isolation to make a test pass on a rootful rental host. Rootless recipes are not interchangeable with this deployment.

For a failed correction, restore the previous reviewed config and service state in the same maintenance window, then requalify the previous behavior. If the proposed fix changes the GPU/runtime path, repeat storage quotas, GPU isolation, resource limits and provider commissioning, not only the originally failing command.
