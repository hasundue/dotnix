# General Rules and Guidelines

## Response Formatting

- Use fenced code blocks for all multi-line code/output (e.g. `...`).
- Always include a language tag when possible (e.g., `ts,`sh, `json,`diff).

## Repository Access and Code Inspection Workflow

When analyzing code from GitHub or similar sources, **do not use WebFetch for
individual files**.

1. **Clone the repository locally with `ghq`** (reuse the clone if it already
   exists).
2. **Use the Read tool** to inspect all files from the local clone.
3. Use WebFetch **only** for resources outside the repository.

Always operate on the local `ghq` clone for code analysis.

## Web Research Workflow

- For extensive web research (multiple pages, synthesis needed, uncertain
  scope), use the Task tool with the web-research subagent instead of WebFetch
  directly.
- For targeted lookups (specific fact, known concise page, user-provided URL),
  direct WebFetch is acceptable.

## GitHub Workflows

### Finding PR for Current Branch

To find the GitHub PR associated with the current branch:

1. Get current branch name: `git branch --show-current`
2. Get repository info: `git remote get-url origin`
3. Extract owner/repo from URL (e.g., `hasundue/dotnix`)
4. Search for PR with branch name:
   `gh pr list --search "head:<branch> repo:<owner>/<repo>"`

### Addressing Review Comments

To reply to a pull request review comment using the GitHub CLI, use the
following command structure:

```sh
$ gh api graphql -f query='
mutation {
  addPullRequestReviewThreadReply(input: {
    pullRequestReviewThreadId: "PRRT_kwDOOS4_0s5hnG0g"
    body: "913f90dd"
  }) {
    comment {
      id
    }
  }
}'
```

The body field should be the commit hash that addresses the review comment, or a
brief explanation when declining the suggestion.

When a review comment has been addressed and no further discussion is needed,
resolve the pull request review thread using the GitHub CLI with the following
command structure:

```sh
$ gh api graphql -f query='
mutation {
  resolveReviewThread(input: {
    threadId: "PRRT_kwDOOS4_0s5hnG0g"
  }) {
    thread {
      id
      isResolved
    }
  }
}'
```
