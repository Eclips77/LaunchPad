import unittest
from src.core.project import Project

class TestProject(unittest.TestCase):

    def test_to_overview_with_comma_in_tag(self):
        """
        Tests that to_overview returns a list of tags, not a string.
        This test will initially fail, proving the bug.
        """
        # A project with a tag that contains a comma
        project = Project(
            key="test-project",
            name="Test Project",
            tags=["database, sql", "web"],
        )

        overview = project.to_overview()

        # The bug is that `overview["tags"]` is a string: "database, sql, web"
        # The fix will make it a list: ["database, sql", "web"]
        self.assertIsInstance(overview["tags"], list, "tags should be a list")
        self.assertEqual(
            overview["tags"],
            ["database, sql", "web"],
            "Tags should be correctly preserved in the overview",
        )

if __name__ == '__main__':
    unittest.main()
