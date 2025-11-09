{ pkgs, lib }:
stdioServers:
let
  mkMcpServer =
    name: index:
    {
      package,
      env ? [ ],
    }:
    let
      socketPort = 9000 + index |> toString;
      backendPort = 9100 + index |> toString;
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
      backend = {
        Unit = {
          Description = "${capitalizedName} MCP Server";
          StopWhenUnneeded = true;
        };
        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.mcp-proxy} --port ${backendPort} ${lib.getExe package}";
          Environment = env;
          RuntimeMaxSec = 600;
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
      proxy = {
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

  serverConfigs = lib.imap0 (i: { name, value }: mkMcpServer name i value) (
    lib.attrsToList stdioServers
  );
in
{
  servers = lib.listToAttrs (
    map (s: {
      name = s.name;
      value = {
        url = "http://127.0.0.1:${s.socketPort}/sse";
      };
    }) serverConfigs
  );
  sockets = lib.listToAttrs (
    map (s: {
      name = "mcp-${s.name}";
      value = s.socket;
    }) serverConfigs
  );
  services = lib.listToAttrs (
    lib.concatMap (s: [
      {
        name = "mcp-${s.name}-backend";
        value = s.backend;
      }
      {
        name = "mcp-${s.name}";
        value = s.proxy;
      }
    ]) serverConfigs
  );
}
