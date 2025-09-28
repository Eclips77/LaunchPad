import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import ImageUpload from './ImageUpload';

// Mock the fetch function
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve({ url: '/media/uploads/test-image.jpg' }),
  })
);

// Mock URL.createObjectURL
window.URL.createObjectURL = jest.fn(() => 'blob:http://localhost/test-image.jpg');

describe('ImageUpload Component', () => {
  beforeEach(() => {
    fetch.mockClear();
    window.URL.createObjectURL.mockClear();
  });

  test('renders the component', () => {
    render(<ImageUpload />);
    expect(screen.getByText('Image Upload')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Upload' })).toBeInTheDocument();
  });

  test('allows a user to select a file and shows a preview', () => {
    render(<ImageUpload />);
    const fileInput = screen.getByLabelText(/image upload/i, { selector: 'input[type="file"]' });

    const file = new File(['(⌐□_□)'], 'chucknorris.png', { type: 'image/png' });

    fireEvent.change(fileInput, { target: { files: [file] } });

    expect(screen.getByAltText('Preview')).toBeInTheDocument();
    expect(window.URL.createObjectURL).toHaveBeenCalledWith(file);
  });

  test('uploads the file when the upload button is clicked', async () => {
    render(<ImageUpload />);
    const fileInput = screen.getByLabelText(/image upload/i, { selector: 'input[type="file"]' });
    const uploadButton = screen.getByRole('button', { name: 'Upload' });

    const file = new File(['(⌐□_□)'], 'chucknorris.png', { type: 'image/png' });
    fireEvent.change(fileInput, { target: { files: [file] } });

    fireEvent.click(uploadButton);

    expect(uploadButton).toBeDisabled();
    expect(screen.getByText('Uploading...')).toBeInTheDocument();

    await waitFor(() => {
      expect(fetch).toHaveBeenCalledTimes(1);
    });

    expect(fetch).toHaveBeenCalledWith('http://localhost:5001/api/v1/images', {
      method: 'POST',
      body: expect.any(FormData),
    });

    await waitFor(() => {
      expect(screen.getByText('Image uploaded successfully!')).toBeInTheDocument();
    });

    const uploadedLink = screen.getByRole('link', { name: /view uploaded image/i });
    expect(uploadedLink).toHaveAttribute('href', 'http://localhost:5001/media/uploads/test-image.jpg');
  });

  test('shows an error message if the upload fails', async () => {
    // Mock a failed fetch response
    fetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: false,
        json: () => Promise.resolve({ error: 'Upload failed' }),
      })
    );

    render(<ImageUpload />);
    const fileInput = screen.getByLabelText(/image upload/i, { selector: 'input[type="file"]' });
    const uploadButton = screen.getByRole('button', { name: 'Upload' });

    const file = new File(['(⌐□_□)'], 'chucknorris.png', { type: 'image/png' });
    fireEvent.change(fileInput, { target: { files: [file] } });

    fireEvent.click(uploadButton);

    await waitFor(() => {
      expect(screen.getByText('Upload failed')).toBeInTheDocument();
    });
  });
});