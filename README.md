# Project Pilot (Web Version)

This project is a web-based application for managing projects, featuring a React single-page application (SPA) frontend and a Python (Flask) backend. This is a migration from the original Qt-based desktop application.

## Project Structure

The project is now organized into two main directories:

-   `frontend/`: Contains the React SPA.
-   `backend/`: Contains the Python Flask server and the original application logic.

## Getting Started

Follow the instructions below to set up and run the application on your local machine.

### Prerequisites

-   [Node.js](https://nodejs.org/) (v14 or newer)
-   [npm](https://www.npmjs.com/)
-   [Python](https://www.python.org/) (v3.8 or newer)
-   [pip](https://pip.pypa.io/en/stable/installation/)

### Backend Setup

1.  **Create and activate a virtual environment from the project root (recommended):**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
    *On Windows, use `venv\\Scripts\\activate`.*

2.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Run the Flask server:**
    ```bash
    python3 -m flask --app backend/app run --port=5001
    ```
    The backend API will be available at `http://localhost:5001`.

#### Image Upload Configuration

The backend uses a local directory to store uploaded images. You can configure this by setting the `MEDIA_ROOT` environment variable. If not set, it defaults to `media/uploads` in the project root.

```bash
export MEDIA_ROOT=/path/to/your/uploads/directory
```

### Frontend Setup

1.  **Navigate to the frontend directory:**
    ```bash
    cd frontend
    ```

2.  **Install JavaScript dependencies:**
    ```bash
    npm install
    ```

3.  **Run the React development server:**
    ```bash
    npm start
    ```
    The application will open in your browser at `http://localhost:3000`.

### Running Tests

#### Backend Tests

To run the backend tests, navigate to the project root and run `pytest`:

```bash
python3 -m pytest
```

#### Frontend Tests

The frontend tests are set up with Jest and React Testing Library. However, there is a known issue with the test environment in some sandbox environments that prevents the tests from running correctly.

To attempt to run the tests, navigate to the `frontend` directory and run:
```bash
npm test
```
If this fails, you can try using `npx`:
```bash
npx react-scripts test -- --watchAll=false
```
If you encounter JSX-related syntax errors, it is likely due to the test runner environment being unable to load the correct Babel configuration. This issue does not affect the application's runtime behavior.