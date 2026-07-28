import unittest

from AppStore import validate_metadata


class MetadataValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = validate_metadata.METADATA_PATH.read_text(encoding="utf-8")

    def test_checked_in_metadata_passes(self) -> None:
        self.assertEqual(validate_metadata.validate_document(self.document), [])

    def test_rejects_an_overlong_subtitle(self) -> None:
        document = self.document.replace(
            "Put your phone down. Level up.",
            "x" * 31,
            1,
        )

        errors = validate_metadata.validate_document(document)

        self.assertIn("English Subtitle is 31 characters; maximum is 30", errors)

    def test_rejects_keyword_spaces_and_duplicates(self) -> None:
        errors = validate_metadata.keyword_errors("English", "study,deep work,study")

        self.assertIn("English keywords must not contain spaces", errors)
        self.assertIn("English keywords contain a duplicate", errors)

    def test_requires_every_localized_listing(self) -> None:
        document = self.document.replace("(ja)", "(ja-disabled)", 1)

        errors = validate_metadata.validate_document(document)

        self.assertIn("missing localized listings: ja", errors)


if __name__ == "__main__":
    unittest.main()
