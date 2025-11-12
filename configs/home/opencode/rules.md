# General Rules and Guidelines

## Response Formatting

- Use fenced code blocks for all multi-line code/output (e.g. `...`).
- Always include a language tag when possible (e.g., `ts,`sh, `json,`diff).

## Web Research Operations

- For extensive web research (multiple pages, synthesis needed, uncertain
  scope), use the Task tool with the web-research subagent instead of WebFetch
  directly.
- For targeted lookups (specific fact, known concise page, user-provided URL),
  direct WebFetch is acceptable.

## GitHub Workflows

### Addressing Review Comments

- To reply to a pull request review comment using the GitHub CLI, use the
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

- To resolve a pull request review thread using the GitHub CLI, use the
  following command structure:

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
