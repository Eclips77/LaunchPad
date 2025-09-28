import os
import io
import pytest
from backend.app import app as flask_app

@pytest.fixture
def app():
    """Create and configure a new app instance for each test."""
    # Set up the app with test-specific configuration
    flask_app.config.update({
        "TESTING": True,
        "UPLOAD_FOLDER": "tests/uploads",
    })
    # Ensure the test upload folder exists
    os.makedirs(flask_app.config['UPLOAD_FOLDER'], exist_ok=True)
    yield flask_app

@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()

def test_upload_image_success(client):
    """Test successful image upload."""
    # Create a dummy 1x1 PNG file in memory
    # A valid 1x1 transparent PNG
    png_data = b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82'
    data = {
        'image': (io.BytesIO(png_data), 'test.png')
    }

    # Post the file to the endpoint
    response = client.post('/api/v1/images', content_type='multipart/form-data', data=data)

    # Assertions
    assert response.status_code == 201
    json_data = response.get_json()
    assert 'id' in json_data
    assert 'url' in json_data
    assert json_data['url'].startswith('/media/uploads/')

    # Check if file was created
    filepath = os.path.join(client.application.config['UPLOAD_FOLDER'], json_data['id'])
    assert os.path.exists(filepath)

    # Cleanup
    os.remove(filepath)

def test_upload_image_no_file_part(client):
    """Test upload request with no file part."""
    response = client.post('/api/v1/images', content_type='multipart/form-data', data={})
    assert response.status_code == 400
    json_data = response.get_json()
    assert 'error' in json_data
    assert 'No image part' in json_data['error']

def test_upload_image_no_selected_file(client):
    """Test upload request with no selected file."""
    data = {'image': (io.BytesIO(b""), '')}
    response = client.post('/api/v1/images', content_type='multipart/form-data', data=data)
    assert response.status_code == 400
    json_data = response.get_json()
    assert 'error' in json_data
    assert 'No image selected' in json_data['error']

def test_upload_image_invalid_extension(client):
    """Test upload with a file that has an invalid extension."""
    data = {
        'image': (io.BytesIO(b"this is a text file"), 'test.txt')
    }
    response = client.post('/api/v1/images', content_type='multipart/form-data', data=data)
    assert response.status_code == 400
    json_data = response.get_json()
    assert 'error' in json_data
    assert 'Allowed image types' in json_data['error']