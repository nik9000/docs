# frozen_string_literal: true

require 'fileutils'

require_relative 'sh'

##
# Helper class for setting up source files for tests.
class Repo
  include Sh

  attr_reader :name, :root

  def initialize(name, root)
    @name = name
    @root = root
  end

  ##
  # Write a source file and return the absolute path to that file.
  def write(source_relative_path, text)
    realpath = path source_relative_path
    dir = File.expand_path '..', realpath
    FileUtils.mkdir_p dir
    File.open(realpath, 'w:UTF-8') do |f|
      f.write text
    end
    realpath
  end

  ##
  # Transform path fragment for a source file into the path that that file
  # should have.
  def path(source_relative_path)
    File.expand_path(source_relative_path, @root)
  end

  ##
  # Commit all changes to the repo.
  def commit(message)
    Dir.chdir @root do
      sh 'git add .'
      sh "git commit -m '#{message}'"
    end
  end

  ##
  # Initialize the repo and commit all files in it and add an Elastic remote
  # so we get a nice edit url when we build the docs.
  def init
    Dir.chdir @root do
      sh 'git init'
      commit 'init'
      sh 'git remote add elastic git@github.com:elastic/docs.git'
    end
  end
end
