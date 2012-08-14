require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'rake/packagetask'
require 'rubygems/package_task'

rdoc_opts = ["--main", "README", "--exclude", "unit_tests/"]
files = ["test_link_update.rb", "test_link_api.rb", "test_link_rspec.rb", "README", "config.yaml"]
desc "Default: run unit tests"
task :default => :test

Rake::TestTask.new(:test) do |t|
  t.pattern = "unit_tests/tc_*.rb"
  t.verbose = true
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README"
  rdoc.rdoc_files = files
end

update_spec = Gem::Specification.new do |spec|
  spec.author = "Bob Saveland"
  spec.email = "savelandr@aol.com"
  spec.platform = Gem::Platform::RUBY
  spec.description = "Test::Unit::TestCase and RSpec integration with TestLink test case tool"
  spec.summary = "TestLink module for Test::Unit and RSpec"
  spec.name = "test_link_update"
  spec.version = "1.4.0"
  spec.requirements << 'Test/Unit or MiniTest/Unit, or RSpec 2'
  spec.require_path = "."
  spec.extra_rdoc_files = ["README"]
  spec.rdoc_options = rdoc_opts
  spec.files = files
  spec.test_files = Dir.glob('unit_tests/tc_*.rb')
  spec.post_install_message = "Make sure you create a config file in your home directory.  See the rdoc for details"
end

Gem::PackageTask.new(update_spec) do |spec|
end
