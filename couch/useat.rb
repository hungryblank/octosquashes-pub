#useat (microseat) couchdb deploy script
require 'rubygems'
require 'json'
require 'mime/types'
require 'rest_client'

DB_NAME = 'squasher'
DB_URI = "http://127.0.0.1:5984/#{DB_NAME}"

APP_ROOT = File.dirname(__FILE__)
APP_NAME = "default"

class Useat

  def initialize(opts={})
  end

  def uri
    @uri ||= File.join(DB_URI, '_design', APP_NAME)
  end

  def id
    "_design/#{APP_NAME}"
  end

  def shows
    Dir.glob(File.join(APP_ROOT, 'shows', '*.js')).map { |f| Show.new(f) }
  end

  def views
    Dir.glob(File.join(APP_ROOT, 'views', '*')).map { |d| View.new(d) }
  end

  def attachments
    Dir.glob(File.join(APP_ROOT, 'public', '**/*.*')).map { |f| Attachment.new(f) }
  end

  def to_json
    app_hash = {'_id' => id}
    rev = current_revision
    app_hash['_rev'] = rev if rev
    app_hash['shows'] = shows.inject({}) do |shows_hash, show|
      shows_hash[show.name] = show.compile
      shows_hash
    end
    app_hash['views'] = views.inject({}) do |views_hash, view|
      views_hash[view.name] = view.to_hash
      views_hash
    end
    app_hash.to_json
  end

  def update
    puts "deploying #{APP_NAME} on #{uri}"
    puts RestClient.put(uri, to_json)
    puts "attachments:"
    attachments.each { |a| a.upload(self) }
    puts "finished revision => #{current_revision}"
    rescue RestClient::ResourceNotFound
      RestClient.put(DB_URI, '{}')
      update
  end

  def fetch
    RestClient.get(uri)
    rescue RestClient::ResourceNotFound
      nil
  end

  def current_revision
    doc = fetch
    return nil unless doc
    version = JSON.parse(doc)['_rev']
  end

end

class Show

  attr_reader :name

  def initialize(file)
    @file = file
    @name = File.basename(file).sub(/\.js$/, '')
  end

  def template
    Template.new(@name)
  end

  def compile
    content = File.open(@file) { |f| f.read}
    content.gsub!('__template__', template.to_json) if !template.blank?
    content
  end

end

class Template

  def initialize(name)
    @file = File.join(APP_ROOT, 'templates', name) + ".html"
  end

  def blank?
    !File.exists?(@file)
  end

  def to_s
    File.open(@file) { |f| f.read}
  end

  def to_json
    to_s.to_json
  end

end

class View

  attr_reader :name

  def initialize(directory)
    @files = Dir.glob(File.join(directory, '*.js'))
    @name = File.basename(directory)
  end

  def to_hash
    @files.inject({}) do |view_hash, file|
      view_hash[file.split('/').pop.sub('.js', '')] = File.open(file) { |f| f.read }
      view_hash
    end
  end

end

class Attachment

  def initialize(path)
    @path = path
    @uri_path = path.sub('./public', '')
    @mime_type = MIME::Types.of(path).to_a.first.to_s
  end

  def upload(app)
    puts "uploading -> #{@uri_path}"
    response = RestClient.put(app.uri + @uri_path + "?rev=#{app.current_revision}", content, :content_type => @mime_type)
    rescue RestClient::RequestFailed => e
      p e.response.body
  end

  def content
    File.open(@path) { |f| f.read }
  end

end

app = Useat.new
app.update
