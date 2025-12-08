# Upload Instructions for ProTip365 Website

## Files to Upload
All files are located in `/Users/jacquesbolduc/Github/ProTip365/Docs/website/`:
- `index.html` - Landing page
- `privacy-policy.html` - Privacy Policy
- `terms-of-service.html` - Terms of Service

## Method 1: Using cPanel File Manager

1. Log into your Bluehost cPanel
2. Open "File Manager"
3. Navigate to `/home2/zzwmuumy/public_html`
4. Click "Upload" button
5. Select and upload all 3 HTML files
6. Verify at https://protip365.com

## Method 2: Using FTP Client (FileZilla, Cyberduck, etc.)

1. Open your FTP client
2. Connect with:
   - Host: `protip365.com` or `50.6.153.246`
   - Username: `zzwmuumy`
   - Password: (your password)
   - Port: 21
3. Navigate to `/public_html` directory
4. Upload all 3 HTML files
5. Verify at https://protip365.com

## Method 3: Using Command Line (if you have SSH access)

```bash
# From your local machine
scp /Users/jacquesbolduc/Github/ProTip365/Docs/website/*.html zzwmuumy@protip365.com:/home2/zzwmuumy/public_html/
```

## After Upload

1. **Test the URLs**:
   - https://protip365.com
   - https://protip365.com/privacy-policy.html
   - https://protip365.com/terms-of-service.html

2. **Update App Store Connect**:
   - Privacy Policy URL: `https://protip365.com/privacy-policy.html`
   - Terms of Service URL: `https://protip365.com/terms-of-service.html`

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
2. Or add A record pointing to `50.6.153.246`
3. Wait for DNS propagation (up to 48 hours)