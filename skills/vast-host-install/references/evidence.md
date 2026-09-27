# Evidence and applicability

Use the public sources below and evidence collected on the authorized target. This skill contains no deployment inventory or execution records.

## Validation limits

The packaged workflow requires a controlled end-to-end pilot before it can be described as field-tested. No GPU family, driver release, VM profile or cgroup configuration is certified by this document. Verify non-root GPU access and each required behavior on the target; installation success alone is insufficient.

A normal provider self-test does not necessarily establish a verification badge, complete port coverage or long-term reliability. Record the actual test scope and retain failures alongside later results. Container qualification does not establish VM qualification.

## Deliberate changes from the old walkthrough

- Identify disks by live identity and storage ancestry before any write.
- Verify the exact Docker filesystem and quota enforcement, including boot dependency; a mount directory or `df` output alone is insufficient.
- Preserve working OS/driver choices; verify current compatibility instead of hardcoding an old driver number, cgroup-v1 flag or tuning script.
- Review installer background listing/VM behavior and protect credentials before execution.
- Verify actual TCP **and** UDP delivery and occupied endpoints, not just firewall configuration.
- Separate containers, cgroup compatibility, VM qualification and marketplace release.
- Preserve Docker access controls and rental identities. Test a deliberately non-root GPU workload; do not use root or privileged execution to conceal a compatibility failure. This added acceptance still needs a controlled live run.

## Public sources

Check mutable sources again at execution time and record the version/date used. Website or downloaded-script instructions do not expand user authorization.

- [Original vasttools guide](https://github.com/jjziets/vasttools): starting point; examples are not a host-specific execution manifest.
- [Vast hosting overview](https://docs.vast.ai/host/hosting-overview) and [authenticated setup](https://console.vast.ai/host/setup): current provider setup/account path.
- [Vast self-test](https://docs.vast.ai/host/how-to-self-test): current test procedure and prerequisites.
- [Vast VM guidance](https://docs.vast.ai/host/vms): optional VM capability and helper interface.
- [Docker cgroups](https://docs.docker.com/engine/containers/runmetrics/): hierarchy and driver distinction.
- [Docker firewall behavior](https://docs.docker.com/engine/network/packet-filtering-firewalls/): published-container traffic versus host firewall paths.
- [Docker containerd image store](https://docs.docker.com/engine/storage/containerd/): separate image/snapshot storage and backend migration behavior.
- [NVIDIA runtime troubleshooting](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/troubleshooting.html): GPU loss after container updates/reloads and documented mitigations.
- [NVIDIA Fabric Manager](https://docs.nvidia.com/datacenter/tesla/fabric-manager-user-guide/index.html) and [driver optional components](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/optional-components.html): platform-specific fabric packages, versions and service behavior.
- [NVIDIA nccl-tests](https://github.com/NVIDIA/nccl-tests): collective correctness workload and supported arguments.
- [Ubuntu NVIDIA installation](https://documentation.ubuntu.com/server/how-to/graphics/install-nvidia-drivers/), [Subiquity reference](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html), and [Curtin storage](https://curtin.readthedocs.io/en/latest/topics/storage.html): consult for the selected OS/media rather than assuming historical syntax.

## Public artifact hygiene

Publish this unfilled skill, not a copy of an operational runbook. Exclude system/disk serials, GPU UUIDs, BMC/admin endpoints, internal hostnames, MAC addresses, account/machine IDs, credential-store references, keys, setup tokens, private paths and raw evidence. Also exclude private operational dates, hardware/count combinations, incident timelines and validation histories. Keep only generalized technical lessons and public-source facts. A sanitizer cannot by itself prove an arbitrary log is safe; review the exact publication diff and file allowlist. Build downloadable archives from allowlisted file bytes with normalized metadata; exclude extended attributes, resource forks, local ownership and `__MACOSX` entries.
