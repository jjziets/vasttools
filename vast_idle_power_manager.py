#!/usr/bin/env python3
"""
GPU Monitoring Script

Monitors running Docker containers for a specified image. If found, applies:
 - Power limits (if --powerlimit is specified), reverting to --default-power (or the card's default) when no container is using that GPU.
 - GPU clock locks (if -lgc/--lock-gpu-clock is specified).
 - Optionally resets or sets a new clock range on GPU inactivity if -rgc/--reset-gpu-clock is provided (with or without values).

Examples:
  # Basic usage: watch for "oguzpastirmaci/gpu-burn", set power=200W, revert to 450W, lock GPU clock to 300-1000MHz, reset clock on exit
  sudo python3 gpu_power_monitor.py \
      --image oguzpastirmaci/gpu-burn \
      --powerlimit 200 \
      --default-power 450 \
      -lgc 300,1000 \
      -rgc \
      -v

  # Only manage clock, no power limit:
  sudo python3 gpu_power_monitor.py \
      --image oguzpastirmaci/gpu-burn \
      -lgc 500,1500 \
      -rgc \
      -v

  # Manage clock differently on exit:
  sudo python3 gpu_power_monitor.py \
      --image oguzpastirmaci/gpu-burn \
      -lgc 300,500 \
      -rgc 0,2000 \
      -v

Run with --help (or -h) to see all options.
"""
import signal
import argparse
import logging
import time
import re
import subprocess
from collections import defaultdict
import sys

import docker

###############################################################################
# Argument Parsing
###############################################################################

def parse_args():
    parser = argparse.ArgumentParser(
        description="Monitor Docker containers for a given image and manage GPU power/clock settings."
    )

    parser.add_argument(
        "--image",
        type=str,
        default="oguzpastirmaci/gpu-burn",
        help="Docker image name (or substring) to watch. Default: oguzpastirmaci/gpu-burn",
    )
    parser.add_argument(
        "--powerlimit",
        type=int,
        default=None,
        help="Watts to set the GPU power limit when the container is running. (If omitted, power-limit not managed.)",
    )
    parser.add_argument(
        "--default-power",
        type=int,
        default=None,
        help="Watts to revert to when no container is using the GPU. "
             "If omitted, attempts to parse from nvidia-smi. "
             "If provided, we force this as the revert power limit. (e.g. 450)",
    )

    # Clock management options
    parser.add_argument(
        "-lgc", "--lock-gpu-clock",
        type=str,
        default=None,
        help="Lock GPU core clock to a MIN,MAX range (e.g. '300,1000'). "
             "If omitted, clocks are not locked upon container usage."
    )

    # -rgc can accept an optional argument:
    #   - If user provides no argument (just '-rgc'), we'll do a full reset: `nvidia-smi -rgc`
    #   - If user provides a range (e.g. '-rgc 0,2000'), we parse that and set it on GPU inactivity.
    parser.add_argument(
        "-rgc", "--reset-gpu-clock",
        nargs="?",
        const="RESET",
        default=None,
        help=(
            "Reset or set a new clock range upon GPU inactivity. "
            "If no value is provided, calls 'nvidia-smi -rgc'. "
            "If a range like '0,2000' is provided, sets that clock range on inactivity."
        ),
    )

    parser.add_argument(
        "-v", "--verbose",
        action="count",
        default=0,
        help="Increase verbosity (repeat for more verbose)."
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=5,
        help="Seconds between checks. Default: 5"
    )

    args = parser.parse_args()

    # Enforce that the user *must* specify at least one action:
    # Either a power-limit, or a clock-lock, or some reset-gpu-clock option.
    # This ensures "one pair is required."
    if (args.powerlimit is None) and (args.lock_gpu_clock is None) and (args.reset_gpu_clock is None):
        parser.error(
            "No action specified. Must specify at least one of --powerlimit, "
            "--lock-gpu-clock, or --reset-gpu-clock."
        )

    return args

###############################################################################
# Logging Setup
###############################################################################

def setup_logging(verbosity: int):
    """
    Map the verbosity count to a logging level.
      0 -> WARNING
      1 -> INFO
      2 -> DEBUG
      3+ -> still DEBUG
    """
    if verbosity == 0:
        level = logging.WARNING
    elif verbosity == 1:
        level = logging.INFO
    else:
        level = logging.DEBUG

    logging.basicConfig(
        format="%(asctime)s [%(levelname)s] %(message)s",
        level=level,
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logging.debug("Logging initialized at DEBUG level.")
    logging.info("Logging initialized.")

###############################################################################
# GPU Utilities
###############################################################################

def list_all_gpu_indices():
    """
    Return a list of all GPU indices on the system by parsing 'nvidia-smi -L'.
    e.g. ["0", "1", "2"] if 3 GPUs.
    """
    try:
        smi_output = subprocess.check_output(["nvidia-smi", "-L"]).decode("utf-8")
        lines = smi_output.strip().split("\n")
        indices = []
        for line in lines:
            match = re.match(r"GPU (\d+):", line)
            if match:
                indices.append(match.group(1))
        return indices
    except Exception as e:
        logging.error(f"Failed to list GPU indices: {e}")
        return []

def get_smi_default_power_limit(gpu_index):
    """
    Attempt to read the 'Default Power Limit' or 'Max Power Limit' via nvidia-smi for GPU index.
    Fallback to 'Enforced Power Limit' if needed.
    Returns a float in watts, or None if any failure/parsing error.
    """
    try:
        smi_output = subprocess.check_output(["nvidia-smi", "-q", "-i", str(gpu_index)]).decode("utf-8")
        match_def = re.search(r"Default Power Limit\s*:\s*([\d\.]+) W", smi_output)
        if match_def:
            return float(match_def.group(1))

        match_max = re.search(r"Max Power Limit\s*:\s*([\d\.]+) W", smi_output)
        if match_max:
            return float(match_max.group(1))

        match_enforced = re.search(r"Enforced Power Limit\s*:\s*([\d\.]+) W", smi_output)
        if match_enforced:
            return float(match_enforced.group(1))

        # If none matched
        logging.warning(f"Could not parse default power limit from nvidia-smi -q for GPU {gpu_index}.")
        return None

    except Exception as e:
        logging.warning(f"Failed to read default power limit for GPU {gpu_index}: {e}")
        return None

def set_power_limit(gpu_index, watts):
    """
    Set GPU power limit using nvidia-smi.
    """
    cmd = ["nvidia-smi", "-i", str(gpu_index), "-pl", str(watts)]
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.info(f"Set power limit of {watts}W on GPU {gpu_index}.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to set power limit on GPU {gpu_index}: {e}")

def lock_gpu_clock(gpu_index, min_clock, max_clock):
    """
    Lock GPU clock by running: nvidia-smi -i GPU_INDEX -lgc MIN_CLOCK,MAX_CLOCK
    """
    cmd = ["nvidia-smi", "-i", str(gpu_index), "-lgc", f"{min_clock},{max_clock}"]
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.info(f"Locked GPU {gpu_index} clock to {min_clock}-{max_clock} MHz.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to lock GPU {gpu_index} clock: {e}")

def reset_gpu_clock(gpu_index):
    """
    Reset GPU clock by running: nvidia-smi -i GPU_INDEX -rgc
    """
    cmd = ["nvidia-smi", "-i", str(gpu_index), "-rgc"]
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.info(f"Reset GPU {gpu_index} clock to default.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to reset GPU {gpu_index} clock: {e}")

def set_gpu_clock_range(gpu_index, min_clock, max_clock):
    """
    On GPU inactivity, if -rgc was given with a range, we set that range instead of fully resetting.
    """
    cmd = ["nvidia-smi", "-i", str(gpu_index), "-lgc", f"{min_clock},{max_clock}"]
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.info(f"Set GPU {gpu_index} clock to {min_clock}-{max_clock} MHz (on inactivity).")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to set GPU {gpu_index} clock on inactivity: {e}")

###############################################################################
# Docker / Container GPU Detection
###############################################################################

def get_gpus_for_container(container, skip_when_all=False):
    """
    Identify which GPU(s) the container is assigned to:
      1) If 'DeviceRequests' is set (typical docker run --gpus), parse it.
      2) Otherwise (Vast.ai scenario), fall back to environment variables:
         - NV_GPU="0,1"
         - or VAST_DEVICE_IDXS="0,1"

    skip_when_all=True means skip if it indicates "use all GPUs" rather than returning them.
    """
    dev_requests = container.attrs["HostConfig"].get("DeviceRequests")

    # 1) Check if we have a "normal" DeviceRequests structure
    if dev_requests:
        gpu_indices = []
        for req in dev_requests:
            caps = req.get("Capabilities", [])
            flat_caps = sum(caps, [])  # e.g. [["gpu"]] -> ["gpu"]
            if "gpu" in flat_caps:
                device_ids = req.get("DeviceIDs")
                if not device_ids or "-1" in device_ids:
                    # Means `--gpus all`
                    if skip_when_all:
                        logging.debug(f"Container {container.short_id}: '--gpus all' -> skipping.")
                        return []
                    else:
                        indices = list_all_gpu_indices()
                        logging.debug(f"Container {container.short_id}: '--gpus all' -> GPUs={indices}")
                        return indices
                else:
                    gpu_indices.extend(device_ids)

        logging.debug(f"Container {container.short_id} has GPU indices (DeviceRequests) = {gpu_indices}")
        return gpu_indices

    # 2) If we get here, DeviceRequests is null -> try environment fallback
    env_vars = container.attrs["Config"].get("Env", []) or []
    # e.g. look for "NV_GPU=0,1" or "VAST_DEVICE_IDXS=0,1"
    env_map = {}
    for kv in env_vars:
        # kv is like "NV_GPU=0,1"
        if '=' in kv:
            key, val = kv.split('=', 1)
            env_map[key] = val

    # Preferred fallback variables: "NV_GPU" or "VAST_DEVICE_IDXS"
    possible_vars = ["NV_GPU", "VAST_DEVICE_IDXS"]
    for var_name in possible_vars:
        if var_name in env_map:
            val = env_map[var_name].strip()
            # If it's blank or "all", interpret as all GPUs
            if not val or val.lower() == "all":
                if skip_when_all:
                    logging.debug(f"Container {container.short_id}: {var_name}=all -> skipping.")
                    return []
                else:
                    indices = list_all_gpu_indices()
                    logging.debug(f"Container {container.short_id}: {var_name}=all -> GPUs={indices}")
                    return indices

            # Typically something like "0,1"
            gpu_indices = [x.strip() for x in val.split(',') if x.strip()]
            logging.debug(f"Container {container.short_id} has GPU indices ({var_name}) = {gpu_indices}")
            return gpu_indices

    # 3) If none of the above worked, we have no idea which GPUs are used.
    logging.debug(f"Container {container.short_id} has GPU indices = [] (no DeviceRequests, no known env).")
    return []


def signal_handler(sig, frame):
    print("Caught Ctrl + C, exiting gracefully...")
    # Here you can do any cleanup work (e.g., revert all GPUs to defaults)
    sys.exit(0)

# Attach our signal handler
signal.signal(signal.SIGINT, signal_handler)


###############################################################################
# Main Loop
###############################################################################

def main():
    args = parse_args()
    setup_logging(args.verbose)

    image_substring = args.image
    check_interval = args.interval

    # Power-limit arguments
    target_power_watts = args.powerlimit
    user_default_power = args.default_power

    # Clock-lock arguments
    lock_clocks = args.lock_gpu_clock  # e.g. "300,1000"

    # -rgc / --reset-gpu-clock can be "RESET" (no arg), some range, or None
    reset_clock_value = args.reset_gpu_clock  # could be "RESET", "0,2000", or None

    ###########################################################################
    # Parse the user's clock range for immediate locking
    ###########################################################################
    clock_min = None
    clock_max = None
    if lock_clocks:
        try:
            parts = [x.strip() for x in lock_clocks.split(",")]
            if len(parts) == 2:
                clock_min, clock_max = parts
            elif len(parts) == 1:
                # In case user only gave one value
                clock_min = parts[0]
                clock_max = parts[0]
            else:
                raise ValueError("Invalid format for --lock-gpu-clock, expected 'min,max'.")
            logging.debug(f"Parsed lock clocks: min={clock_min}, max={clock_max}")
        except Exception as e:
            logging.error(f"Failed to parse --lock-gpu-clock='{lock_clocks}': {e}")
            exit(1)

    ###########################################################################
    # Parse the user's clock range for on-exit action (if provided with -rgc)
    ###########################################################################
    exit_clock_min = None
    exit_clock_max = None
    do_full_reset = False

    if reset_clock_value is not None:
        if reset_clock_value == "RESET":
            # user typed just '-rgc' => do full nvidia-smi -rgc
            do_full_reset = True
            logging.debug("User requested full GPU clock reset on inactivity.")
        else:
            # user typed '-rgc 0,2000' => parse that range
            try:
                parts = [x.strip() for x in reset_clock_value.split(",")]
                if len(parts) == 2:
                    exit_clock_min, exit_clock_max = parts
                elif len(parts) == 1:
                    exit_clock_min = parts[0]
                    exit_clock_max = parts[0]
                else:
                    raise ValueError("Invalid format for -rgc/--reset-gpu-clock, expected 'min,max'.")
                logging.debug(f"Parsed on-exit clock range: {exit_clock_min}, {exit_clock_max}")
            except Exception as e:
                logging.error(f"Failed to parse -rgc/--reset-gpu-clock='{reset_clock_value}': {e}")
                exit(1)

    # We'll store default power limit for each GPU so we can revert.
    gpu_default_limits = {}

    # Track which containers from our watched image are using each GPU
    gpu_usage_map = defaultdict(set)

    # Create Docker client
    client = docker.from_env()

    while True:
        try:
            # Build a new usage map
            new_gpu_usage_map = defaultdict(set)

            containers = client.containers.list(filters={"status": "running"})
            for container in containers:
                # Check if container image matches
                config_image = container.attrs["Config"].get("Image", "")
                image_tags = container.image.tags or []

                matched_by_config = (image_substring in config_image)
                matched_by_tags = any(image_substring in tag for tag in image_tags)
                if matched_by_config or matched_by_tags:
                    container_id = container.id
                    assigned_gpus = get_gpus_for_container(container, skip_when_all=False)
                    if assigned_gpus:
                        for gpu_idx in assigned_gpus:
                            new_gpu_usage_map[gpu_idx].add(container_id)

            ###################################################################
            # If a GPU just started being used, apply power limit / clock lock
            ###################################################################
            for gpu_idx, container_ids in new_gpu_usage_map.items():
                if len(container_ids) > 0:
                    old_container_ids = gpu_usage_map.get(gpu_idx, set())
                    if len(old_container_ids) == 0:
                        # GPU usage for this GPU is new
                        # 1) Possibly retrieve default power if not known
                        if target_power_watts is not None:
                            if gpu_idx not in gpu_default_limits:
                                if user_default_power is not None:
                                    gpu_default_limits[gpu_idx] = float(user_default_power)
                                    logging.debug(f"Using user-specified default power {user_default_power}W for GPU {gpu_idx}.")
                                else:
                                    lim = get_smi_default_power_limit(gpu_idx)
                                    if lim is not None:
                                        gpu_default_limits[gpu_idx] = lim
                                        logging.debug(f"Parsed default power limit for GPU {gpu_idx} = {lim}W.")
                                    else:
                                        logging.debug(f"No default power found for GPU {gpu_idx}.")

                            # Set the new power limit
                            set_power_limit(gpu_idx, target_power_watts)

                        # 2) Immediately lock GPU clocks if requested
                        if clock_min is not None and clock_max is not None:
                            lock_gpu_clock(gpu_idx, clock_min, clock_max)

            ###################################################################
            # If a GPU is no longer used by any watched container, revert
            ###################################################################
            for gpu_idx, old_container_ids in gpu_usage_map.items():
                if gpu_idx not in new_gpu_usage_map or len(new_gpu_usage_map[gpu_idx]) == 0:
                    # Means no usage now
                    # Revert power limit if we set it
                    if target_power_watts is not None:
                        # If we previously stored a default limit, revert
                        if gpu_idx in gpu_default_limits:
                            revert_lim = gpu_default_limits[gpu_idx]
                            set_power_limit(gpu_idx, revert_lim)
                        else:
                            logging.debug(f"No known default power for GPU {gpu_idx}; skipping revert.")

                    # Handle clock reset or exit clock range
                    if reset_clock_value is not None:
                        if do_full_reset:
                            # user typed just '-rgc'
                            reset_gpu_clock(gpu_idx)
                        else:
                            # user typed '-rgc 0,2000'
                            if exit_clock_min is not None and exit_clock_max is not None:
                                set_gpu_clock_range(gpu_idx, exit_clock_min, exit_clock_max)

            # Update usage map
            gpu_usage_map = new_gpu_usage_map

        except Exception as e:
            logging.error(f"Error in main loop: {e}", exc_info=True)

        time.sleep(check_interval)

###############################################################################
# Entry
###############################################################################

if __name__ == "__main__":
    main()
