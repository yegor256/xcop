# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'differ'
require 'rainbow'
require_relative 'version'
require_relative 'document'

# Command line interface.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2025 Yegor Bugayenko
# License:: MIT
class Xcop::CLI
  def initialize(files, nocolor: false)
    @files = files
    @nocolor = nocolor
  end

  def run
    @files.each do |f|
      doc = Xcop::Document.new(f)
      diff = doc.diff(nocolor: @nocolor)
      unless diff.empty?
        puts diff
        raise "Invalid XML formatting in #{f}"
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
