# Mac Mini n8n Setup Guide

## 1. Install n8n

```bash
# SSH into Mac Mini
ssh user@mac-mini-ip

# Install n8n globally
npm install -g n8n

# Create n8n data directory
mkdir -p ~/.n8n
```

## 2. Environment Variables

Create `~/.n8n/.env`:

```bash
cat > ~/.n8n/.env << 'EOF'
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=YourSecurePassword

# Webhook URL (required for external triggers)
WEBHOOK_URL=https://n8n.yourdomain.com/

# Timezone
GENERIC_TIMEZONE=Europe/Istanbul

# Site URL for workflows
SITE_URL=https://ainews.vercel.app
EOF
```

## 3. Start n8n with PM2

```bash
# Start n8n as a daemon
pm2 start n8n --name "n8n" -- start

# Save PM2 config for auto-restart
pm2 save

# Verify it's running
pm2 status
```

n8n will be available at `http://localhost:5678`

## 4. Nginx Reverse Proxy

Add to your Nginx config (`/etc/nginx/sites-available/n8n` or similar):

```nginx
server {
    listen 80;
    server_name n8n.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding off;
    }
}
```

```bash
# Enable site and restart
sudo ln -s /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 5. SSL with Certbot

```bash
sudo certbot --nginx -d n8n.yourdomain.com
```

## 6. Setup Credentials in n8n

Open n8n at `https://n8n.yourdomain.com` and add these credentials:

### Supabase
- Go to: Settings > Credentials > Add Credential > Supabase
- **Host**: Your Supabase project URL (e.g., `https://xxxxx.supabase.co`)
- **Service Role Key**: Your Supabase service role key (NOT anon key)

### OpenAI
- Go to: Settings > Credentials > Add Credential > OpenAI
- **API Key**: Your OpenAI API key

### Twitter/X
- Go to: Settings > Credentials > Add Credential > Twitter OAuth2
- **Client ID** and **Client Secret** from X Developer Portal
- Complete the OAuth2 flow

### Resend
- Go to: Settings > Credentials > Add Credential > Resend
- **API Key**: Your Resend API key

## 7. Import Workflows

1. Open n8n dashboard
2. Click **"..."** menu > **Import from file**
3. Import each JSON file in order:
   - `01-ai-news-pipeline.json`
   - `02-tweet-new-articles.json`
   - `03-weekly-newsletter.json`
4. In each workflow, update the credential references:
   - Click each Supabase/OpenAI/Twitter/Resend node
   - Select the correct credential from the dropdown
5. **Activate** each workflow (toggle switch on top right)

## 8. Test Workflows

For each workflow:
1. Click **"Test workflow"** button (play icon)
2. Check the execution log for errors
3. Verify data in Supabase dashboard

### Pipeline test:
- Run "AI News Pipeline" manually
- Check `articles` table in Supabase for new entries
- Verify article content quality

### Tweet test:
- First ensure there are published articles without tweets
- Run "Tweet New Articles" manually
- Check your X account for the tweet

### Newsletter test:
- Insert a test subscriber in Supabase: `INSERT INTO subscribers (email, confirmed) VALUES ('your@email.com', true);`
- Run "Weekly Newsletter" manually
- Check your inbox

## 9. Monitoring

```bash
# Check n8n process
pm2 status

# View n8n logs
pm2 logs n8n

# Restart n8n
pm2 restart n8n
```

In n8n dashboard:
- **Executions** tab shows all workflow runs with status
- Failed executions are highlighted in red
- Click any execution to see detailed node-by-node results
