Feature: The user can successfully remove a todo.

  Background:
  Given I clear all cookies
  And I visit the homepage

  @live
  Scenario: The user can remove a task.

  When I add another task
    And I remove a task
  Then I should not see that task anymore
