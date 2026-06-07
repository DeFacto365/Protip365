#!/bin/bash

echo "Starting secure upload to protip365.com..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

: "${PROTIP365_FTP_HOST:?Set PROTIP365_FTP_HOST before running this script}"
: "${PROTIP365_FTP_USER:?Set PROTIP365_FTP_USER before running this script}"
: "${PROTIP365_FTP_REMOTE_DIR:=/www}"
: "${PROTIP365_UPLOAD_PROTOCOL:=sftp}"

case "$PROTIP365_UPLOAD_PROTOCOL" in
  sftp)
    : "${PROTIP365_SFTP_PORT:=22}"
    ;;
  ftps)
    : "${PROTIP365_FTP_PASSWORD:?Set PROTIP365_FTP_PASSWORD before running FTPS upload}"
    : "${PROTIP365_FTPS_PORT:?Set PROTIP365_FTPS_PORT to the FTPS port shown in Bluehost/cPanel}"
    ;;
  *)
    echo "Plain FTP is disabled. Set PROTIP365_UPLOAD_PROTOCOL to sftp or ftps."
    exit 1
    ;;
esac

if [ "$PROTIP365_UPLOAD_PROTOCOL" = "sftp" ]; then
  command -v sftp >/dev/null 2>&1 || {
    echo "sftp command not found"
    exit 1
  }

  batch_file="$(mktemp)"
  trap 'rm -f "$batch_file"' EXIT

  cat > "$batch_file" <<EOF
cd $PROTIP365_FTP_REMOTE_DIR
put index.html
put privacy-policy.html
put terms-of-service.html
-mkdir privacy
cd privacy
put privacy/index.html index.html
cd ..
-mkdir terms
cd terms
put terms/index.html index.html
cd ..
-mkdir support
cd support
put support/index.html index.html
cd ..
-mkdir delete-account
cd delete-account
put delete-account/index.html index.html
EOF

  sftp -b "$batch_file" -P "$PROTIP365_SFTP_PORT" "$PROTIP365_FTP_USER@$PROTIP365_FTP_HOST"
  echo "Secure SFTP upload complete."
  exit 0
fi

python3 << 'EOF'
import ftplib
import os
import sys

host = os.environ["PROTIP365_FTP_HOST"]
username = os.environ["PROTIP365_FTP_USER"]
password = os.environ["PROTIP365_FTP_PASSWORD"]
remote_dir = os.environ.get("PROTIP365_FTP_REMOTE_DIR", "/www")
port = int(os.environ["PROTIP365_FTPS_PORT"])

# Files to upload
files = [
    "index.html",
    "privacy-policy.html",
    "terms-of-service.html",
    "privacy/index.html",
    "terms/index.html",
    "support/index.html",
    "delete-account/index.html",
]

try:
    print(f"Connecting securely to {host} with FTPS...")
    ftp = ftplib.FTP_TLS()
    ftp.connect(host, port)
    ftp.login(username, password)
    ftp.prot_p()
    print("Connected securely!")

    # Change to public_html directory
    ftp.cwd(remote_dir)
    print(f"Changed to directory: {remote_dir}")

    # Upload each file
    for filename in files:
        filepath = os.path.join(os.getcwd(), filename)
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
    print("- https://protip365.com/support")
    print("- https://protip365.com/delete-account")

except ftplib.error_perm as e:
    print(f"❌ FTPS Permission Error: {e}")
    print("Please check your credentials and permissions")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    print("Please check your connection and credentials")
    sys.exit(1)
EOF
