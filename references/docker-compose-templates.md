# Docker Compose Templates

## Traefik (Reverse Proxy)

Use this configuration to set up Traefik. It handles SSL certificates automatically and routes traffic to your containers.

```yaml
services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    command:
      - "--api.insecure=true" # Disable in production or protect with middleware
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=your-email@example.com" # CHANGE THIS
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "./letsencrypt:/letsencrypt"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    networks:
      - proxy-net
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-dashboard.rule=Host(`traefik.yourdomain.com`)" # Optional
      - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
      - "traefik.http.routers.traefik-dashboard.tls.certresolver=myresolver"
      - "traefik.http.services.traefik-dashboard.loadbalancer.server.port=8080"
      # Watchtower: Update this container automatically
      - "com.centurylinklabs.watchtower.enable=true"

networks:
  proxy-net:
    external: true
```

## Watchtower (Auto-Update Containers)

Automatically updates your running containers when new images are available.

```yaml
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true # Remove old images
      - WATCHTOWER_SCHEDULE=0 0 4 * * * # Run every day at 4am
    restart: unless-stopped
    networks:
      - proxy-net
```

## Crowdsec (Security Automation)

Crowdsec parses logs to detect attacks and blocks malicious IPs.

```yaml
services:
  crowdsec:
    image: crowdsecurity/crowdsec
    container_name: crowdsec
    environment:
      GID: "${GID-1000}"
      COLLECTIONS: "crowdsecurity/traefik crowdsecurity/linux crowdsecurity/sshd"
    volumes:
      - ./config:/etc/crowdsec:rw
      - ./data:/var/lib/crowdsec/data:rw
      - /var/log/auth.log:/var/log/auth.log:ro
      - /var/log/syslog:/var/log/syslog:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy-net
    restart: unless-stopped
    labels:
      - "com.centurylinklabs.watchtower.enable=true"

networks:
  proxy-net:
    external: true
```

## Duplicati (Backups)

Duplicati provides a web interface for managing encrypted backups.

```yaml
services:
  duplicati:
    image: lscr.io/linuxserver/duplicati:latest
    container_name: duplicati
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config:/config
      - ./backups:/backups
      - /home/ubuntu:/source
    ports:
      - 8200:8200
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.duplicati.rule=Host(`backup.yourdomain.com`)"
      - "traefik.http.routers.duplicati.entrypoints=websecure"
      - "traefik.http.routers.duplicati.tls.certresolver=myresolver"
      - "traefik.http.services.duplicati.loadbalancer.server.port=8200"
      - "com.centurylinklabs.watchtower.enable=true"

networks:
  proxy-net:
    external: true
```