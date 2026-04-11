#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any


STATE_MARKER = "<!-- issue-monitor-state"
LEGACY_STATE_MARKER = "<!-- swift-packaging-monitor-state"
CONFIG_MARKER = "<!-- issue-monitor-config"
STATE_END = "-->"
API_ROOT = "https://api.github.com"
PR_SEARCH_LIMIT = 10


@dataclass(frozen=True)
class Signal:
  fingerprint: str
  summary: str
  url: str


@dataclass(frozen=True)
class MonitorConfig:
  issue_number: int
  issue_title: str
  issue_url: str
  name: str
  watched_issues: tuple[tuple[str, str, int], ...]
  pr_search_queries: tuple[str, ...]
  pr_search_limit: int


def require_env(name: str) -> str:
  value = os.getenv(name)
  if not value:
    raise RuntimeError(f"Missing required environment variable: {name}")
  return value


TOKEN = require_env("GITHUB_TOKEN")
OWNER, REPO = require_env("GITHUB_REPOSITORY").split("/", 1)
ISSUE_NUMBER = os.getenv("ISSUE_NUMBER", "").strip()


def github_request(
  path: str,
  *,
  method: str = "GET",
  data: dict[str, Any] | None = None,
  query: dict[str, Any] | None = None,
) -> Any:
  url = f"{API_ROOT}{path}"
  if query:
    url = f"{url}?{urllib.parse.urlencode(query)}"

  payload = None
  if data is not None:
    payload = json.dumps(data).encode()

  request = urllib.request.Request(
    url,
    method=method,
    data=payload,
    headers={
      "Accept": "application/vnd.github+json",
      "Authorization": f"Bearer {TOKEN}",
      "User-Agent": "hasundue-dotnix-issue-monitor",
      "X-GitHub-Api-Version": "2022-11-28",
    },
  )

  try:
    with urllib.request.urlopen(request) as response:
      charset = response.headers.get_content_charset() or "utf-8"
      return json.loads(response.read().decode(charset))
  except urllib.error.HTTPError as error:
    body = error.read().decode("utf-8", errors="replace")
    raise RuntimeError(f"GitHub API request failed: {error.code} {url}\n{body}") from error


def fetch_issue(owner: str, repo: str, number: int) -> dict[str, Any]:
  return github_request(f"/repos/{owner}/{repo}/issues/{number}")


def list_repo_issues() -> list[dict[str, Any]]:
  return github_request(
    f"/repos/{OWNER}/{REPO}/issues",
    query={
      "state": "open",
      "per_page": "100",
    },
  )


def search_pull_requests(query: str) -> list[dict[str, Any]]:
  result = github_request(
    "/search/issues",
    query={
      "q": query,
      "sort": "updated",
      "order": "desc",
      "per_page": str(PR_SEARCH_LIMIT),
    },
  )
  return result.get("items", [])


def fetch_issue_comments(issue_number: int) -> list[dict[str, Any]]:
  return github_request(
    f"/repos/{OWNER}/{REPO}/issues/{issue_number}/comments",
    query={"per_page": "100"},
  )


def extract_hidden_json(body: str, marker: str) -> dict[str, Any] | None:
  start = body.find(marker)
  if start < 0:
    return None

  remainder = body[start + len(marker):]
  end = remainder.find(STATE_END)
  if end < 0:
    raise ValueError(f"Unterminated hidden JSON block for marker: {marker}")

  return json.loads(remainder[:end].strip())


def extract_state(comment_body: str) -> dict[str, Any]:
  marker = None
  if comment_body.startswith(STATE_MARKER):
    marker = STATE_MARKER
  elif comment_body.startswith(LEGACY_STATE_MARKER):
    marker = LEGACY_STATE_MARKER

  if marker is None:
    raise ValueError("Comment does not contain swift monitor state")

  stripped = comment_body[len(marker):]
  if stripped.endswith(STATE_END):
    stripped = stripped[: -len(STATE_END)]
  return json.loads(stripped.strip())


def build_state_comment(state: dict[str, Any]) -> str:
  return f"{STATE_MARKER}\n{json.dumps(state, indent=2, sort_keys=True)}\n{STATE_END}"


def find_state_comment(comments: list[dict[str, Any]]) -> dict[str, Any] | None:
  for comment in comments:
    body = comment.get("body", "")
    if body.startswith(STATE_MARKER) or body.startswith(LEGACY_STATE_MARKER):
      return comment
  return None


def parse_monitor_config(issue: dict[str, Any]) -> MonitorConfig | None:
  config = extract_hidden_json(issue.get("body") or "", CONFIG_MARKER)
  if config is None:
    return None

  watched_issues = tuple(
    (item["owner"], item["repo"], int(item["number"]))
    for item in config.get("watched_issues", [])
  )
  pr_search_queries = tuple(config.get("pr_search_queries", []))
  return MonitorConfig(
    issue_number=issue["number"],
    issue_title=issue["title"],
    issue_url=issue["html_url"],
    name=config.get("name", issue["title"]),
    watched_issues=watched_issues,
    pr_search_queries=pr_search_queries,
    pr_search_limit=int(config.get("pr_search_limit", PR_SEARCH_LIMIT)),
  )


def collect_issue_signals(config: MonitorConfig) -> list[Signal]:
  signals: list[Signal] = []
  for owner, repo, number in config.watched_issues:
    issue = fetch_issue(owner, repo, number)
    fingerprint = f"issue:{owner}/{repo}#{number}:{issue['updated_at']}"
    summary = (
      f"Tracked issue updated: `{owner}/{repo}#{number}`"
      f" - {issue['title']} (updated {issue['updated_at']})"
    )
    signals.append(Signal(fingerprint=fingerprint, summary=summary, url=issue["html_url"]))
  return signals


def collect_pr_signals(config: MonitorConfig) -> list[Signal]:
  matches: dict[str, Signal] = {}
  for query in config.pr_search_queries:
    for item in search_pull_requests(query):
      number = item["number"]
      repo_name = item["repository_url"].rsplit("/", 1)[-1]
      title = item["title"]
      summary = f"New matching PR: `NixOS/{repo_name}#{number}` - {title}"
      fingerprint = f"pr:NixOS/{repo_name}#{number}"
      matches[fingerprint] = Signal(
        fingerprint=fingerprint,
        summary=summary,
        url=item["html_url"],
      )
  return sorted(matches.values(), key=lambda signal: signal.fingerprint)[: config.pr_search_limit]


def post_issue_comment(issue_number: int, body: str) -> None:
  github_request(
    f"/repos/{OWNER}/{REPO}/issues/{issue_number}/comments",
    method="POST",
    data={"body": body},
  )


def update_issue_comment(comment_id: int, body: str) -> None:
  github_request(
    f"/repos/{OWNER}/{REPO}/issues/comments/{comment_id}",
    method="PATCH",
    data={"body": body},
  )


def format_notification(config: MonitorConfig, new_signals: list[Signal]) -> str:
  lines = [
    f"Issue monitor found new signals for **{config.name}**:",
    "",
  ]
  for signal in new_signals:
    lines.append(f"- {signal.summary}")
    lines.append(f"  {signal.url}")
  lines.extend(
    [
      "",
      "_Generated by `.github/workflows/issue-monitor.yml`._",
    ]
  )
  return "\n".join(lines)


def process_issue(config: MonitorConfig) -> None:
  print(f"Processing issue #{config.issue_number}: {config.issue_title}", flush=True)
  current_signals = collect_issue_signals(config) + collect_pr_signals(config)
  comments = fetch_issue_comments(config.issue_number)
  state_comment = find_state_comment(comments)

  if state_comment is None:
    baseline = {
      "issue_number": config.issue_number,
      "name": config.name,
      "version": 1,
      "seen_fingerprints": sorted(signal.fingerprint for signal in current_signals),
    }
    post_issue_comment(config.issue_number, build_state_comment(baseline))
    print("Initialized issue monitor baseline.", flush=True)
    return

  state = extract_state(state_comment["body"])
  seen_fingerprints = set(state.get("seen_fingerprints", []))
  new_signals = [signal for signal in current_signals if signal.fingerprint not in seen_fingerprints]

  updated_state = {
    "issue_number": config.issue_number,
    "name": config.name,
    "version": 1,
    "seen_fingerprints": sorted(seen_fingerprints | {signal.fingerprint for signal in current_signals}),
  }
  update_issue_comment(state_comment["id"], build_state_comment(updated_state))

  if not new_signals:
    print("No new signals found.", flush=True)
    return

  post_issue_comment(config.issue_number, format_notification(config, new_signals))
  print(f"Posted notification for {len(new_signals)} new signal(s).", flush=True)


def monitored_issues() -> list[dict[str, Any]]:
  if ISSUE_NUMBER:
    issue = fetch_issue(OWNER, REPO, int(ISSUE_NUMBER))
    return [issue]

  return [
    issue
    for issue in list_repo_issues()
    if "pull_request" not in issue
  ]


def main() -> int:
  issues = monitored_issues()
  configs = [config for issue in issues if (config := parse_monitor_config(issue)) is not None]

  if not configs:
    print("No configured monitor issues found.", flush=True)
    return 0

  for config in configs:
    process_issue(config)

  return 0


if __name__ == "__main__":
  try:
    raise SystemExit(main())
  except Exception as error:  # noqa: BLE001
    print(str(error), file=sys.stderr)
    raise
