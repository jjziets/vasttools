# Preserve Docker and rental privilege boundaries

This runbook must not make an unprivileged rental root or grant tenants control of the host. Apply this constraint to installer code, runtime wrappers, diagnostics and proposed repairs, including recommendations copied from vendor troubleshooting pages.

## Distinguish identities

- **Host administrator:** may use scoped `sudo` for an authorized installation or inspection. This does not authorize changing a rental's identity or permissions.
- **Docker daemon:** may already be rootful in the supported Vast deployment. Record its actual mode and access policy; do not claim it is rootless. Do not convert a rootless daemon to rootful, remove user-namespace remapping or broaden daemon access to get a test working. An incompatible architecture is HOLD for a separate supported design.
- **Container process:** has its own configured/effective UID/GID and namespace mapping. UID 0 inside a container and privileged Docker mode are distinct, but neither is an acceptable substitute for a requested non-root workload. Preserve existing template semantics; do not rewrite all templates to root or to a different user globally.

Control of a rootful Docker daemon can confer host-level privileges. Treat its socket, remote API and membership in the host Docker administration group accordingly. [Docker Engine security](https://docs.docker.com/engine/security/)

## Prohibited installation shortcuts

Never use these to fix permission, GPU, cgroup or installer failures:

- Add `--privileged`, `--user root`, `--user 0`, `docker exec -u 0`, root Compose overrides or a Dockerfile `USER root` to an intended non-root workload.
- Add tenant users to the host `docker`/`sudo` groups, change a daemon to run as root, make its socket world-writable, expose an unauthenticated Docker API, or mount Docker/containerd sockets into a rental. A read-only socket bind mount does not make API access read-only.
- Mount the host root, broad `/dev`, host credentials, writable cgroup controls or host administrative directories into a rental. Do not use host PID/user/cgroup namespaces or `nsenter` as a workaround.
- Add broad capabilities such as `CAP_SYS_ADMIN`, unconfine seccomp/AppArmor, disable SELinux separation, remove `no-new-privileges` or change user-namespace policy to bypass a failure.
- Disable NVIDIA cgroup controls, expose unallocated GPUs or change global device permissions indiscriminately. Apply only the supported, narrowly scoped device/group assignment for the intended GPU allocation without changing the workload UID.

Existing provider-owned privileged infrastructure is not evidence that tenant workloads may inherit its access. Identify ownership and scope before changing any provider component. If a downloaded installer would introduce one of these tenant/daemon access regressions, stop before running it; the guide does not authorize accepting that shortcut.

## Verify before and after runtime changes

Record a minimal private baseline of the intended daemon identity/socket ownership, user-namespace policy, and effective tenant launch policy. Inspect only selected fields; full container/service output can contain secrets. Where Docker is not installed yet, record the approved intended baseline, then compare the installed state with it.

For an owned representative diagnostic container collect:

| Boundary | Evidence |
|---|---|
| Workload identity | Configured user plus effective UID/GID and supplementary groups, observed from its host PID; expected namespace mapping |
| Host privilege | `Privileged=false`; expected effective capabilities; no extra capabilities or host-namespace bypass |
| Confinement | Expected seccomp/AppArmor/SELinux and no-new-privileges state where supported; no weakening from baseline |
| Mounts and daemon access | Selected mount source/destination/mode and socket/API/group policy; no tenant-accessible administrative controls |
| Resources and devices | Effective limits; only assigned GPU UUIDs and required control devices; no access to another allocation |

Docker's empty `Config.User` is not proof of non-root execution. Resolve the image/template default and read back effective identity; account for any user-namespace mapping. Do not execute tenant-supplied binaries or enter tenant containers as root to collect this evidence. Use host-side metadata and owned test containers.

At least one commissioning test must deliberately use a known numeric **nonzero** UID/GID through the supported provider GPU path. Use an image that supports that user, prebuilt dependencies and a writable scratch directory owned by that identity. It must complete GPU enumeration and bounded CUDA correctness, retain its identity after the cgroup tests, and preserve the above boundaries. If it fails, diagnose the exact device-group, image, path or runtime permission; do not retry as root or privileged. Record any difference from the normal provider launch policy rather than calling a modified launch full provider acceptance.

Inspect runtime wrappers and launch policy as well as the diagnostic container: a safe scratch launch does not prove all rentals use that policy. Do not edit, restart or recreate existing rentals as a test. Keep unobserved template coverage explicit. Any unexpected privilege increase fails commissioning and stops further changes until the supported configuration is restored and reverified.
