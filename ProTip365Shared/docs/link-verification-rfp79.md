# RFP-79 Link Verification

## Commands

```sh
curl -L https://protip365.com/privacy
curl -L https://protip365.com/terms
curl -L https://protip365.com/delete-account

curl -k -L -s -o /dev/null -w "%{http_code} %{url_effective}\n" https://protip365.com/privacy
curl -k -L -s -o /dev/null -w "%{http_code} %{url_effective}\n" https://protip365.com/terms
curl -k -L -s -o /dev/null -w "%{http_code} %{url_effective}\n" https://protip365.com/delete-account
```

## Results

| URL | Result |
| --- | --- |
| `https://protip365.com/privacy` | TLS validation failed with curl code 60; with `-k`, returned `200 https://protip365.com/cgi-sys/suspendedpage.cgi`. |
| `https://protip365.com/terms` | TLS validation failed with curl code 60; with `-k`, returned `200 https://protip365.com/cgi-sys/suspendedpage.cgi`. |
| `https://protip365.com/delete-account` | TLS validation failed with curl code 60; with `-k`, returned `200 https://protip365.com/cgi-sys/suspendedpage.cgi`. |
| `mailto:support@protip365.com` | Present in app; mailbox deliverability not verifiable by curl. |

## Linear Bug

- RFP-139: Store blocker for failed public compliance URLs.

## Result

RFP-79 verification is complete, but store readiness is blocked until RFP-139 is fixed and retested.
