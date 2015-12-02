Feature: The user can successfully add a new todo.

  Background:
  Given I clear all cookies
  And I visit the homepage

  @live
  Scenario: The user can add a new task

  When add a new task
  Then I should see the task on the list
