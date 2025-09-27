import os
import uuid
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename

# Configuration
UPLOAD_FOLDER = os.environ.get("MEDIA_ROOT", "media/uploads")
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MAX_CONTENT_LENGTH = 5 * 1024 * 1024  # 5 MB

app = Flask(__name__, static_folder='../frontend/build')
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# Enable CORS for the API endpoints
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Ensure the upload folder exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def allowed_file(filename):
    """Check if the file has an allowed extension."""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/api/v1/images', methods=['POST'])
def upload_image():
    """Handle image uploads."""
    if 'image' not in request.files:
        return jsonify({"error": "No image part in the request"}), 400
    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "No image selected for uploading"}), 400

    if file and allowed_file(file.filename):
        # Sanitize filename
        filename = secure_filename(file.filename)
        # Create a unique filename to prevent overwriting
        unique_filename = f"{uuid.uuid4().hex}_{filename}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)

        # Save the file
        file.save(filepath)

        # In a real application, you might want to get image dimensions
        # from PIL import Image
        # with Image.open(filepath) as img:
        #     width, height = img.size

        # For now, returning placeholder dimensions
        width, height = 0, 0

        # Create a URL for the uploaded file
        # Note: This requires a static file route to be set up
        file_url = f"/media/uploads/{unique_filename}"

        return jsonify({
            "id": unique_filename,
            "url": file_url,
            "width": width,
            "height": height
        }), 201
    else:
        return jsonify({"error": "Allowed image types are -> png, jpg, jpeg, gif"}), 400

# Route to serve uploaded files
@app.route('/media/uploads/<filename>')
def uploaded_file(filename):
    """Serve an uploaded file."""
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# Serve React App
@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve(path):
    """Serve the React application."""
    if path != "" and os.path.exists(os.path.join(app.static_folder, path)):
        return send_from_directory(app.static_folder, path)
    else:
        return send_from_directory(app.static_folder, 'index.html')

if __name__ == '__main__':
    app.run(debug=True, port=5001)