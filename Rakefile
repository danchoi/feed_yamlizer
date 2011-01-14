require 'rake'
require 'rake/testtask'
require 'bundler'
Bundler::GemHelper.install_tasks

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

desc "git push and rake release bumped version"
task :bumped do
  puts `git push && rake release`
  Rake::Task["web"].execute
end

desc "Run tests"
task :test do 
  $:.unshift File.expand_path("test")
  require 'test_helper'
  Dir.chdir("test") do 
    Dir['*_test.rb'].each do |x|
      puts "requiring #{x}"
      require x
    end
  end
  MiniTest::Unit.autorun
end

task :default => :test

