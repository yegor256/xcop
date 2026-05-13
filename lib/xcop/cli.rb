# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'differ'
require 'rainbow'
require_relative 'version'
require_relative 'document'

# Command line interface.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class Xcop::CLI
  # Extensions recognized when a directory is passed as input.
  EXTENSIONS = %w[xml xsd xhtml xsl html].freeze

  def initialize(files, nocolor: false)
    @files = files.flat_map { |f| File.directory?(f) ? Xcop::CLI.expand(f) : [f] }
    @nocolor = nocolor
  end

  # Recursively collect XML-like files inside a directory.
  def self.expand(dir)
    EXTENSIONS.flat_map { |ext| Dir.glob(File.join(dir, '**', "*.#{ext}")) }.sort
  end

  def run
    @files.each do |f|
      doc = Xcop::Document.new(f)
      diff = doc.diff(nocolor: @nocolor)
      unless diff.empty?
        puts diff
        raise "Invalid XML formatting in #{f}"
      end
      errors = doc.validate
      unless errors.empty?
        puts errors.join("\n")
        raise "XSD validation failed in #{f}"
      end
      yield(f) if block_given?
    end
  end

  # Fix them all.
  def fix
    @files.each do |f|
      Xcop::Document.new(f).fix
      yield(f) if block_given?
    end
  end
end
