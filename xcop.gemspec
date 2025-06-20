# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'English'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/xcop/version'

Gem::Specification.new do |s|
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>= 2.2'
  s.name = 'xcop'
  s.version = Xcop::VERSION
  s.license = 'MIT'
  s.metadata = { 'rubygems_mfa_required' => 'true' }
  s.summary = 'XML Formatting Static Validator'
  s.description = 'Validates XML-like documents for proper formatting'
  s.authors = ['Yegor Bugayenko']
  s.email = 'yegor256@gmail.com'
  s.homepage = 'https://github.com/yegor256/xcop'
  s.files = `git ls-files`.split($RS)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE.txt']
  s.add_dependency 'differ', '~>0.1.2'
  s.add_dependency 'nokogiri', '~>1.8'
  s.add_dependency 'rainbow', '~>3.0'
  s.add_dependency 'slop', '~>4.4'
end
