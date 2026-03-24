# SimpleLogin AIO: Unraid Setup Guide

This guide covers setting up the "Mega-Container" version of SimpleLogin on Unraid, which handles PostgreSQL, Redis, and Postfix internally.

## 1. Cloudflare DNS Setup
To route mail to your home internet, you need to point DNS records to your WAN IP. 

1. Create an `A` record pointing `mail.yourdomain.com` to your public Unraid IP.
2. Create an `MX` record on `yourdomain.com` pointing to `mail.yourdomain.com` with priority `10`.
3. Create a `TXT` record on `yourdomain.com` for SPF: `v=spf1 mx ~all`.
4. Create a `TXT` record for DMARC on `_dmarc.yourdomain.com`: `v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com`.

## 2. Unraid Network Setup (Port Forwarding)
1. In your physical hardware router (e.g., pfSense, UniFi, Eero), forward **TCP Port 25** to your Unraid Server's local IP address. 
2. Without this, the internet cannot deliver mail to your aliases!

## 3. Install the Template
1. Search CA for `SimpleLogin-AIO`.
2. Fill out your `App URL` (e.g., `https://app.yourdomain.com`), `Email Domain`, and `Support Email`.
3. Select your `SMTP Relay Mode` (crucial if your ISP blocks outbound Port 25, which 99% of them do). Fill in the credentials if using Brevo, Gmail, etc.
4. Click Apply.

## 4. Retrieve DKIM Keys 
The container takes about 30-45 seconds on its first boot to generate the internal database and cryptographic keys. 
1. Open the Docker Logs for SimpleLogin-AIO.
2. Scroll until you see the `SUCCESS: DKIM Keys Generated` banner. 
3. Copy the raw `TXT` record provided in the logs.
4. Go back to Cloudflare and add that `TXT` record (Name: `dkim._domainkey`).

You are fully self-hosted!
