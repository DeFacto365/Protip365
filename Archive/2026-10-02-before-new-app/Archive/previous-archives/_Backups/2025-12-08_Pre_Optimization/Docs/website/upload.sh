#!/bin/bash

echo "Starting FTP upload to protip365.com..."

# Using Python's built-in FTP library since macOS doesn't have ftp command by default
python3 << 'EOF'
import ftplib
import os

# FTP credentials
host = "ftp.zzw.muu.mybluehost.me"
username = "claude@protip365.com"
password = "Claude.7777!"
remote_dir = "/www"

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
        filepath = f"/Users/jacquesbolduc/Github/ProTip365/Docs/website/{filename}"
        if os.path.exists(filepath):
            with open(filepath, 'rb') as file:
                print(f"Uploading {filename}...")
                ftp.storbinary(f'STOR {filename}', file)
                print(f"✓ {filename} uploaded successfully")
        else:
            print(f"✗ {filename} not found")

    # Close connection
    ftp.quit()
    print("\n✅ All files uploaded successfully!")
    print("\nYour website is now live at:")
    print("- https://protip365.com")
    print("- https://protip365.com/privacy-policy.html")
    print("- https://protip365.com/terms-of-service.html")

except ftplib.error_perm as e:
    print(f"❌ FTP Permission Error: {e}")
    print("Please check your FTP credentials and permissions")
except Exception as e:
    print(f"❌ Error: {e}")
    print("Please check your connection and credentials")
EOF