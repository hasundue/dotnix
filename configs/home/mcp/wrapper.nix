{ pkgs, lib }:
stdioServers:
lib.attrsToList stdioServers
|> lib.imap0 (
  i:
  { name, value }:
  let
    package = value.package;
    env = value.env or [ ];
    socketPort = 9000 + i |> toString;
    backendPort = 9100 + i |> toString;
    capitalizedName = lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
  in
  {
    servers.${name} = {
      url = "http://127.0.0.1:${socketPort}/sse";
    };
    sockets."mcp-${name}" = {
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
    services."mcp-${name}-backend" = {
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
    services."mcp-${name}" = {
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
  }
)
|> lib.zipAttrsWith (_: lib.mergeAttrsList)
