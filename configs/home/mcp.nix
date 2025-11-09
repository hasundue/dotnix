{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    mcp-nixos
    mcp-proxy
    zotero-mcp
  ];
  programs.mcp.enable = true;
  programs.mcp.servers = {
    github = {
      url = "https://api.githubcopilot.com/mcp/";
      headers = {
        Authorization = "Bearer {file:${config.age.secrets."github/claude-code".path}}";
      };
    };
    nixos.url = "http://127.0.0.1:9000/sse";
    zotero.url = "http://127.0.0.1:9001/sse";
  };
  systemd.user.sockets = {
    mcp-nixos = {
      Unit = {
        Description = "NixOS MCP Server Socket";
      };
      Socket = {
        ListenStream = "127.0.0.1:9000";
        Accept = false;
      };
      Install = {
        WantedBy = [ "sockets.target" ];
      };
    };
    mcp-zotero = {
      Unit = {
        Description = "Zotero MCP Server Socket";
      };
      Socket = {
        ListenStream = "127.0.0.1:9001";
        Accept = false;
      };
      Install = {
        WantedBy = [ "sockets.target" ];
      };
    };
  };
  systemd.user.services =
    let
      lib = pkgs.lib;
      mcp-proxy = lib.getExe pkgs.mcp-proxy;
    in
    {
      mcp-nixos-backend = {
        Unit = {
          Description = "NixOS MCP Server";
          StopWhenUnneeded = true;
        };
        Service = {
          Type = "simple";
          ExecStart = "${mcp-proxy} --port 9100 mcp-nixos";
          RuntimeMaxSec = 600;
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
      mcp-nixos = {
        Unit = {
          Description = "NixOS MCP Server Proxy";
          Requires = [
            "mcp-nixos.socket"
            "mcp-nixos-backend.service"
          ];
          After = [
            "mcp-nixos.socket"
            "mcp-nixos-backend.service"
          ];
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        Service = {
          Type = "notify";
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:9100";
          RuntimeMaxSec = 600;
        };
      };
      mcp-zotero-backend = {
        Unit = {
          Description = "Zotero MCP Server";
          StopWhenUnneeded = true;
        };
        Service = {
          Type = "simple";
          ExecStart = "${mcp-proxy} --port 9101 zotero-mcp";
          Environment = [
            "ZOTERO_LOCAL=true"
          ];
          RuntimeMaxSec = 600;
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
      mcp-zotero = {
        Unit = {
          Description = "Zotero MCP Server Proxy";
          Requires = [
            "mcp-zotero.socket"
            "mcp-zotero-backend.service"
          ];
          After = [
            "mcp-zotero.socket"
            "mcp-zotero-backend.service"
          ];
        };
        Service = {
          Type = "notify";
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:9101";
          RuntimeMaxSec = 600;
        };
      };
    };
}
