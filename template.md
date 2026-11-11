# Top 100 PHP repositories using coding agents

This list ranks public GitHub repositories by stars. Each repository uses PHP as its primary language and has a default-branch commit dated October 22, 2026 or later (UTC).

Agent evidence is a file named `AGENTS.md`, `SKILLS.md`, `SKILL.md`, or `CLAUDE.md` anywhere on the default branch (case-insensitive), or a recognized coding agent recorded as an author, committer, or co-author in its latest 100 commits. The evidence column links to the file or commit.

{{data}}

### Refreshing the ranking

The **Update README** workflow runs daily at 13:37 UTC and can also run on demand from the Actions tab. It uses the built-in GitHub token by default. Set the optional `RANKING_GITHUB_TOKEN` Actions secret to a token with public repository read access if the run exceeds the built-in token's API quota.

To regenerate locally with Ruby, set `GITHUB_TOKEN` in your environment and run `ruby parse.rb`.

### Inspiration

The original idea comes from [EvanLi/Github-Ranking](https://github.com/EvanLi/Github-Ranking). I wanted to track only PHP projects, and code something from scratch.

### Disclaimer

*Fun fact* : I know literally nothing about Ruby. The [code itself](https://github.com/ozh/top_100_PHP_projects/blob/master/parse.rb) was **100% generated** by [Github Copilot](https://copilot.github.com/).I typed the comments to indicate what I was trying to achieve, and all the code was written by the AI. *All. The. Code*. Isn't it amazing ? 🤩

### License

Do whatever the hell you want with it. I mean, it's not even my code.
