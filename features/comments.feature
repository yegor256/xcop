# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
Feature: Comment Formatting
  As an author of XML I want XCOP to enforce
  a single canonical layout for XML comments

  Scenario: Messy single-line comment is rejected
    Given I have a "single.xml" file with content:
    """
    <?xml version="1.0"?>
    <a>
      <!--   text   -->
    </a>

    """
    When I run bin/xcop with "single.xml"
    Then Exit code is not zero

  Scenario: Messy single-line comment is fixed
    Given I have a "single.xml" file with content:
    """
    <?xml version="1.0"?>
    <a>
      <!--   text   -->
    </a>

    """
    When I run bin/xcop with "--fix single.xml"
    Then Exit code is zero
    And I run bin/xcop with "single.xml"
    Then Exit code is zero
    And Stdout contains "single.xml looks good"

  Scenario: Over-indented multi-line comment is rejected
    Given I have a "multi.xml" file with content:
    """
    <?xml version="1.0"?>
    <a>
      <!--
          line1
          line2
      -->
    </a>

    """
    When I run bin/xcop with "multi.xml"
    Then Exit code is not zero

  Scenario: Over-indented multi-line comment is fixed
    Given I have a "multi.xml" file with content:
    """
    <?xml version="1.0"?>
    <a>
      <!--
          line1
          line2
      -->
    </a>

    """
    When I run bin/xcop with "--fix multi.xml"
    Then Exit code is zero
    And I run bin/xcop with "multi.xml"
    Then Exit code is zero
    And Stdout contains "multi.xml looks good"
