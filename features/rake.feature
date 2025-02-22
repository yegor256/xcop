# (The MIT License)
# 
# SPDX-FileCopyrightText: Copyright (c) 2017-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT
Feature: Rake tasks
  As a source code writer I want to be able to
  run Xcop from Rakefile

  Scenario: Xcop can be used in Rakefile
    Given It is Unix
    And I have a "Rakefile" file with content:
    """
    require 'xcop/rake_task'
    Xcop::RakeTask.new(:xcop) do |task|
      task.includes = ['good.xml']
    end
    """
    And I have a "good.xml" file with content:
    """
    <?xml version="1.0"?>
    <hello>Hello, world!</hello>

    """
    When I run bash with "rake xcop"
    Then Exit code is zero
