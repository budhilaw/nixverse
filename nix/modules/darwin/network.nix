{
  services.dnscrypt-proxy = {
    settings = {
      listen_addresses = [ "127.0.0.1:5355" ];
      doh_servers = true;
      dnscrypt_servers = true;
      server_names = [
        "doh.tiarap.org"
        "doh.tiar.app-doh"
        # "adguard-dns"
        # "adguard-dns-doh"
        # "cloudflare"
        # "cloudflare-security"
        # "cloudflare-ipv6"
        # "cloudflare-security-ipv6"
      ];
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
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
          "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
          "https://ipv6.download.dnscrypt.info/resolvers-list/v3/relays.md"
        ];
        cache_file = "relays.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 72;
        prefix = "";
      };
    };
  };
}
