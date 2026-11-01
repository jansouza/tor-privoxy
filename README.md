# Tor & Privoxy Docker Container

This repository provides a Docker image that runs Tor and Privoxy together in a single container, enabling anonymous and secure browsing on the internet. Tor is a network of virtual tunnels that enhances privacy and security online. Privoxy is a filtering proxy that improves privacy, modifies web data, and removes ads and other unwanted content.

Inside the container, both services are managed by `supervisord`:

- **Tor** exposes a SOCKS5 proxy on port `9050` and a control port on `9051`.
- **Privoxy** exposes an HTTP proxy on port `8118` and forwards all traffic to Tor's SOCKS port.

The image is based on `alpine:3.22`, which ships Tor 0.4.9. Older Tor releases (0.4.8) are rejected by the Tor network since October 2026, so avoid changing the base image to an older Alpine release.

## Images

Prebuilt multi-arch images (`linux/amd64` and `linux/arm64`) are published on every push to `main`:

| Registry                  | Image                                 |
| ------------------------- | ------------------------------------- |
| Docker Hub                | `jansouza/tor-privoxy:latest`         |
| GitHub Container Registry | `ghcr.io/jansouza/tor-privoxy:latest` |

```bash
docker pull jansouza/tor-privoxy:latest
```

## Configuration

### Environment Variables

You can adjust the Tor and Privoxy configuration at startup using environment variables. Each variable maps to an option in the Tor (`/etc/tor/torrc`) or Privoxy (`/etc/privoxy/config`) configuration file. If the option already exists in the file, its value is replaced; otherwise, the option is appended.

- **Tor Configuration**: prefix the option name with `TOR_`. For example:
  - `TOR_SOCKSPort=9050` sets `SOCKSPort`.
  - `TOR_ExitNodes={us}` sets `ExitNodes`.

- **Privoxy Configuration**: prefix the option name with `PRIVOXY_`, keeping the option name exactly as written in the Privoxy config (including hyphens). For example:
  - `PRIVOXY_listen-address=0.0.0.0:8118` sets `listen-address`.
  - `PRIVOXY_toggle=1` sets `toggle`.

#### Notes

- Option names that contain an underscore after the prefix are ignored. Use `PRIVOXY_listen-address`, not `PRIVOXY_listen_address`.
- Variable names with hyphens work with `docker run -e`, Docker Compose and Kubernetes, but cannot be set with a shell `export`.
- For `TOR_SOCKSPort` and `TOR_ControlPort`, provide **only the port number**. The startup script binds them to `0.0.0.0` automatically (`TOR_SOCKSPort=9050` becomes `SOCKSPort 0.0.0.0:9050`).
- Privoxy forwards to Tor at `127.0.0.1:9050`, defined when the image is built. If you change `TOR_SOCKSPort` at runtime, Privoxy will not follow it; map a different host port instead (for example, `-p 19050:9050`).

#### Default Values

| Variable                   | Default                | Description                                              |
| -------------------------- | ---------------------- | -------------------------------------------------------- |
| `TOR_DataDirectory`        | `/var/lib/tor`         | Tor data directory.                                      |
| `TOR_SOCKSPort`            | `9050`                 | Tor SOCKS5 port (bound to `0.0.0.0`).                    |
| `TOR_ControlPort`          | `9051`                 | Tor control port (bound to `0.0.0.0`).                   |
| `TOR_CookieAuthentication` | `1`                    | Requires cookie authentication on the control port.      |
| `TOR_LOG_LEVEL`            | `notice`               | Tor log level, written to stdout.                        |
| `PRIVOXY_listen-address`   | `0.0.0.0:8118`         | Address and port where Privoxy listens.                  |
| `PRIVOXY_LOG_LEVEL`        | `512,1024,4096,8192`   | Privoxy debug levels to enable (see below).              |

### Configuring the `TOR_LOG_LEVEL` Variable

`TOR_LOG_LEVEL` sets the minimum severity of Tor messages sent to the container logs. Accepted values are `debug`, `info`, `notice`, `warn` and `err`.

```bash
TOR_LOG_LEVEL=notice # default value
```

### Configuring the `PRIVOXY_LOG_LEVEL` Variable

The `PRIVOXY_LOG_LEVEL` variable is used to configure the logging levels for Privoxy. This variable accepts a list of comma-separated values, where each value corresponds to a specific log level you wish to enable.

#### Format

```bash
PRIVOXY_LOG_LEVEL="512,1024,4096,8192" # default values
```

#### Log Levels Description

Each number in the list enables the matching `debug` line in the Privoxy configuration file, which are commented out by default:

```bash
debug     1 # Log the destination for each request. See also debug 1024.
debug     2 # show each connection status
debug     4 # show tagging-related messages
debug     8 # show header parsing
debug    16 # log all data written to the network
debug    32 # debug force feature
debug    64 # debug regular expression filters
debug   128 # debug redirects
debug   256 # debug GIF de-animation
debug   512 # Common Log Format
debug  1024 # Log the destination for requests Privoxy didn't let through, and the reason why.
debug  2048 # CGI user interface
debug  4096 # Startup banner and warnings.
debug  8192 # Non-fatal errors
debug 32768 # log all data read from the network
debug 65536 # Log the applying actions
```

#### Notes

- Ensure that the `PRIVOXY_LOG_LEVEL` variable only contains valid log level numbers supported by Privoxy.

### Using the Control Port

The control port uses cookie authentication by default. To read the cookie from outside the Tor process, set its location and make it group-readable:

```bash
-e TOR_CookieAuthFile=/var/lib/tor/control_auth_cookie \
-e TOR_CookieAuthFileGroupReadable=1
```

Since the control port is bound to `0.0.0.0`, avoid publishing port `9051` to untrusted networks.

## Usage

### Docker

Run the published image:

```bash
docker run -d \
  --name tor-privoxy \
  -p 9050:9050 \
  -p 9051:9051 \
  -p 8118:8118 \
  jansouza/tor-privoxy:latest
```

This starts Tor on port `9050` (SOCKS5) and Privoxy on port `8118` (HTTP).

To build the image locally instead:

```bash
git clone https://github.com/jansouza/tor-privoxy.git
cd tor-privoxy
docker build -t tor-privoxy .
```

Container logs (each line is prefixed with `[TOR]` or `[PRIVOXY]`):

```bash
docker logs -f tor-privoxy
```

Container console:

```bash
docker exec -it tor-privoxy sh
```

### Docker Compose

The repository includes a [docker-compose.yml](docker-compose.yml) file:

```yaml
version: '3'
services:
  tor-privoxy:
    build: .
    ports:
      - "9050:9050"
      - "9051:9051"
      - "8118:8118"
    environment:
      - TOR_SOCKSPort=9050
      - TOR_ControlPort=9051
      - PRIVOXY_listen-address=0.0.0.0:8118
```

To start the service:

```bash
docker compose up -d
```

To use the published image instead of building it, replace `build: .` with `image: jansouza/tor-privoxy:latest`.

### Kubernetes

The [k8s/deployment.yaml](k8s/deployment.yaml) manifest creates a `Deployment` and a `Service` exposing ports `9050`, `9051` and `8118`. The readiness probe checks through the SOCKS proxy that traffic is going through Tor.

```bash
kubectl apply -f k8s/deployment.yaml
```

### Local Development (Podman)

The `build.sh` and `destroy.sh` scripts build and run the container with Podman:

```bash
./build.sh    # builds the tor-privoxy-img image and starts the tor-privoxy container
./destroy.sh  # stops and removes the container and the image
```

## Check

```bash
# SOCKS5 Proxy
curl -x socks5h://localhost:9050 -s https://check.torproject.org/api/ip

# HTTP Proxy
curl -x http://localhost:8118 -s https://check.torproject.org/api/ip
```

Both commands should return `"IsTor":true`. Tor may take a few seconds to build its first circuit after the container starts.

## Browsing Anonymously

After starting the container, you can configure your browser or other applications to use the HTTP proxy at `localhost:8118` (Privoxy) or the SOCKS5 proxy at `localhost:9050` (Tor).

## Releases

The [release workflow](.github/workflows/release.yml) builds the image for `linux/amd64` and `linux/arm64`. On pull requests to `main` it only builds the image, to validate the change. On pushes to `main` it also pushes the `latest` tag to Docker Hub and GHCR, which requires the following repository secrets:

| Secret               | Description                                   |
| -------------------- | --------------------------------------------- |
| `DOCKERHUB_USERNAME` | Docker Hub user.                              |
| `DOCKERHUB_TOKEN`    | Docker Hub access token.                      |
| `GIT_TOKEN`          | GitHub token with `write:packages` scope.     |

## Contribution

Feel free to open issues or submit pull requests for improvements or bug fixes. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
