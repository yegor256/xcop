# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
Feature: Command Line Processing
  As an author of XML I want to be able to
  call XCOP as a command line tool

  Scenario: Help can be printed
    When I run bin/xcop with "-h"
    Then Exit code is zero
    And Stdout contains "--help"

  Scenario: Version can be printed
    When I run bin/xcop with "--version"
    Then Exit code is zero

  Scenario: Validating correct XML file
    Given I have a "test.xml" file with content:
    """
    <?xml version="1.0"?>
    <hello>Hello, world!</hello>

    """
    When I run bin/xcop with "test.xml"
    Then Stdout contains "test.xml looks good"
    And Exit code is zero

  Scenario: Validating incorrect XML file
    Given I have a "abc.xml" file with content:
    """
    <a><b>something</b>
    </a>
    """
    When I run bin/xcop with "abc.xml"
    Then Exit code is not zero

  Scenario: Fixing incorrect XML file
    Given I have a "broken.xml" file with content:
    """
    <a><b>something</b>
    </a>
    """
    When I run bin/xcop with "--fix broken.xml"
    Then Exit code is zero
    Then I run bin/xcop with "broken.xml"
    Then Exit code is zero

  Scenario: Validating all files in the current directory by default
    Given I have a "auto.xml" file with content:
    """
    <?xml version="1.0"?>
    <hello>Hello, world!</hello>

    """
    And I have a "nested/deep.xsl" file with content:
    """
    <?xml version="1.0"?>
    <hello>Hello, world!</hello>

    """
    When I run bin/xcop with ""
    Then Stdout contains "auto.xml looks good"
    And Stdout contains "deep.xsl looks good"
    And Exit code is zero

  Scenario: Validating a directory of XML files recursively
    Given I have a "pkg/top.xml" file with content:
    """
    <?xml version="1.0"?>
    <hello>Hello, world!</hello>

    """
    And I have a "pkg/nested/deep.xsl" file with content:
    """
    <?xml version="1.0"?>
    <hello>Hello, world!</hello>

    """
    When I run bin/xcop with "pkg"
    Then Stdout contains "top.xml looks good"
    And Stdout contains "deep.xsl looks good"
    And Exit code is zero
