task :default => [:test]

task :deploy => [:prepare_js, :prepare_css] do
  Dir.chdir('couch')
  ruby "useat.rb"
end

task :prepare_js do
  files = Dir.glob('couch/src/js/*.js').sort
  #`cat #{files.join(' ')} |java -jar yuicompressor-2.4.2.jar --type=js > couch/public/js/squasher-min.js`
  `cat #{files.join(' ')} > couch/public/js/squasher-min.js`
end

task :prepare_css do
  require 'lib/css_gradient.rb'
  require 'erb'
  files = Dir.glob('couch/src/css/*.css').each do |css_file|
    File.open('couch/public/css/' + File.basename(css_file),'w') do |compiled_css|
      compiled_css.write(ERB.new(File.open(css_file, 'rb') { |f| f.read }).result)
    end
  end
end

task :test do
  puts "no tests here"
end

