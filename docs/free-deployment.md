# Free Deployment Guide

This repo has four deployable surfaces:

- `website/`: static marketing site
- `throttle-admin-portal/`: Vite React admin portal
- `throttle-frontend/throttle_ui/`: Flutter app, including a web build
- `throttle/`: Spring Boot backend with Docker-managed dependencies

## Recommended zero-cost path

Use this split:

1. Deploy `website/` to GitHub Pages or Cloudflare Pages.
2. Deploy `throttle-admin-portal/` to Cloudflare Pages.
3. Deploy Flutter Web only if you need a browser version of the mobile app.
4. Run the backend yourself:
   - on an Oracle Cloud Always Free VM, or
   - on your own machine with Docker Compose + Cloudflare Tunnel.

This backend is not a good fit for free serverless hosts because it expects:

- PostgreSQL
- Redis
- Neo4j
- Kafka
- Elasticsearch
- SMTP
- Prometheus/Grafana/Loki stack in `docker-compose.yml`

## Option A: Oracle Cloud Always Free

Use this if you want the app online 24/7 without paying.

1. Create an Oracle Cloud Free Tier account.
2. Create an Always Free Ubuntu VM.
3. Install Docker and Docker Compose.
4. Clone this repo onto the VM.
5. Start the dependency stack:

```bash
docker compose up -d postgres redis neo4j kafka elasticsearch
```

6. Start the backend:

```bash
cd throttle
./mvnw spring-boot:run
```

7. Open these ports on the VM security list:

- `8080` for the backend
- `5433`, `6379`, `7687`, `29092`, `9200` only if you explicitly need remote access

8. Point your frontend/admin env vars at:

- `https://<your-domain-or-vm-ip>/api/v1`
- `https://<your-domain-or-vm-ip>`

## Option B: Your own machine + Cloudflare Tunnel

Use this if you want fully free hosting and do not need 24/7 uptime.

1. Run the backend dependencies locally:

```bash
docker compose up -d postgres redis neo4j kafka elasticsearch
```

2. Start the backend:

```bash
cd throttle
./mvnw spring-boot:run
```

3. Install `cloudflared`.
4. Create a tunnel to `http://localhost:8080`.
5. Use the tunnel hostname as the backend base URL for your deployed clients.

This is the cheapest route, but the app is only online while your machine is on.

## Static deployments

### `website/`

Free options:

- GitHub Pages
- Cloudflare Pages

No backend integration is required unless you add it.

### `throttle-admin-portal/`

Free options:

- Cloudflare Pages
- Netlify Free
- Vercel Hobby

Required env vars:

```bash
VITE_API_BASE_URL=https://your-backend.example.com/api/v1
VITE_MANAGEMENT_BASE_URL=https://your-backend.example.com
```

Build command:

```bash
npm run build
```

Publish directory:

```bash
dist
```

### `throttle-frontend/throttle_ui/` as Flutter Web

Free options:

- Firebase Hosting
- Cloudflare Pages
- GitHub Pages

Required env vars in `.env` before building:

```bash
API_BASE_URL=https://your-backend.example.com/api/v1
MANAGEMENT_BASE_URL=https://your-backend.example.com
GOOGLE_CLIENT_ID=your-google-client-id
MAPBOX_PUBLIC_TOKEN=your-mapbox-public-token
WHATSAPP_COMMUNITY_URL=https://chat.whatsapp.com/your-community-link
```

Build command:

```bash
flutter build web
```

Publish directory:

```bash
build/web
```

## URL configuration

The deploy-time URLs are now centralized:

- Flutter: `throttle-frontend/throttle_ui/.env`
- Admin portal: `throttle-admin-portal/.env`

Examples are included as:

- `throttle-frontend/throttle_ui/.env.example`
- `throttle-admin-portal/.env.example`

## What still costs money

Nothing is required to pay if you use:

- GitHub Pages / Cloudflare Pages / Firebase Spark for static hosting
- Oracle Cloud Always Free for the VM
- your own machine for self-hosting

The tradeoff is operational complexity and uptime:

- self-hosted local machine: free, but not always online
- Oracle Free Tier: free, but setup is more involved
