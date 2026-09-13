# The three docker-compose stacks from /opt, as declarative containers.
# Same images, same volumes, same host ports; one shared docker network so
# NPM, Immich and Seafile can all see each other by container name.
{
  config,
  lib,
  ...
}:

let
  net = "homelab";
  tz = "Asia/Jakarta";
  opt = "/opt/homelab";
  data = "/mnt/hdd-ext";
  ids = {
    PUID = "1000";
    PGID = "1000";
    TZ = tz;
  };
  secret = name: config.sops.secrets.${name}.path;
  immichVersion = "v3";

  # linuxserver.io style *arr container
  lsio = name: port: mem: {
    image = "lscr.io/linuxserver/${name}:latest";
    environment = ids;
    volumes = [
      "${opt}/${name}/config:/config"
      "${data}:/data"
    ];
    ports = [ "${port}:${port}" ];
    networks = [ net ];
    extraOptions = [
      "--memory=${mem}"
      "--add-host=socks-proxy:host-gateway"
    ];
  };

  containers = {
    ### media
    jellyfin = {
      image = "lscr.io/linuxserver/jellyfin:latest";
      environment = ids;
      volumes = [
        "${opt}/jellyfin/config:/config"
        "${data}/media:/media"
      ];
      ports = [ "8096:8096" ];
      devices = [ "/dev/dri:/dev/dri" ];
      networks = [ net ];
      extraOptions = [ "--memory=2g" ];
    };

    gluetun = {
      image = "qmcgaw/gluetun:latest";
      capabilities.NET_ADMIN = true;
      devices = [ "/dev/net/tun:/dev/net/tun" ];
      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "wireguard";
        WIREGUARD_ADDRESSES = "10.2.0.2/32";
        SERVER_COUNTRIES = "Singapore";
        VPN_PORT_FORWARDING = "on";
        VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
        TZ = tz;
      };
      environmentFiles = [ (secret "gluetun/env") ]; # WIREGUARD_PRIVATE_KEY
      ports = [
        "8080:8080" # qbittorrent web UI (shares gluetun's netns)
        "6881:6881"
        "6881:6881/udp"
      ];
      networks = [ net ];
      extraOptions = [ "--memory=256m" ];
    };

    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      environment = ids // {
        WEBUI_PORT = "8080";
      };
      volumes = [
        "${opt}/qbittorrent/config:/config"
        "${data}:/data"
      ];
      dependsOn = [ "gluetun" ];
      extraOptions = [
        "--network=container:gluetun"
        "--memory=1g"
      ];
    };

    radarr = lsio "radarr" "7878" "512m";
    sonarr = lsio "sonarr" "8989" "512m";
    prowlarr = (lsio "prowlarr" "9696" "256m") // {
      volumes = [ "${opt}/prowlarr/config:/config" ];
    };
    whisparr = (lsio "whisparr" "6969" "512m") // {
      image = "ghcr.io/hotio/whisparr:latest";
      environment = ids // {
        UMASK = "002";
      };
    };
    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      environment = {
        LOG_LEVEL = "info";
        TZ = tz;
      };
      ports = [ "8191:8191" ];
      networks = [ net ];
      extraOptions = [
        "--memory=512m"
        "--add-host=socks-proxy:host-gateway"
      ];
    };

    ### edge
    npm = {
      image = "jc21/nginx-proxy-manager:latest";
      volumes = [
        "${opt}/npm/data:/data"
        "${opt}/npm/letsencrypt:/etc/letsencrypt"
      ];
      ports = [
        "80:80"
        "443:443"
        "81:81"
      ];
      networks = [ net ];
      extraOptions = [ "--memory=512m" ];
    };

    adguardhome = {
      image = "adguard/adguardhome:latest";
      volumes = [
        "${opt}/adguardhome/work:/opt/adguardhome/work"
        "${opt}/adguardhome/conf:/opt/adguardhome/conf"
      ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "3000:3000/tcp"
      ];
      networks = [ net ];
    };

    vaultwarden = {
      image = "vaultwarden/server:latest";
      environment = {
        DOMAIN = "https://vault.budhilaw.com";
        SIGNUPS_ALLOWED = "false";
        TZ = tz;
      };
      environmentFiles = [ (secret "vaultwarden/env") ]; # ADMIN_TOKEN
      volumes = [ "${opt}/vaultwarden/data:/data" ];
      networks = [ net ];
      extraOptions = [ "--memory=256m" ];
    };

    ### immich
    immich_server = {
      image = "ghcr.io/immich-app/immich-server:${immichVersion}";
      environment = {
        TZ = tz;
        DB_HOSTNAME = "immich_postgres";
        DB_USERNAME = "postgres";
        DB_DATABASE_NAME = "immich";
        REDIS_HOSTNAME = "immich_redis";
        IMMICH_MACHINE_LEARNING_URL = "http://immich_machine_learning:3003";
      };
      environmentFiles = [ (secret "immich/server-env") ]; # DB_PASSWORD
      volumes = [ "${data}/immich:/data" ];
      ports = [ "2283:2283" ];
      dependsOn = [
        "immich_redis"
        "immich_postgres"
      ];
      networks = [ net ];
    };

    immich_machine_learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
      environment.TZ = tz;
      volumes = [ "immich-model-cache:/cache" ];
      networks = [ net ];
    };

    immich_redis = {
      image = "docker.io/valkey/valkey:9@sha256:3b55fbaa0cd93cf0d9d961f405e4dfcc70efe325e2d84da207a0a8e6d8fde4f9";
      networks = [ net ];
    };

    immich_postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      environmentFiles = [ (secret "immich/postgres-env") ]; # POSTGRES_PASSWORD
      volumes = [ "/opt/immich/postgres:/var/lib/postgresql/data" ];
      networks = [ net ];
      extraOptions = [ "--shm-size=128m" ];
    };

    ### seafile
    seafile-mysql = {
      image = "mariadb:10.11";
      environment = {
        MYSQL_LOG_CONSOLE = "true";
        MARIADB_AUTO_UPGRADE = "1";
      };
      environmentFiles = [ (secret "seafile/mysql-env") ]; # MYSQL_ROOT_PASSWORD
      volumes = [ "/opt/seafile-mysql/db:/var/lib/mysql" ];
      networks = [ net ];
    };

    seafile-redis = {
      image = "redis";
      cmd = [
        "/bin/sh"
        "-c"
        "redis-server --requirepass \"$REDIS_PASSWORD\""
      ];
      environmentFiles = [ (secret "seafile/redis-env") ]; # REDIS_PASSWORD
      networks = [ net ];
    };

    seafile = {
      image = "seafileltd/seafile-mc:13.0-latest";
      environment = {
        SEAFILE_MYSQL_DB_HOST = "seafile-mysql";
        SEAFILE_MYSQL_DB_PORT = "3306";
        SEAFILE_MYSQL_DB_USER = "seafile";
        SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
        SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
        SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";
        TIME_ZONE = tz;
        SEAFILE_SERVER_HOSTNAME = "files.budhilaw.com";
        SEAFILE_SERVER_PROTOCOL = "https";
        SITE_ROOT = "/";
        NON_ROOT = "false";
        SEAFILE_LOG_TO_STDOUT = "false";
        ENABLE_GO_FILESERVER = "true";
        ENABLE_SEADOC = "true";
        SEADOC_SERVER_URL = "https://files.budhilaw.com/sdoc-server";
        CACHE_PROVIDER = "redis";
        REDIS_HOST = "seafile-redis";
        REDIS_PORT = "6379";
        ENABLE_NOTIFICATION_SERVER = "false";
        ENABLE_SEAFILE_AI = "false";
        ENABLE_FACE_RECOGNITION = "false";
        MD_FILE_COUNT_LIMIT = "100000";
      };
      # SEAFILE_MYSQL_DB_PASSWORD, INIT_SEAFILE_MYSQL_ROOT_PASSWORD, REDIS_PASSWORD,
      # JWT_PRIVATE_KEY, SEAFILE_AI_SECRET_KEY, INIT_SEAFILE_ADMIN_{EMAIL,PASSWORD}
      environmentFiles = [ (secret "seafile/server-env") ];
      volumes = [ "${data}/seafile-data:/shared" ];
      ports = [ "8088:80" ];
      dependsOn = [
        "seafile-mysql"
        "seafile-redis"
      ];
      networks = [ net ];
    };
  };
in
{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers = {
    backend = "docker";
    inherit containers;
  };

  systemd.services = {
    # The shared bridge, created once before any container starts. The fixed
    # bridge name lets the firewall admit container -> host traffic (SOCKS).
    docker-network-homelab = {
      description = "docker network ${net}";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        docker=${config.virtualisation.docker.package}/bin/docker
        $docker network inspect ${net} >/dev/null 2>&1 \
          || $docker network create -o com.docker.network.bridge.name=br-${net} ${net}
      '';
    };
  }
  // lib.genAttrs (map (n: "docker-${n}") (lib.attrNames containers)) (_: {
    after = [ "docker-network-homelab.service" ];
    requires = [ "docker-network-homelab.service" ];
  });
}
