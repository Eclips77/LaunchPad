import sys
import os

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from core.database import ProjectDatabase
from gui import ProjectListModel

if __name__ == "__main__":
    # Set the QtQuick Controls style
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

    app = QGuiApplication(sys.argv)

    database = ProjectDatabase()
    model = ProjectListModel(database)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("projectModel", model)

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
