import React, { useState } from 'react';

function ImageUpload() {
    const [file, setFile] = useState(null);
    const [preview, setPreview] = useState(null);
    const [uploadedUrl, setUploadedUrl] = useState('');
    const [error, setError] = useState('');
    const [uploading, setUploading] = useState(false);

    const handleFileChange = (e) => {
        const selectedFile = e.target.files[0];
        if (selectedFile) {
            setFile(selectedFile);
            setPreview(URL.createObjectURL(selectedFile));
            setUploadedUrl('');
            setError('');
        }
    };

    const handleUpload = async () => {
        if (!file) {
            setError('Please select a file to upload.');
            return;
        }

        setUploading(true);
        setError('');

        const formData = new FormData();
        formData.append('image', file);

        try {
            const apiUrl = `${process.env.REACT_APP_API_URL}/images`;
            const response = await fetch(apiUrl, {
                method: 'POST',
                body: formData,
            });

            const data = await response.json();

            if (response.ok) {
                setUploadedUrl(data.url);
            } else {
                setError(data.error || 'Image upload failed.');
            }
        } catch (err) {
            setError('An error occurred during upload.');
            console.error('Upload error:', err);
        } finally {
            setUploading(false);
        }
    };

    return (
        <div>
            <h2 id="image-upload-heading">Image Upload</h2>
            <input aria-labelledby="image-upload-heading" type="file" accept="image/png, image/jpeg, image/gif" onChange={handleFileChange} />
            {preview && <img src={preview} alt="Preview" width="200" style={{ marginTop: '10px' }} />}
            <button onClick={handleUpload} disabled={uploading}>
                {uploading ? 'Uploading...' : 'Upload'}
            </button>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {uploadedUrl && (
                <div>
                    <p>Image uploaded successfully!</p>
                    <a href={`http://localhost:5001${uploadedUrl}`} target="_blank" rel="noopener noreferrer">
                        View Uploaded Image
                    </a>
                </div>
            )}
        </div>
    );
}

export default ImageUpload;