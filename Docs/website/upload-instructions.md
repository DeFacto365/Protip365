# Upload Instructions for ProTip365 Website

## Files to Upload
All files are located in `/Users/jacquesbolduc/Github/ProTip365/Docs/website/`:
- `index.html` - Landing page
- `privacy-policy.html` - Privacy Policy
- `terms-of-service.html` - Terms of Service
- `privacy/index.html` - Short privacy route for app/store links
- `terms/index.html` - Short terms route for app/store links
- `delete-account/index.html` - Account deletion instructions

## Method 1: Using cPanel File Manager

1. Log into your Bluehost cPanel
2. Open "File Manager"
3. Navigate to the public web root for `protip365.com`
4. Click "Upload" button
5. Select and upload the root HTML files
6. Create `privacy`, `terms`, and `delete-account` folders if they do not exist
7. Upload each folder's `index.html`
8. Verify at https://protip365.com

## Method 2: Using FTP Client (FileZilla, Cyberduck, etc.)

1. Open your FTP client
2. Connect with:
   - Host: current Bluehost FTP host
   - Username: current Bluehost FTP user
   - Password: current password
   - Port: 21
3. Navigate to the domain's public web root
4. Upload the root HTML files and the `privacy`, `terms`, and `delete-account` folders
5. Verify at https://protip365.com

## Method 3: Using Command Line (if you have SSH access)

```bash
# From your local machine
scp /Users/jacquesbolduc/Github/ProTip365/Docs/website/*.html \
  YOUR_USER@YOUR_HOST:/path/to/public_html/
scp -r /Users/jacquesbolduc/Github/ProTip365/Docs/website/privacy \
  /Users/jacquesbolduc/Github/ProTip365/Docs/website/terms \
  /Users/jacquesbolduc/Github/ProTip365/Docs/website/delete-account \
  YOUR_USER@YOUR_HOST:/path/to/public_html/
```

## After Upload

1. **Test the URLs**:
   - https://protip365.com
   - https://protip365.com/privacy
   - https://protip365.com/privacy-policy.html
   - https://protip365.com/terms
   - https://protip365.com/terms-of-service.html
   - https://protip365.com/delete-account

2. **Update App Store Connect**:
   - Privacy Policy URL: `https://protip365.com/privacy`
   - Terms of Service URL: `https://protip365.com/terms`
   - Account deletion URL: `https://protip365.com/delete-account`

3. **Update the App** (Settings screen):
   - Privacy Policy link
   - Terms of Service link

4. **Update Placeholders**:
   - Replace `[Your Address]` with your business address
   - Replace `[Your State]` with your state
   - Update `support@protip365.com` if using different email

## Domain Setup (if needed)

If protip365.com isn't pointing to your Bluehost hosting yet:
1. Update domain nameservers to Bluehost nameservers
2. Or add an A record pointing to the current hosting IP from Bluehost/cPanel
3. Wait for DNS propagation (up to 48 hours)
