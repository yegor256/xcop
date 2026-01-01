# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'differ'
require 'rainbow'
require_relative 'version'

# One document.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2017-2026 Yegor Bugayenko
# License:: MIT
class Xcop::Document
  # Ctor.
  # +path+:: Path of it
  def initialize(path)
    @path = path
  end

  # Return the difference, if any (empty string if everything is clean).
  def diff(nocolor: false)
    xml = Nokogiri::XML(File.open(@path), &:noblanks)
    ideal = xml.to_xml(indent: 2)
    now = File.read(@path)
    differ(ideal, now, nocolor: nocolor)
  end

  # Fixes the document.
  def fix
    xml = Nokogiri::XML(File.open(@path), &:noblanks)
    ideal = xml.to_xml(indent: 2)
    File.write(@path, ideal)
  end

  private

  def differ(ideal, fact, nocolor: false)
    return '' if ideal == fact
    if nocolor
      Differ.diff_by_line(ideal, fact).to_s
    else
      Differ.format = :color
      Differ.diff_by_line(schars(ideal), schars(fact)).to_s
    end
  end

  def schars(text)
    text.gsub("\n", "\\n\n")
  end
end
