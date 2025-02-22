# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT
Feature: Gem Package
  As a source code writer I want to be able to
  package the Gem into .gem file

  Scenario: Gem can be packaged
    Given It is Unix
    Given I have a "execs.rb" file with content:
    """
    #!/usr/bin/env ruby
    require 'rubygems'
    spec = Gem::Specification::load('./spec.rb')
    if spec.executables.empty?
      fail 'no executables: ' + File.read('./spec.rb')
    end
    """
    When I run bash with:
    """
    cd xcop
    gem build xcop.gemspec
    gem specification --ruby xcop-*.gem > ../spec.rb
    cd ..
    ruby execs.rb
    """
    Then Exit code is zero
