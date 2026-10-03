# FTP Upload Guide for ProTip365 Website

## Your FTP Credentials
- **FTP Host:** zzw.muu.mybluehost.me (or 50.6.153.246)
- **FTP Username:** claude@protip365.com
- **FTP Password:** [Use the password you set]
- **Port:** 21 (standard FTP)
- **Directory:** /home2/zzwmuumy/public_html

## Using an FTP Client (Recommended: FileZilla, Cyberduck, or Transmit)

### Step 1: Download an FTP Client
- **FileZilla** (Free): https://filezilla-project.org
- **Cyberduck** (Free): https://cyberduck.io
- **Transmit** (Mac, Paid): https://panic.com/transmit

### Step 2: Connect to Your Server
1. Open your FTP client
2. Enter the connection details:
   - Host: `zzw.muu.mybluehost.me`
   - Username: `claude@protip365.com`
   - Password: [Your password]
   - Port: `21`
3. Click Connect

### Step 3: Navigate to the Correct Directory
1. In the remote server panel, navigate to: `/home2/zzwmuumy/public_html`
   (This is where your website files should go)

### Step 4: Upload the Files
1. In the local panel, navigate to: `/Users/jacquesbolduc/Github/ProTip365/Docs/website/`
2. Select these files:
   - `index.html`
   - `privacy-policy.html`
   - `terms-of-service.html`
3. Drag them to the remote server panel (public_html folder)

## Using macOS Terminal (Alternative)

```bash
# Navigate to the website folder
cd /Users/jacquesbolduc/Github/ProTip365/Docs/website/

# Upload all HTML files using FTP
ftp claude@protip365.com@zzw.muu.mybluehost.me
# Enter password when prompted
# Then run these commands:
cd public_html
put index.html
put privacy-policy.html
put terms-of-service.html
quit
```

## Using Finder (Mac) - Connect to Server

1. Open Finder
2. Press Cmd+K (Go > Connect to Server)
3. Enter: `ftp://claude@protip365.com@zzw.muu.mybluehost.me`
4. Enter your password
5. Navigate to public_html folder
6. Drag and drop the HTML files

## After Upload - Verify

Check these URLs:
- https://protip365.com (Landing page)
- https://protip365.com/privacy-policy.html
- https://protip365.com/terms-of-service.html

## Important Notes

1. Make sure files go in the `public_html` directory
2. The domain protip365.com must be pointing to this server
3. Files should be accessible immediately after upload
4. If you see the Bluehost default page, you may need to delete or rename any existing `index.html` or `index.php` files in public_html

## Troubleshooting

- **Can't connect:** Check firewall settings, try IP address instead of domain
- **Permission denied:** Make sure you're using the correct password
- **Files not showing:** Clear browser cache, check file permissions (should be 644)
- **Domain not working:** DNS may need time to propagate if recently configured