# Tor & Privoxy Docker Container

This repository provides a Docker setup to run Tor and Privoxy in containers, enabling anonymous and secure browsing on the internet. Tor is a network of virtual tunnels that enhances privacy and security online. Privoxy is a filtering proxy that improves privacy, modifies web data, and removes ads and other unwanted content.

## Configuration

### Environment Variables

You can dynamically adjust the Tor and Privoxy configuration by using environment variables. Each environment variable corresponds to a specific configuration option in the Tor or Privoxy configuration files. The format is as follows:

- **Tor Configuration**: Environment variables should be prefixed with `TOR_` followed by the option name. For example:
  - To set the `ControlPort` option, use `TOR_ControlPort=9051`.
  - To set the `SOCKSPort` option, use `TOR_SOCKSPort=0.0.0.0:9050`.

- **Privoxy Configuration**: Similarly, environment variables for Privoxy should be prefixed with `PRIVOXY_`. For example:
  - To set the `listen-address` option, use `PRIVOXY_listen_address=0.0.0.0:8118`.
  - To set the `toggle` option, use `PRIVOXY_toggle=1`.

### Example Usage

1. Clone this repository:

   ```bash
   git clone https://github.com/jansouza/tor-privoxy.git
   cd tor-privoxy
   ```

2. Build the Docker image:

   ```bash
   docker build -t tor-privoxy .
   ```

3. Run the container:

   ```bash
   docker run -d \
    --name tor-privoxy \
    -p 9050:9050 \
    -p 9051:9051 \
    -p 8118:8118 \
    -e TOR_SOCKSPort=0.0.0.0:9050 \
    -e TOR_ControlPort=9051 \
    -e PRIVOXY_listen-address=0.0.0.0:8118 \
     tor-privoxy
   ```

   This will start Tor on port `9050` and Privoxy on port `8118`.

### Using Docker Compose

You can use Docker Compose to manage the container more easily. Here’s an example `docker-compose.yml` file:

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
      - TOR_SOCKSPort=0.0.0.0:9050
      - TOR_ControlPort=9051
      - PRIVOXY_listen-address=0.0.0.0:8118
```

To start the service using Docker Compose, run:

```bash
docker-compose up -d
```

## Check

```
# SOCKS5 Proxy
curl -x socks5h://localhost:9050 -s https://check.torproject.org/api/ip

# HTTP Proxy
curl -x http://localhost:8118 -s https://check.torproject.org/api/ip
```

## Browsing Anonymously

After starting the container, you can configure your browser or other applications to use the HTTP proxy at `localhost:8118` (Privoxy) or the SOCKS5 proxy at `localhost:9050` (Tor).

## Contribution

Feel free to open issues or submit pull requests for improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
