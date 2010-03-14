require 'rubygems'
require 'pp'
require 'superfeedr-rb'
require 'restclient'
require 'json'
require 'md5'
require 'ostruct'

class CouchClient

  class << self
    def delete(*args); JSON.parse(RestClient.delete(*args)); end
    def get(*args); JSON.parse(RestClient.get(*args)); end
    def post(*args); JSON.parse(RestClient.post(*args)); end
    def put(*args); JSON.parse(RestClient.put(*args)); end
  end

end

module GitResource

  DB="http://127.0.0.1:5984/squasher"

  attr_reader :id

  def uri
    id ? "#{DB}/#{id}" : DB
  end

  def <<(entry)
    @entries << entry
    save
  end

  def to_hash
    @last_version.merge({'entries' => @entries, 'last_update' => last_update, 'last_update_string' => last_update_string})
  end

  def last_update
    @entries.last.published
  end

  def last_update_string
    @entries.last.published_string
  end

  def to_json
    to_hash.to_json
  end

  def save
    CouchClient.send(save_verb, uri, to_json)
    rescue => e
      File.open(File.join(File.dirname(__FILE__), 'error.log'), 'a') { |f| f.puts("#{Time.now.strftime('%Y%m%d-%H:%M:%S')}\nRESCUED #{e} '#{e.message}'\n#{e.backtrace.join("\n")}") }
  end

  private

  def save_verb
    id ? 'put' : 'post'
  end

end

class Logger

  def self.log(message)
    File.open(File.join(File.dirname(__FILE__), 'error.log'), 'a') do |logfile|
      logfile.puts("#{Time.now.strftime('%Y%m%d-%H:%M:%S')} #{message}")
    end
  end

end

class GithubUser

  include GitResource

  def initialize(username)
    @id = MD5.hexdigest(username)
    @title = username
    @last_version = fetch
    @entries = @last_version['entries'] || []
  end

  def fetch
    CouchClient.get(uri)
    rescue RestClient::ResourceNotFound
    {'title' => @title, 'resource_type' => 'user'}
  end

end

class GithubProject

  include GitResource


  def initialize(author, name)
    @name = name
    @title = "#{author}/#{name}"
    @id = MD5.hexdigest(@title)
    @author = author
    @last_version = fetch
    @entries = @last_version['entries'] || []
  end

  def fetch
    CouchClient.get(uri)
    rescue RestClient::ResourceNotFound
    {'title' => @title, 'author' => @author, 'resource_type' => 'project', 'description' => infos['repository']['description']}
  end

  def infos
    github_api_repo_uri = "http://github.com/api/v2/json/repos/show/#{@title}"
    @infos ||= begin JSON.parse(RestClient.get(github_api_repo_uri))
    rescue => e
      Logger.log("in #{self.inspect}\nRESCUED #{e} '#{e.message}'\n#{e.backtrace.join("\n")}")
      end
      {'repository' => {'description' => ''}}
  end

end

class GithubUrl

  def initialize(url)
    @uri = URI.parse(url)
    rescue URI::InvalidURIError => e
      Logger.log("RESCUED #{e} '#{e.message}'\nurl was #{url}")
      @uri = OpenStruct.new(:host => 'exception', :url => url)
  end

  def resource
    case @uri.host
      when 'github.com'
        author, project = @uri.path.split('/')[1,2]
        return GithubProject.new(author, project) if project
        GithubUser.new(author)
    else
      warn("not implemented resource for host '#{@uri.host}' '#{@uri.inspect}'")
      nil
    end
  end

end

class GithubFeedEntry

  attr_reader :resource, :entry, :published, :published_string

  def initialize(feed_entry)
    @entry = feed_entry
    @published = entry.published.strftime('%s%L').to_i
    @published_string = entry.published.strftime('%Y%m%d%H%M%S').to_i
    @resource = GithubUrl.new(@entry.links.first.href).resource
  end

  def to_hash
    @to_hash ||= {
    :id => entry.id,
    :chunks => entry.chunks,
    :chunk => entry.chunk,
    :title => entry.title,
    :published => published,
    :published_string => published_string,
    :content => entry.content,
    :summary => entry.summary,
    :categories => entry.categories,
    :links => entry.links.map do |link|
      {:href => link.href,
       :rel => link.rel,
       :type => link.type,
       :title => link.title}
    end,
    :authors => entry.authors.map do |author| {
      :name => author.name,
      :email => author.email,
      :uri => author.uri}
    end}
  end

  def to_json
    to_hash.to_json
  end

  def save
    resource << self if resource
  end

end

Superfeedr::Client.connect(ENV['SUPERFEEDR_USER'], ENV['SUPERFEEDR_PWD']) do |client|

  client.feed('http://github.com/timeline.atom') do |status, entries|
    entries.each do |entry|
      GithubFeedEntry.new(entry).save
    end
  end

end
