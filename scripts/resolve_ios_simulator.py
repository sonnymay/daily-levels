#!/usr/bin/env python3
"""Return a usable iPhone Simulator UDID for the active Xcode."""

from __future__ import annotations

import json
import subprocess
import sys
from typing import Any


DEFAULT_DEVICE_NAME = "iPhone 16"


def version_tuple(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def select_runtime(inventory: dict[str, Any], sdk_version: str) -> dict[str, Any]:
    sdk = version_tuple(sdk_version)
    runtimes = [
        runtime
        for runtime in inventory.get("runtimes", [])
        if runtime.get("platform") == "iOS"
        and runtime.get("isAvailable", True)
        and version_tuple(runtime["version"]) <= sdk
    ]
    if not runtimes:
        raise RuntimeError(f"No iOS Simulator runtime supports SDK {sdk_version}")

    return max(runtimes, key=lambda runtime: version_tuple(runtime["version"]))


def select_existing_device(
    inventory: dict[str, Any], runtime_id: str, preferred_name: str
) -> dict[str, Any] | None:
    device_types = {
        device_type["identifier"]: device_type
        for device_type in inventory.get("devicetypes", [])
    }
    devices = [
        device
        for device in inventory.get("devices", {}).get(runtime_id, [])
        if device.get("isAvailable", True)
        and device_types.get(device.get("deviceTypeIdentifier"), {}).get(
            "productFamily"
        )
        == "iPhone"
    ]
    return next(
        (device for device in devices if device.get("name") == preferred_name),
        devices[0] if devices else None,
    )


def select_device_type(
    inventory: dict[str, Any], runtime_version: str, preferred_name: str
) -> dict[str, Any]:
    runtime = version_tuple(runtime_version)
    device_types = [
        device_type
        for device_type in inventory.get("devicetypes", [])
        if device_type.get("productFamily") == "iPhone"
        and version_tuple(device_type.get("minRuntimeVersionString", "0"))
        <= runtime
        <= version_tuple(device_type.get("maxRuntimeVersionString", "65535.255.255"))
    ]
    if not device_types:
        raise RuntimeError(f"No iPhone device type supports iOS {runtime_version}")

    return next(
        (
            device_type
            for device_type in device_types
            if device_type.get("name") == preferred_name
        ),
        device_types[0],
    )


def command_output(*arguments: str) -> str:
    return subprocess.run(
        arguments,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def resolve_simulator(preferred_name: str) -> str:
    # Listing through simctl also initializes CoreSimulator on fresh hosted runners.
    inventory = json.loads(command_output("xcrun", "simctl", "list", "-j"))
    sdk_version = command_output(
        "xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"
    )
    runtime = select_runtime(inventory, sdk_version)
    existing = select_existing_device(inventory, runtime["identifier"], preferred_name)

    if existing:
        print(
            f"Using {existing['name']} on iOS {runtime['version']}",
            file=sys.stderr,
        )
        return existing["udid"]

    device_type = select_device_type(inventory, runtime["version"], preferred_name)
    simulator_name = f"Daily Levels CI ({runtime['version']})"
    udid = command_output(
        "xcrun",
        "simctl",
        "create",
        simulator_name,
        device_type["identifier"],
        runtime["identifier"],
    )
    print(
        f"Created {device_type['name']} on iOS {runtime['version']}",
        file=sys.stderr,
    )
    return udid


def main() -> None:
    preferred_name = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DEVICE_NAME
    print(resolve_simulator(preferred_name))


if __name__ == "__main__":
    main()
