import sys
import os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

# Add imports for our new classes
from src.core.project import ProjectManager
from src.gui.models import ProjectListModel

if __name__ == "__main__":
    # Set the QtQuick Controls style
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

    app = QGuiApplication(sys.argv)

    # --- Backend Data Loading ---
    # Define the path to the projects directory
    # Note: This assumes the script is run from the repository root
    projects_dir = "projects"

    # Instantiate the manager to find and load all projects
    project_manager = ProjectManager(projects_dir)
    projects = project_manager.get_all_projects()

    # --- Model Setup ---
    # Create the list model with the loaded projects
    project_model = ProjectListModel(projects)

    # --- QML Engine Setup ---
    engine = QQmlApplicationEngine()

    # Expose the Python model to QML as a context property
    engine.rootContext().setContextProperty("projectModel", project_model)

    # Construct the absolute path to the main QML file
    qml_file = os.path.join(os.path.dirname(__file__), "gui", "qml", "main.qml")

    # Load the QML file
    engine.load(os.path.abspath(qml_file))

    # Check if the QML file was loaded successfully
    if not engine.rootObjects():
        print("Error: Could not load QML file.")
        sys.exit(-1)

    # Execute the application's event loop
    sys.exit(app.exec())
