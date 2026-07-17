# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'differ'
require 'nokogiri'
require 'rainbow'
require_relative 'document'
require_relative 'version'

# Command line interface.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class Xcop::CLI
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
        puts(diff)
        raise(StandardError, "Invalid XML formatting in #{f}")
      end
      errors = doc.validate
      unless errors.empty?
        puts(errors.join("\n"))
        raise(StandardError, "XSD validation failed in #{f}")
      end
      yield(f) if block_given?
    end
  end

  # Fix them all. The block, when given, receives the file path and a
  # status symbol that is +:fixed+ when the file was rewritten and
  # +:untouched+ when the file was already canonical.
  def fix
    @files.each do |f|
      status = Xcop::Document.new(f).fix
      yield(f, status) if block_given?
    end
  end
end
