import unittest

from scripts import resolve_ios_simulator


class SimulatorSelectionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.inventory = {
            "runtimes": [
                {
                    "identifier": "ios-18-4",
                    "platform": "iOS",
                    "version": "18.4",
                    "isAvailable": True,
                },
                {
                    "identifier": "ios-18-5",
                    "platform": "iOS",
                    "version": "18.5",
                    "isAvailable": True,
                },
                {
                    "identifier": "ios-26-0",
                    "platform": "iOS",
                    "version": "26.0",
                    "isAvailable": True,
                },
            ],
            "devicetypes": [
                {
                    "identifier": "iphone-17",
                    "name": "iPhone 17",
                    "productFamily": "iPhone",
                    "minRuntimeVersionString": "26.0.0",
                },
                {
                    "identifier": "iphone-16",
                    "name": "iPhone 16",
                    "productFamily": "iPhone",
                    "minRuntimeVersionString": "18.0.0",
                },
                {
                    "identifier": "ipad",
                    "name": "iPad",
                    "productFamily": "iPad",
                    "minRuntimeVersionString": "18.0.0",
                },
            ],
            "devices": {
                "ios-18-5": [
                    {
                        "udid": "IPAD-ID",
                        "name": "iPad",
                        "deviceTypeIdentifier": "ipad",
                        "isAvailable": True,
                    },
                    {
                        "udid": "FALLBACK-ID",
                        "name": "iPhone 16 Pro",
                        "deviceTypeIdentifier": "iphone-16",
                        "isAvailable": True,
                    },
                    {
                        "udid": "PREFERRED-ID",
                        "name": "iPhone 16",
                        "deviceTypeIdentifier": "iphone-16",
                        "isAvailable": True,
                    },
                ]
            },
        }

    def test_selects_latest_runtime_supported_by_active_sdk(self) -> None:
        runtime = resolve_ios_simulator.select_runtime(self.inventory, "18.5")

        self.assertEqual(runtime["identifier"], "ios-18-5")

    def test_ignores_runtime_newer_than_active_sdk(self) -> None:
        runtime = resolve_ios_simulator.select_runtime(self.inventory, "18.6")

        self.assertEqual(runtime["identifier"], "ios-18-5")

    def test_prefers_requested_existing_iphone(self) -> None:
        device = resolve_ios_simulator.select_existing_device(
            self.inventory, "ios-18-5", "iPhone 16"
        )

        self.assertEqual(device["udid"], "PREFERRED-ID")

    def test_falls_back_to_an_available_iphone(self) -> None:
        device = resolve_ios_simulator.select_existing_device(
            self.inventory, "ios-18-5", "iPhone 15"
        )

        self.assertEqual(device["udid"], "FALLBACK-ID")

    def test_selects_device_type_compatible_with_runtime(self) -> None:
        device_type = resolve_ios_simulator.select_device_type(
            self.inventory, "18.5", "iPhone 17"
        )

        self.assertEqual(device_type["identifier"], "iphone-16")


if __name__ == "__main__":
    unittest.main()
