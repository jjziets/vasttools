# Fabric setup and final Docker workload

Use the fabric branch when the identified hardware requires it. Run the final workload on **every** host, including ordinary PCIe GPU systems. These are execution requirements for an authorized commissioning window; do not claim a live pass from this document or from a service-status check.

## DGX/HGX and NVSwitch fabric setup

Identify the exact platform, GPU/NVSwitch generation and supported driver stack from hardware inventory and current NVIDIA/OEM guidance. A DGX/HGX name or SXM GPU alone does not establish the required services. Mark Fabric Manager NOT APPLICABLE with the hardware reason on non-NVSwitch systems; do not install it just because multiple GPUs are present.

Where required, **install Fabric Manager**, not merely check whether it exists. Select the package from the supported signed repository for the installed OS and driver. Require its full upstream NVIDIA release to match the loaded NVIDIA driver release, not merely the major branch; distinguish distro package suffixes from the NVIDIA version. Inspect the package transaction before executing it, preserve working configuration and record exact installed package/build versions. If a matching supported package is unavailable, HOLD rather than install a random latest version or silently change the driver. A driver change needs the existing driver/reboot acceptance sequence.

Use the platform's complete supported fabric stack. Newer NVSwitch platforms can require NVLSM and associated dependencies; follow that generation's package/service instructions and version compatibility matrix. Do not force every auxiliary component to have the driver's version string. [NVIDIA Fabric Manager guide](https://docs.nvidia.com/datacenter/tesla/fabric-manager-user-guide/index.html), [driver optional components](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/optional-components.html)

Enable and start the installed service through its supported unit, normally `nvidia-fabricmanager.service`, within the idle maintenance window. Verify any companion process/service through the actual package integration; NVLSM may be managed by the Fabric Manager unit rather than an independent unit. Do not rewrite service privileges or device permissions as a shortcut.

Require all of the following before compute tests:

- Installed Fabric Manager build and **loaded** GPU driver match; the next boot's driver module matches the intended package set too.
- Required service is active and configured to start at boot; required companion processes are healthy. Inspect selected sanitized logs for initialization/version errors, not only exit status.
- Expected GPU UUIDs, switches, NVLink topology and link states are present. Where exposed, GPU fabric registration has completed successfully. Use model-specific expectations; do not hardcode a switch/link count from another machine.
- CUDA initialization succeeds on every intended GPU. An active service with a pending/broken fabric fails this gate.

Repeat version, service and topology acceptance after the commissioning reboot and after any later driver/fabric change. Coordinate driver/Fabric Manager updates so a partial upgrade cannot silently leave mismatched releases. Never restart fabric services or reload drivers on an occupied host to satisfy this checklist.

## Final post-reboot Docker acceptance

Perform this after the final planned reboot and runtime/fabric changes, before release. Recheck occupancy and scope first. No renter or retained workload may be used as a test container. If the idle window or safe resource budget is unavailable, record HOLD and preserve completed work.

Default to a **five-minute active GPU workload with a ten-minute workload deadline**, excluding separately bounded image preparation. This is a bounded commissioning check; a 30+ minute burn-in is a separately selected profile. Record the chosen duration before launch and do not silently extend the window. A requested different duration takes precedence.

1. **Prepare reproducible tools.** Use a trusted digest-pinned image containing a compatible CUDA runtime, NCCL and a pinned build of NVIDIA `nccl-tests`. Prepare dependencies before the timed run; do not make the workload install packages or depend on mutable downloads. Record image digest, tool commit, CUDA/NCCL versions and build architecture. A base CUDA image does not necessarily contain NCCL tests.
2. **Prove Docker launch.** Verify the intended local daemon is running; start it only within the authorized install scope if necessary. Create a fresh, uniquely labeled diagnostic container through the supported Vast GPU allocation path, allocating exactly the expected GPU UUIDs. It must start, run real work and exit successfully. Use a known nonzero UID/GID and enforce [privileges.md](privileges.md): no root/privileged fallback, host Docker socket, host IPC or security-profile bypass. Configure finite CPU/RAM/PID/disk/shared-memory budgets; increase private shared memory within the agreed budget if needed, not host IPC. Do not remove vendor-default safety limits or alter clocks/power caps.
3. **Exercise compute on every GPU.** Run a repeated CUDA correctness workload, such as bounded matrix multiplication with known expected results, concurrently on all intended GPUs. Check outputs and actual work counters, not just `nvidia-smi` visibility. Size buffers conservatively from the available memory and agreed limits. Keep repeated compute active long enough to contribute meaningful load to the five-minute window; a sleep or idle container does not count.
4. **Run NCCL even on ordinary multi-GPU hosts.** In the same diagnostic environment, complete all-reduce with correctness enabled across every intended GPU in **one communicator**. Reject or unset inherited `NCCL_TESTS_SPLIT` and `NCCL_TESTS_SPLIT_MASK`; split groups can produce a false pass without cross-GPU traffic. A single-process/multiple-GPU `nccl-tests` build avoids requiring MPI/root allowances. The following is a workload argument example to run **inside the prepared non-root container**, after validating the binary and positive integer GPU count:

   ```bash
   unset NCCL_TESTS_SPLIT NCCL_TESTS_SPLIT_MASK
   ./build/all_reduce_perf -b 8 -e 128M -f 2 -g "$EXPECTED_GPU_COUNT" -w 5 -n 20 -c 1
   ```

   Here `-g` covers the allocated GPUs in the single-process test, `-c 1` requests correctness checks and the message sweep is bounded. Confirm these options against the pinned tool. Verify reported ranks/devices match the expected UUID allocation, require a single communicator/group containing exactly that GPU count, and inspect both in-place/out-of-place results. Record group membership as well as device mapping. Require completed sweeps, zero wrong results and exit zero. Repeat complete finite sweeps, interleaved with the compute workload if needed, until the active-work target is met; every repetition must pass. [NVIDIA nccl-tests](https://github.com/NVIDIA/nccl-tests)
5. **Handle a single GPU honestly.** Run the compute workload for the active-work target and a one-GPU NCCL initialization/correctness check where supported. Mark cross-GPU communication NOT APPLICABLE; a one-rank result cannot establish peer transport. Missing NCCL tooling is a preparation gap, not a substitute pass.
6. **Observe health and finish.** Sample every GPU's utilization, temperature, power and relevant error counters before/during/after the workload. Verify work completed on all GPUs, with no new Xid/SXid, uncorrectable memory errors, fabric failures or thermal slowdown. Keep hardware-specific limits in the private plan and stop on their violation. Capture workload exit status before removing its container; propagate errors through any logging pipeline. An elapsed deadline, killed process, zero-work run or partial sweep is FAIL, even if some output looked healthy.

Use an independent host-side watchdog tied to this run's exact container ID, with a bounded stop/kill/cleanup path. A timeout around `docker exec`, `docker wait` or an SSH connection does **not** guarantee the container workload stops. On failure or deadline, stop only the owned test container and verify its processes/GPU allocation are gone. Never use a global prune or kill all GPU processes. On success, remove only owned test resources and verify unchanged provider listing, workload inventory, GPU/fabric health and non-root launch policy.

Do not force `NCCL_P2P_DISABLE`, disable NVLink, hide GPUs or turn off correctness to obtain a pass. Inspect actual transport selection against this hardware's supported topology: ordinary GPUs need not have NVLink or peer access, while an advertised NVSwitch fabric must not be accepted on a fallback that conceals its failure. A bounded successful workload proves observed startup/compute/collective completion, not peak performance or long-term reliability.

Keep Docker lifecycle, per-GPU compute, NCCL ranks/correctness, duration, health, privilege preservation and cleanup as separate results. Any failed or untested required component blocks final container qualification. Repeat the affected final workload if driver, fabric, runtime, cgroup or relevant boot configuration changes afterward.
