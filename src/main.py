import os
import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from core.launcher import LaunchService
from core.database import ProjectDatabase
from gui.project_store import ProjectStore
from gui import ProjectListModel

if __name__ == "__main__":
    # Set the QtQuick Controls style
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

    app = QGuiApplication(sys.argv)

    database = ProjectDatabase()
    model = ProjectListModel(database)

    engine = QQmlApplicationEngine()
    context = engine.rootContext()
    launch_service = LaunchService()
    context.setContextProperty("projectLauncher", launch_service)
    engine.rootContext().setContextProperty("projectModel", model)

    database = ProjectDatabase()
    project_store = ProjectStore(database=database)
    engine.rootContext().setContextProperty("projectStore", project_store)

    # Construct the absolute path to the main QML file
    qml_file = os.path.join(os.path.dirname(__file__), "gui", "qml", "main.qml")

    # Load the QML file
    engine.load(os.path.abspath(qml_file))

    # Check if the QML file was loaded successfully
    if not engine.rootObjects():
        print("Error: Could not load QML file.")
        sys.exit(-1)

    # Close the database connection when the app exits
    app.aboutToQuit.connect(database.close)

    # Execute the application's event loop
    sys.exit(app.exec())
