Feature: The user can successfully clear completed tasks.

  Background:
  Given I clear all cookies
  And I visit the homepage

  @live
  Scenario: The user can clear completed tasks.

  When I click the checkbox
    And I clear all completed tasks
  Then I should not see completed tasks
