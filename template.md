# Top 100 PHP repositories using coding agents

This list ranks up to 100 public GitHub repositories by stars. To qualify, a repository must use PHP as its primary language, have a default-branch commit dated October 22, 2026 or later (UTC), and show evidence of coding-agent use.

Agent evidence is a file named `AGENTS.md`, `SKILLS.md`, `SKILL.md`, or `CLAUDE.md` anywhere on the default branch (case-insensitive), or a recognized coding agent recorded as an author, committer, or co-author in its latest 100 commits. The evidence column links to the file or commit.

{{data}}

### Refreshing the ranking

The **Update README** workflow runs every Monday at 13:37 UTC. To refresh the ranking on demand, open **Actions → Update README → Run workflow** and select the default branch. The workflow uses the built-in GitHub token by default. If it hits the API rate limit, set the optional `RANKING_GITHUB_TOKEN` Actions secret to a token with public repository read access.

To regenerate locally with Ruby, set `GITHUB_TOKEN` in your environment and run `ruby parse.rb`.

### Credits

This project builds on [ozh/top_100_PHP_projects](https://github.com/ozh/top_100_PHP_projects), whose original Ruby script was generated with GitHub Copilot and inspired by [EvanLi/Github-Ranking](https://github.com/EvanLi/Github-Ranking).

### License

[MIT License](LICENSE)
