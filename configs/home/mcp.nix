{ config, pkgs, ... }:
let
  lib = pkgs.lib;

  remoteServers = {
    github = {
      url = "https://api.githubcopilot.com/mcp/";
      headers = {
        Authorization = "Bearer {file:${config.age.secrets."github/claude-code".path}}";
      };
    };
  };

  # Define local MCP servers with minimal configuration
  stdioServers = {
    nixos = {
      package = "mcp-nixos";
    };
    zotero = {
      package = "zotero-mcp";
      env = [ "ZOTERO_LOCAL=true" ];
    };
  };

  # Generate MCP server configuration with auto-assigned ports
  mkMcpServer =
    name: index:
    {
      package,
      env ? [ ],
    }:
    let
      socketPort = 9000 + index;
      backendPort = 9100 + index;
      capitalizedName = lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
    in
    {
      inherit name socketPort;

      socket = {
        Unit = {
          Description = "${capitalizedName} MCP Server Socket";
        };
        Socket = {
          ListenStream = "127.0.0.1:${socketPort}";
          Accept = false;
        };
        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };

      backendService = {
        Unit = {
          Description = "${capitalizedName} MCP Server";
          StopWhenUnneeded = true;
        };
        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.mcp-proxy} --port ${backendPort} ${package}";
          Environment = env;
          RuntimeMaxSec = 600;
          Restart = "on-failure";
          RestartSec = 10;
        };
      };

      proxyService = {
        Unit = {
          Description = "${capitalizedName} MCP Server Proxy";
          Requires = [
            "mcp-${name}.socket"
            "mcp-${name}-backend.service"
          ];
          After = [
            "mcp-${name}.socket"
            "mcp-${name}-backend.service"
          ];
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        Service = {
          Type = "notify";
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${backendPort}";
          RuntimeMaxSec = 600;
        };
      };
    };

  # Generate all server configurations
  serverConfigs = lib.imap0 (i: { name, value }: mkMcpServer name i value) (
    lib.attrsToList stdioServers
  );

  # Convert to attribute sets for systemd
  allSockets = lib.listToAttrs (
    map (s: {
      name = "mcp-${s.name}";
      value = s.socket;
    }) serverConfigs
  );

  allServices = lib.listToAttrs (
    lib.concatMap (s: [
      {
        name = "mcp-${s.name}-backend";
        value = s.backendService;
      }
      {
        name = "mcp-${s.name}";
        value = s.proxyService;
      }
    ]) serverConfigs
  );

  # Generate MCP server URLs
  localMcpServers = lib.listToAttrs (
    map (s: {
      name = s.name;
      value = {
        url = "http://127.0.0.1:${s.socketPort}/sse";
      };
    }) serverConfigs
  );
in
{
  home.packages = map (s: pkgs.${s.package}) (lib.attrValues stdioServers);

  programs.mcp.enable = true;
  programs.mcp.servers = remoteServers // localMcpServers;

  systemd.user.sockets = allSockets;
  systemd.user.services = allServices;
}
