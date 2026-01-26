# frozen_string_literal: true

require "net/http"
require "json"
require "openssl"

class LinearClient
  BASE_URL = "https://api.linear.app/graphql"

  class Error < StandardError; end
  class RateLimitError < Error; end

  def initialize(api_key: ENV["LINEAR_API_KEY"])
    @api_key = api_key
    raise Error, "LINEAR_API_KEY is not set" if @api_key.blank?
  end

  # Fetch organization info
  def organization
    query = <<~GRAPHQL
      query {
        organization {
          id name urlKey
        }
      }
    GRAPHQL
    execute(query).dig("organization")
  end

  # Fetch all users
  def users(first: 100, after: nil)
    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        users(first: $first, after: $after) {
          nodes {
            id name email displayName avatarUrl
            admin guest active createdAt
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "users")
  end

  # Fetch all teams
  def teams(first: 100, after: nil)
    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        teams(first: $first, after: $after) {
          nodes {
            id name key description color icon
            issueCount createdAt
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "teams")
  end

  # Fetch workflow states
  def workflow_states(first: 100, after: nil)
    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        workflowStates(first: $first, after: $after) {
          nodes {
            id name color description type position
            team { id }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "workflowStates")
  end

  # Fetch labels
  def labels(first: 200, after: nil)
    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        issueLabels(first: $first, after: $after) {
          nodes {
            id name color description isGroup
            parent { id }
            team { id }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "issueLabels")
  end

  # Fetch projects
  def projects(first: 100, after: nil)
    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        projects(first: $first, after: $after) {
          nodes {
            id name slugId description icon color
            state startDate targetDate progress health
            lead { id }
            teams { nodes { id } }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "projects")
  end

  # Fetch cycles
  def cycles(first: 100, after: nil)
    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        cycles(first: $first, after: $after) {
          nodes {
            id number name description
            startsAt endsAt progress completedAt
            team { id }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "cycles")
  end

  # Fetch issues
  def issues(first: 100, after: nil, updated_after: nil)
    filter = updated_after ? "filter: { updatedAt: { gt: \"#{updated_after.iso8601}\" } }" : ""

    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        issues(first: $first, after: $after, #{filter} orderBy: updatedAt) {
          nodes {
            id identifier number title description
            priority estimate dueDate sortOrder
            createdAt updatedAt startedAt completedAt canceledAt archivedAt
            state { id }
            team { id }
            creator { id }
            assignee { id }
            project { id }
            cycle { id }
            parent { id }
            labels { nodes { id } }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "issues")
  end

  # Fetch comments
  def comments(first: 100, after: nil)
    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        comments(first: $first, after: $after) {
          nodes {
            id body createdAt editedAt
            issue { id }
            user { id }
            parent { id }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "comments")
  end

  # Fetch issue relations
  def issue_relations(first: 100, after: nil)
    query = <<~GRAPHQL
      query($first: Int!, $after: String) {
        issueRelations(first: $first, after: $after) {
          nodes {
            id type
            issue { id }
            relatedIssue { id }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL
    paginate(query, { first: first, after: after }, "issueRelations")
  end

  # Fetch attachments for a specific issue
  def issue_attachments(issue_id)
    query = <<~GRAPHQL
      query($id: String!) {
        issue(id: $id) {
          attachments {
            nodes {
              id title url
            }
          }
        }
      }
    GRAPHQL
    result = execute(query, { id: issue_id })
    result.dig("issue", "attachments", "nodes") || []
  end

  private

  def execute(query, variables = {})
    uri = URI(BASE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 10

    # SSL configuration - skip CRL check which can cause issues with some CA certs
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    store = OpenSSL::X509::Store.new
    store.set_default_paths
    # Disable CRL checking which is causing the issue
    store.flags = OpenSSL::X509::V_FLAG_NO_CHECK_TIME
    http.cert_store = store

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = @api_key

    request.body = { query: query, variables: variables }.to_json

    response = http.request(request)

    case response.code.to_i
    when 200
      data = JSON.parse(response.body)
      if data["errors"]
        raise Error, "GraphQL errors: #{data['errors'].map { |e| e['message'] }.join(', ')}"
      end
      data["data"]
    when 429
      raise RateLimitError, "Rate limited by Linear API"
    else
      raise Error, "HTTP #{response.code}: #{response.body}"
    end
  end

  def paginate(query, variables, root_key)
    Enumerator.new do |yielder|
      cursor = variables[:after]
      loop do
        vars = variables.merge(after: cursor)
        result = execute(query, vars)

        nodes = result.dig(root_key, "nodes") || []
        nodes.each { |node| yielder << node }

        page_info = result.dig(root_key, "pageInfo")
        break unless page_info&.dig("hasNextPage")
        cursor = page_info["endCursor"]
      end
    end
  end
end
