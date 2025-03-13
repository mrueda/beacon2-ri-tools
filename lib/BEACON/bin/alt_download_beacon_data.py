import requests, os, hashlib
from tqdm import tqdm

def download_file(url, output_filename, chunk_size=8192):
    current_size = os.path.getsize(output_filename) if os.path.exists(output_filename) else 0
    headers = {'Range': f'bytes={current_size}-'} if current_size else {}
    r = requests.get(url, stream=True, headers=headers)
    r.raise_for_status()
    total = int(r.headers.get('Content-Length', 0)) + current_size if r.headers.get('Content-Length') else None
    mode = 'ab' if current_size else 'wb'
    with open(output_filename, mode) as f, tqdm(total=total, initial=current_size,
                                                unit='B', unit_scale=True, desc=output_filename) as pbar:
        for chunk in r.iter_content(chunk_size=chunk_size):
            if chunk:
                f.write(chunk)
                pbar.update(len(chunk))

# Mapping file names to their OneDrive/SharePoint download URLs.
files = {
    "beacon_data.part1": "https://ccnag-my.sharepoint.com/:u:/g/personal/manuel_rueda_cnag_eu/Ed1kDJleiWxEl_07C7BOexoB6Yh-Zcl_8NPM_pw7Cl0Mcw?e=EvgRQB&download=1",
    "beacon_data.part2": "https://ccnag-my.sharepoint.com/:u:/g/personal/manuel_rueda_cnag_eu/EdfKD_teMU9HsOQTDyPhGhYBY4ez0fiPYPrsxuqXHcFnFg?e=sLasmT&download=1",
    "beacon_data.part3": "https://ccnag-my.sharepoint.com/:u:/g/personal/manuel_rueda_cnag_eu/ERvK95sukGNOqH_uvs5aOPoBJlzzE8ENQotM93Ju7Sn2lQ?e=yWYnmt?download=1",
    "beacon_data.part4": "https://ccnag-my.sharepoint.com/:u:/g/personal/manuel_rueda_cnag_eu/EUdVtVTqDCpKtf4o9FheLM8BYnK5MHFOJyLadHdbcGe9rQ?e=adbkUa?download=1",
    "beacon_data.part5": "https://ccnag-my.sharepoint.com/:u:/g/personal/manuel_rueda_cnag_eu/Eb3G8wq-JiBCiQmAK-u2fVsB4B7wVD6QvWWp3RqTIfLcVw?e=FPlTkg?download=1"
}

# Hardcoded expected MD5 checksums.
expected_md5 = {
    "beacon_data.part1": "997ea6cf793941d6e045fba68a152403",
    "beacon_data.part2": "ede28f2f203297b96946bbea76efc7dc",
    "beacon_data.part3": "822cb234ab787ed65c12d8455947686c",
    "beacon_data.part4": "d245c9069fdc861105f051d791ad7d3a",
    "beacon_data.part5": "cf13676fbd6700d00747aa43a6560551"
}

# Download each file in turn.
for filename, url in files.items():
    print(f"Downloading {filename}...")
    download_file(url, filename)
    print(f"Finished downloading {filename}\n")

# Function to compute MD5 checksum.
def md5sum(filename, chunk_size=8192):
    m = hashlib.md5()
    with open(filename, 'rb') as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            m.update(chunk)
    return m.hexdigest()

# Verify downloaded parts.
print("Verifying MD5 checksums:")
for filename, expected in expected_md5.items():
    calc = md5sum(filename)
    if calc == expected:
        print(f"{filename}: OK")
    else:
        print(f"{filename}: MISMATCH (expected {expected}, got {calc})")
