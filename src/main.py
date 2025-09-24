import os
import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from core.launcher import LaunchService
from core.database import ProjectDatabase
from gui.project_store import ProjectStore

if __name__ == "__main__":
    # Set the QtQuick Controls style
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

    app = QGuiApplication(sys.argv)

    # Create single database instance
    database = ProjectDatabase()
    
    engine = QQmlApplicationEngine()
    context = engine.rootContext()
    
    # Create services
    launch_service = LaunchService()
    project_store = ProjectStore(database=database)
    
    # Set context properties
    context.setContextProperty("projectLauncher", launch_service)
    context.setContextProperty("projectStore", project_store)
    context.setContextProperty("projectModel", project_store.projectsModel)

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
