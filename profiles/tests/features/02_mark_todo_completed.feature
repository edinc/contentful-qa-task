Feature: The user can successfully mark a todo as completed.

  Background:
  Given I clear all cookies
  And I visit the homepage

  @live
  Scenario: The user can mark a task as completed.

  When I add another task
  Then I should see the task on the list

  When I click the checkbox
  Then I should see the task as completed
