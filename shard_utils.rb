require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'couchrest', '~> 2.0', require: true
  gem 'thor', require: true
  gem 'jsondiff', require: true
end

class ShardUtils < Thor
  package_name "shard_utils"

  desc "add NODE_NAME", "Add shards to node"
  method_option :all, type: :boolean, desc: 'Apply to all databases'
  method_option :database, type: :string, desc: 'The database to modify'
  method_option :template, required: true, desc: 'The -name you want to use as a template'
  method_option :couch_url, required: true, desc: 'The url of the CouchDB, e.g. http://user:pass@localhost'
  method_option :yes, type: :boolean, desc: 'Do not ask for confirmation'
  def add_node(node_name)
    @node_name = node_name
    ensure_supported_version
    dbs =
      if options[:all]
        all_databases(couch_url)
      else
        [options[:database]].compact
      end

    dbs.each do |db|
      apply_changes(db) do |config|
        create_add_node_changes(db, config)
      end
    end
  end

  desc "remove NODE_NAME", "Remove all shards from the given node"
  method_option :all, type: :boolean, desc: 'Apply to all databases'
  method_option :database, type: :string, desc: 'The database to modify'
  method_option :couch_url, required: true, desc: 'The url of the CouchDB, e.g. http://user:pass@localhost'
  method_option :yes, type: :boolean, desc: 'Do not ask for confirmation'
  def remove_node(node_name)
    @node_name = node_name
    ensure_supported_version
    dbs =
      if options[:all]
        all_databases(couch_url)
      else
        [options[:database]].compact
      end

    dbs.each do |db|
      apply_changes(db) do |config|
        create_remove_node_changes(db, config)
      end
    end
  end

  private

  attr_accessor :node_name

  DEFAULT_PORT = 5984
  ADMIN_PORT = 5986

  def couch_url
    options.fetch(:couch_url)
  end

  def dbs_url_for(db)
    "#{couch_url}:#{ADMIN_PORT}/_dbs/#{db}"
  end

  def ensure_supported_version
    result = CouchRest.get("#{couch_url}:#{DEFAULT_PORT}/")
    version = result.fetch('version')
    raise "Version #{version} not yet supported." unless version.start_with?('2.3')
  end

  def create_add_node_changes(db, current_config)
    changelog = current_config.fetch('changelog')
    relevant = changelog.select do |entry|
      method, _, node = entry
      node == options[:template] && method == 'add'
    end

    unless current_config.fetch('by_node')[node_name].nil?
      say("Database #{db} is already up to date.", :green)
      return
    end

    # TODO: we could probably check that we are not adding more than n shards

    relevant.each do |method, range|
      current_config['changelog'] << [method, range, node_name]
    end

    current_config['by_node'][node_name] = current_config.fetch('by_node').fetch(options[:template])

    current_config.fetch('by_range').transform_values! { |v| v.push(node_name) }
    current_config
  end

  def create_remove_node_changes(db, current_config)
    changelog = current_config.fetch('changelog')
    relevant = changelog.select do |entry|
      _, _, node = entry
      node == node_name && method == 'add'
    end

    if current_config.fetch('by_node')[node_name].nil?
      say("Database #{db} is already up to date.", :green)
      return
    end
    relevant.each do |method, range|
      current_config['changelog'] << ['remove', range, node_name]
    end

    current_config['by_node'].delete(node_name)

    current_config.fetch('by_range').transform_values! {|v| v.reject {|i| i == node_name } }
    current_config
  end

  def apply_changes(db, &block)
    db_doc = CouchRest.get(dbs_url_for(db))
    before = JSON.parse(JSON.generate(db_doc))

    yield db_doc
    diff = JsonDiff.generate(before, db_doc)
    return if diff.empty?
    say(JSON.pretty_generate(diff), :green)

    if options[:yes] || yes?("Applying to #{db}, type 'yes' to confirm", :yellow)
      puts CouchRest.put(dbs_url_for(db), db_doc).inspect
    else
      exit 1
    end
  end

  def all_databases(couch_url)
    suffix = ":#{ADMIN_PORT}/_all_dbs"
    all_shards = CouchRest.get("#{couch_url}#{suffix}")

    result = all_shards.map do |shard_name|
      if shard_name.include?('shards')
        shard_name.split('/').last.split('.').first
      else
        shard_name
      end
    end

    result.uniq.reject { |name| %w[_dbs _nodes].include?(name) }
  end
end

ShardUtils.start