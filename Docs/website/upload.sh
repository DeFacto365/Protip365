#!/bin/bash

echo "Starting FTP upload to protip365.com..."

: "${PROTIP365_FTP_HOST:?Set PROTIP365_FTP_HOST before running this script}"
: "${PROTIP365_FTP_USER:?Set PROTIP365_FTP_USER before running this script}"
: "${PROTIP365_FTP_PASSWORD:?Set PROTIP365_FTP_PASSWORD before running this script}"
: "${PROTIP365_FTP_REMOTE_DIR:=/www}"

# Using Python's built-in FTP library since macOS doesn't have ftp command by default
python3 << 'EOF'
import ftplib
import os
import sys

# FTP credentials are read from environment variables.
host = os.environ["PROTIP365_FTP_HOST"]
username = os.environ["PROTIP365_FTP_USER"]
password = os.environ["PROTIP365_FTP_PASSWORD"]
remote_dir = os.environ.get("PROTIP365_FTP_REMOTE_DIR", "/www")

# Files to upload
files = [
    "index.html",
    "privacy-policy.html",
    "terms-of-service.html",
    "privacy/index.html",
    "terms/index.html",
    "delete-account/index.html",
]

try:
    # Connect to FTP server
    print(f"Connecting to {host}...")
    ftp = ftplib.FTP(host)
    ftp.login(username, password)
    print("Connected successfully!")

    # Change to public_html directory
    ftp.cwd(remote_dir)
    print(f"Changed to directory: {remote_dir}")

    # Upload each file
    for filename in files:
        filepath = f"/Users/jacquesbolduc/Github/ProTip365/Docs/website/{filename}"
        if os.path.exists(filepath):
            dirname = os.path.dirname(filename)
            if dirname:
                for part in dirname.split("/"):
                    try:
                        ftp.mkd(part)
                    except ftplib.error_perm:
                        pass
                    ftp.cwd(part)
            with open(filepath, 'rb') as file:
                print(f"Uploading {filename}...")
                ftp.storbinary(f'STOR {os.path.basename(filename)}', file)
                print(f"✓ {filename} uploaded successfully")
            if dirname:
                ftp.cwd(remote_dir)
        else:
            print(f"✗ {filename} not found")

    # Close connection
    ftp.quit()
    print("\n✅ All files uploaded successfully!")
    print("\nYour website is now live at:")
    print("- https://protip365.com")
    print("- https://protip365.com/privacy")
    print("- https://protip365.com/privacy-policy.html")
    print("- https://protip365.com/terms")
    print("- https://protip365.com/terms-of-service.html")
    print("- https://protip365.com/delete-account")

except ftplib.error_perm as e:
    print(f"❌ FTP Permission Error: {e}")
    print("Please check your FTP credentials and permissions")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    print("Please check your connection and credentials")
    sys.exit(1)
EOF
