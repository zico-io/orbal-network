{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.zebes.media-stack;
in
{
  options.zebes.media-stack = {
    enable = mkEnableOption "media stack (Plex + *arr suite)";
    mediaPath = mkOption {
      type = types.path;
      default = "/data/media";
      description = "Path to media library";
    };
    downloadPath = mkOption {
      type = types.path;
      default = "/data/downloads";
      description = "Path to download directory";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {

      plex = {
        image = "lscr.io/linuxserver/plex:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = config.time.timeZone;
          VERSION = "docker";
        };
        volumes = [
          "${cfg.mediaPath}:/media"
          "plex-config:/config"
        ];
        extraOptions = [
          "--network=host"
          "--label=io.containers.autoupdate=registry"
        ];
      };

      sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = config.time.timeZone;
        };
        ports = [ "8989:8989" ];
        volumes = [
          "${cfg.mediaPath}/tv:/tv"
          "${cfg.downloadPath}:/downloads"
          "sonarr-config:/config"
        ];
        extraOptions = [ "--label=io.containers.autoupdate=registry" ];
      };

      radarr = {
        image = "lscr.io/linuxserver/radarr:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = config.time.timeZone;
        };
        ports = [ "7878:7878" ];
        volumes = [
          "${cfg.mediaPath}/movies:/movies"
          "${cfg.downloadPath}:/downloads"
          "radarr-config:/config"
        ];
        extraOptions = [ "--label=io.containers.autoupdate=registry" ];
      };

      prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";
          TZ = config.time.timeZone;
        };
        ports = [ "9696:9696" ];
        volumes = [
          "prowlarr-config:/config"
        ];
        extraOptions = [ "--label=io.containers.autoupdate=registry" ];
      };

    };
  };
}
