#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'time'

class PhpRanking
  LIMIT = 100
  PAGE_SIZE = 100
  FIRST_ELIGIBLE_COMMIT = Time.utc(2026, 10, 22)
  AGENT_FILES = %w[agents.md skills.md skill.md claude.md].freeze
  AGENT_LOGINS = /\A(?:copilot|copilot-swe-agent|claude|claude-code|openai-codex|codex|devin-ai|cursoragent|cursor-agent)(?:\[bot\])?\z/i
  AGENT_EMAILS = /\A(?:noreply@anthropic\.com|codex@openai\.com|(?:\d+\+)?(?:copilot(?:-swe-agent)?|claude(?:-code)?|openai-codex|codex|devin-ai|cursoragent|cursor-agent)(?:\[bot\])?@users\.noreply\.github\.com)\z/i

  def initialize(token = ENV['GITHUB_TOKEN'])
    @token = token
  end

  def run
    rows = []
    each_candidate do |repo|
      match = evidence(repo)
      next unless match

      rows << row(rows.size + 1, repo, match)
      break if rows.size == LIMIT
    end

    table = [
      '| # | Repository | Description | Stars | Forks | Agent evidence |',
      '|---|------------|-------------|-------|-------|----------------|',
      *rows,
      '',
      "Last update (UTC) — #{Time.now.utc.strftime('%Y-%m-%d %H:%M')}"
    ].join("\n")
    template = File.read(File.join(__dir__, 'template.md'), encoding: 'UTF-8')
    File.write(File.join(__dir__, 'README.md'), template.sub('{{data}}') { table }, encoding: 'UTF-8')
  end

  private

  def each_candidate
    seen = {}
    stars = 'stars:>0'
    loop do
      last_stars = nil
      1.upto(10) do |page|
        results = get('/search/repositories',
                      q: "language:php #{stars} pushed:>=#{FIRST_ELIGIBLE_COMMIT.strftime('%Y-%m-%d')}",
                      sort: 'stars', order: 'desc', per_page: PAGE_SIZE, page: page)
        raise 'GitHub returned incomplete repository search results' if results.fetch('incomplete_results')

        items = results.fetch('items')
        items.each do |repo|
          id = repo.fetch('id')
          next if seen[id]

          seen[id] = true
          yield repo
        end
        return if items.size < PAGE_SIZE || results.fetch('total_count') <= page * PAGE_SIZE

        last_stars = items.last.fetch('stargazers_count')
      end

      # GitHub exposes only the first 1,000 matches per search. Keep the
      # boundary inclusive so repositories tied on stars are still eligible.
      next_range = "stars:1..#{last_stars}"
      raise "GitHub search limit reached for repositories tied at #{last_stars} stars" if next_range == stars

      stars = next_range
    end
  end

  def evidence(repo)
    path = "/repos/#{repo.fetch('full_name')}"
    commits = get("#{path}/commits", per_page: PAGE_SIZE)
    return if commits.nil? || commits.empty?

    active = commits.any? do |commit|
      Time.iso8601(commit.fetch('commit').fetch('committer').fetch('date')) >= FIRST_ELIGIBLE_COMMIT
    end
    return unless active

    agent_commit = commits.find { |commit| agent_commit?(commit) }
    return "[Commit `#{agent_commit.fetch('sha')[0, 7]}`](#{agent_commit.fetch('html_url')})" if agent_commit

    head = commits.first
    tree_sha = head.fetch('commit').fetch('tree').fetch('sha')
    file = agent_file(path, tree_sha)
    return unless file

    encoded_path = file.split('/').map { |part| URI.encode_www_form_component(part).gsub('+', '%20') }.join('/')
    "[`#{markdown_cell(file).gsub('`', '&#96;')}`](#{repo.fetch('html_url')}/blob/#{head.fetch('sha')}/#{encoded_path})"
  end

  def agent_commit?(commit)
    return true if %w[author committer].any? do |role|
      AGENT_LOGINS.match?(commit.dig(role, 'login').to_s) ||
        AGENT_EMAILS.match?(commit.dig('commit', role, 'email').to_s)
    end

    commit.fetch('commit').fetch('message')
          .scan(/^Co-authored-by:[^\r\n]*<([^<>\r\n]+)>[ \t]*\r?$/i)
          .any? { |email,| AGENT_EMAILS.match?(email) }
  end

  def agent_file(repo_path, tree_sha, prefix = '', recursive: true)
    tree_path = "#{repo_path}/git/trees/#{tree_sha}"
    tree = recursive ? get(tree_path, recursive: 1) : get(tree_path)
    entries = tree.fetch('tree')
    match = entries.find do |entry|
      entry.fetch('type') == 'blob' && AGENT_FILES.include?(File.basename(entry.fetch('path')).downcase)
    end
    return prefix + match.fetch('path') if match
    return if recursive && !tree.fetch('truncated')
    return agent_file(repo_path, tree_sha, prefix, recursive: false) if recursive

    raise "GitHub returned a truncated tree for #{repo_path}" if tree.fetch('truncated')

    entries.each do |entry|
      next unless entry.fetch('type') == 'tree'

      match = agent_file(repo_path, entry.fetch('sha'), "#{prefix}#{entry.fetch('path')}/", recursive: false)
      return match if match
    end
    nil
  end

  def row(rank, repo, match)
    "| %03d | [%s](%s) | %s | %d | %d | %s |" % [
      rank, repo.fetch('full_name'), repo.fetch('html_url'), markdown_cell(repo['description']),
      repo.fetch('stargazers_count'), repo.fetch('forks_count'), match
    ]
  end

  def markdown_cell(value)
    value.to_s.gsub(/[\r\n]+/, ' ').gsub('|') { '\\|' }
  end

  def get(path, params = {})
    uri = URI("https://api.github.com#{path}")
    uri.query = URI.encode_www_form(params) unless params.empty?
    headers = { 'Accept' => 'application/vnd.github+json', 'User-Agent' => 'php-agentic-dataset',
                'X-GitHub-Api-Version' => '2022-11-28' }
    headers['Authorization'] = "Bearer #{@token}" unless @token.to_s.empty?

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 60) do |http|
      http.get(uri.request_uri, headers)
    end
    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
    return nil if response.code == '409' && path.end_with?('/commits')

    raise "GitHub API #{response.code} for #{uri.request_uri}: #{response.body}"
  end
end

PhpRanking.new.run if $PROGRAM_NAME == __FILE__
