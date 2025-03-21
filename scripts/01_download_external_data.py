import os, gdown

# Dictionary mapping the desired output filenames to their Google Drive file IDs
files = {
    'data.tar.gz.md5': '1g7bUAdOj5HWos03_dWsH0Y2V9EHx54Qe',
    'data.tar.gz.part-00': '1GOy9yUS71UP3pYhV1KZORbxA7rPDxH3a',
    'data.tar.gz.part-01': '19vTasSHcX47qSh_VvUkfnr-UHEvfjyR6',
    'data.tar.gz.part-02': '1HeURlpWk1CcjqckE0g7Vp_G2-rBz-Dej',
    'data.tar.gz.part-03': '1lwx3yeeal3otHMGyEJEsl5qqvhXUw32q',
    'data.tar.gz.part-04': '1zp9-Tl4EyXFXbyUq7MAr7g5NdmpgMt8F',
    'data.tar.gz.part-05': '1dUTRxjKheNZ5OoSutvdxPJ8NkYbKohbc',
    'data.tar.gz.part-06': '1-wZPfReNAmKkY9ZWNrFmqb0pwQxvhN1w'
}

def download_if_missing(filename, file_id):
    if os.path.exists(filename):
        print(f"{filename} already exists. Skipping download.")
    else:
        url = f'https://drive.google.com/uc?export=download&id={file_id}'
        print(f"Downloading {filename}...")
        gdown.download(url, filename, quiet=False)

# Check and download files if not present
for filename, file_id in files.items():
    download_if_missing(filename, file_id)
