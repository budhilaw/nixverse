# Host-level services: secrets, tailnet, Cloudflare tunnel, vendor agent,
# and the SOCKS proxy that used to be a hand-built container.
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Decrypted with the host's SSH key (see .sops.yaml). Keep the Ubuntu host
  # key on reinstall (README) or re-key the file for the new one.
  sops = {
    defaultSopsFile = "${inputs.self}/secrets/homelab-lenovo.yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "cloudflared/token" = { };
      "gluetun/env" = { };
      "vaultwarden/env" = { };
      "immich/server-env" = { };
      "immich/postgres-env" = { };
      "seafile/mysql-env" = { };
      "seafile/redis-env" = { };
      "seafile/server-env" = { };
    };
  };

  # Headscale-backed tailnet. Node state is carried over from Ubuntu, so no
  # re-enrolment; the flags below are re-applied on every boot.
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--advertise-routes=192.168.18.0/24"
      "--accept-dns=false"
    ];
  };

  # Remotely-managed tunnel (token from the Cloudflare dashboard).
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = "token:${config.sops.secrets."cloudflared/token".path}";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel run --token-file %d/token";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # Proprietary agent for cloudnan.com; binary + config are copied over from
  # the Ubuntu install (README), not built from source.
  systemd.services.cloudnan-agent = {
    description = "Cloudnan Agent";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "/var/lib/cloudnan/cloudnan-agent";
    serviceConfig = {
      ExecStart = "/var/lib/cloudnan/cloudnan-agent -config /etc/cloudnan/agent.yaml -panel https://cloudnan.com";
      Restart = "always";
      RestartSec = 10;
    };
  };

  # SOCKS5 on :1080 via an SSH tunnel to the Onidel VPS. Containers reach it
  # as `socks-proxy` (host-gateway alias in containers.nix).
  systemd.services.socks-proxy = {
    description = "SOCKS proxy over SSH (autossh)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "/var/lib/socks-proxy/id_ed25519";
    environment.AUTOSSH_GATETIME = "0";
    serviceConfig = {
      ExecStart = ''
        ${pkgs.autossh}/bin/autossh -M 0 -N -D 0.0.0.0:1080 \
          -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
          -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=yes \
          -o UserKnownHostsFile=/var/lib/socks-proxy/known_hosts \
          -i /var/lib/socks-proxy/id_ed25519 \
          -p 22 root@104.250.122.107
      '';
      Restart = "always";
      RestartSec = 10;
    };
  };
}
