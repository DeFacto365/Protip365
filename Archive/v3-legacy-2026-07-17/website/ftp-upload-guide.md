# Secure Upload Guide for ProTip365 Website

## Secure Transfer Credentials

Do not store transfer credentials in this repository. Use the current credentials from Bluehost/cPanel and rotate any credential that was previously committed.

- **Protocol:** SFTP preferred, or FTPS if SFTP is unavailable
- **Host:** Use the current Bluehost secure transfer host
- **Username:** Use the current Bluehost transfer user
- **Password:** Use the password from your password manager
- **Port:** Use the SFTP/FTPS port shown in Bluehost/cPanel
- **Directory:** Confirm in Bluehost/cPanel before upload

## Using a Secure Transfer Client (Recommended: FileZilla, Cyberduck, or Transmit)

### Step 1: Download a Transfer Client
- **FileZilla** (Free): https://filezilla-project.org
- **Cyberduck** (Free): https://cyberduck.io
- **Transmit** (Mac, Paid): https://panic.com/transmit

### Step 2: Connect to Your Server
1. Open your transfer client
2. Enter the connection details:
   - Protocol: SFTP or FTPS
   - Host: current Bluehost secure transfer host
   - Username: current Bluehost transfer user
   - Password: current password
   - Port: the SFTP/FTPS port shown in Bluehost/cPanel
3. Click Connect

### Step 3: Navigate to the Correct Directory
1. In the remote server panel, navigate to the domain's public web root.

### Step 4: Upload the Files
1. In the local panel, navigate to: `/Users/jacquesbolduc/Github/ProTip365/Docs/website/`
2. Select these files:
   - `index.html`
   - `privacy-policy.html`
   - `terms-of-service.html`
   - `privacy/index.html`
   - `terms/index.html`
   - `delete-account/index.html`
3. Drag them to the remote server panel (public_html folder)

## Using macOS Terminal (Alternative)

```bash
# Navigate to the website folder
cd /Users/jacquesbolduc/Github/ProTip365/Docs/website/

# Upload all HTML files using SFTP
sftp -P YOUR_SFTP_PORT YOUR_USER@YOUR_HOST
# Enter password or use your SSH key, then run:
cd /path/to/public_html
put index.html
put privacy-policy.html
put terms-of-service.html
mkdir privacy
put privacy/index.html privacy/index.html
mkdir terms
put terms/index.html terms/index.html
mkdir support
put support/index.html support/index.html
mkdir delete-account
put delete-account/index.html delete-account/index.html
quit
```

## Using Finder (Mac) - Connect to Server

1. Open Finder
2. Press Cmd+K (Go > Connect to Server)
3. Enter your current SFTP or FTPS server URL from Bluehost/cPanel
4. Enter your password
5. Navigate to public_html folder
6. Drag and drop the HTML files

## After Upload - Verify

Check these URLs:
- https://protip365.com (Landing page)
- https://protip365.com/privacy
- https://protip365.com/privacy-policy.html
- https://protip365.com/terms
- https://protip365.com/terms-of-service.html
- https://protip365.com/delete-account

## Important Notes

1. Make sure files go in the `public_html` directory
2. The domain protip365.com must be pointing to this server
3. Files should be accessible immediately after upload
4. If you see the Bluehost default page, you may need to delete or rename any existing `index.html` or `index.php` files in public_html
5. Do not use plain FTP. It sends credentials without the required transport protection.

## Troubleshooting

- **Can't connect:** Check firewall settings, try IP address instead of domain
- **Permission denied:** Make sure you're using the correct password
- **Files not showing:** Clear browser cache, check file permissions (should be 644)
- **Domain not working:** DNS may need time to propagate if recently configured
