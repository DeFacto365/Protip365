#!/usr/bin/env bash
set -euo pipefail

echo "Starting FTP upload to protip365.com..."

# Required environment variables:
#   PROTIP365_FTP_HOST
#   PROTIP365_FTP_USERNAME
#   PROTIP365_FTP_PASSWORD
# Optional:
#   PROTIP365_FTP_REMOTE_DIR (defaults to /www)

for required_var in PROTIP365_FTP_HOST PROTIP365_FTP_USERNAME PROTIP365_FTP_PASSWORD; do
    if [[ -z "${!required_var:-}" ]]; then
        echo "Missing required environment variable: ${required_var}" >&2
        exit 1
    fi
done

# Using Python's built-in FTP library since macOS doesn't have ftp command by default.
python3 << 'EOF'
import ftplib
import os
import sys

host = os.environ["PROTIP365_FTP_HOST"]
username = os.environ["PROTIP365_FTP_USERNAME"]
password = os.environ["PROTIP365_FTP_PASSWORD"]
remote_dir = os.environ.get("PROTIP365_FTP_REMOTE_DIR", "/www")
base_dir = os.path.dirname(os.path.abspath(__file__))

# Files to upload
files = ["index.html", "privacy-policy.html", "terms-of-service.html"]

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
        filepath = os.path.join(base_dir, filename)
        if os.path.exists(filepath):
            with open(filepath, 'rb') as file:
                print(f"Uploading {filename}...")
                ftp.storbinary(f'STOR {filename}', file)
                print(f"{filename} uploaded successfully")
        else:
            print(f"{filename} not found", file=sys.stderr)
            raise FileNotFoundError(filepath)

    # Close connection
    ftp.quit()
    print("\nAll files uploaded successfully!")
    print("\nYour website is now live at:")
    print("- https://protip365.com")
    print("- https://protip365.com/privacy-policy.html")
    print("- https://protip365.com/terms-of-service.html")

except ftplib.error_perm as e:
    print(f"FTP Permission Error: {e}", file=sys.stderr)
    print("Please check your FTP credentials and permissions", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    print("Please check your connection and credentials", file=sys.stderr)
    sys.exit(1)
EOF
