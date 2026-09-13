# Local encrypted DNS: system resolver -> dnsmasq :53 -> dnscrypt-proxy :53530.
# Note: while Tailscale's "Use Tailscale DNS" is on, macOS resolves through
# the tailnet's nameserver instead and this chain is bypassed.
{ lib, pkgs, ... }:

{
  networking = {
    knownNetworkServices = [
      "Wi-Fi"
      "Ethernet"
      "USB 10/100/1000 LAN"
    ];
    dns = [ "127.0.0.1" ];
  };

  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53530" ];
      doh_servers = true;
      dnscrypt_servers = true;
      server_names = [
        "doh.tiarap.org"
        "doh.tiar.app-doh"
      ];
      require_nolog = true;
      require_dnssec = true;
      require_nofilter = false;
      cache = true;
      cache_size = 4096;
      cache_min_ttl = 2400;
      cache_max_ttl = 86400;
      query_log = {
        file = "/private/var/lib/dnscrypt-proxy/query.log";
        ignored_qtypes = [
          "DNSKEY"
          "NS"
        ];
      };
      sources.public-resolvers = {
        cache_file = "public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 72;
        prefix = "";
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          "https://ipv6.download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
      };
      sources.relays = {
        cache_file = "relays.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 72;
        prefix = "";
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
          "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
          "https://ipv6.download.dnscrypt.info/resolvers-list/v3/relays.md"
        ];
      };
    };
  };
  users.users._dnscrypt-proxy.home = lib.mkForce "/private/var/lib/dnscrypt-proxy";

  launchd.daemons.dns-forwarder = {
    script = ''
      exec ${pkgs.dnsmasq}/bin/dnsmasq \
        --keep-in-foreground \
        --no-daemon \
        --no-resolv \
        --bind-interfaces \
        --listen-address=127.0.0.1 \
        --port=53 \
        --server=127.0.0.1#53530 \
        --cache-size=1000 \
        --log-facility=- \
        --no-poll
    '';
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      Label = "org.nixos.dns-forwarder";
    };
  };
}
