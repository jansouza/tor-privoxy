FROM alpine:edge AS base
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "TARGETPLATFORM=$TARGETPLATFORM BUILDPLATFORM=$BUILDPLATFORM"

# Install pakages
RUN apk --no-cache add \
    supervisor \
    bash \
    curl

COPY assets/supervisord.conf /etc/supervisord.conf

FROM base AS tools

######
# tor
######

# Install pakages
RUN apk --no-cache add \
    tor 

RUN addgroup -S tor \
    && adduser tor -G tor || true

# Copy scripts
COPY assets/tor-init.sh /usr/local/bin/tor-init.sh
RUN chmod +x /usr/local/bin/tor-init.sh \
    && chown tor:tor /usr/local/bin/tor-init.sh \
    && chown -R tor:tor /etc/tor

# Default values
ENV TOR_DataDirectory=/var/lib/tor
ENV TOR_SOCKSPort=9050
ENV TOR_ControlPort=9051
ENV TOR_CookieAuthentication=1
ENV TOR_LOG_LEVEL=notice

##########
# privoxy
##########

# Install pakages
RUN apk --no-cache add \
    privoxy 

RUN mv /etc/privoxy/config.new /etc/privoxy/config \
    && mv /etc/privoxy/default.action.new /etc/privoxy/default.action \
    && mv /etc/privoxy/user.action.new /etc/privoxy/user.action \
    && mv /etc/privoxy/default.filter.new /etc/privoxy/default.filter \
    && mv /etc/privoxy/user.filter.new /etc/privoxy/user.filter \
    && mv /etc/privoxy/regression-tests.action.new /etc/privoxy/regression-tests.action \
    && mv /etc/privoxy/trust.new /etc/privoxy/trust \
    && mv /etc/privoxy/match-all.action.new /etc/privoxy/match-all.action \
    && echo "forward-socks5t / 127.0.0.1:${TOR_SOCKSPort} ." >> /etc/privoxy/config

RUN addgroup -S privoxy \
    && adduser privoxy -G privoxy || true

# Copy scripts
COPY assets/privoxy-init.sh /usr/local/bin/privoxy-init.sh
RUN chmod +x /usr/local/bin/privoxy-init.sh \
    && chown privoxy:privoxy /usr/local/bin/privoxy-init.sh \
    && chown -R privoxy:privoxy /etc/privoxy

# Default values
ENV PRIVOXY_listen-address=0.0.0.0:8118
ENV PRIVOXY_LOG_LEVEL=512,1024,4096,8192

CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]