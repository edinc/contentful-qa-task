######## WHEN STEPS ########
When(/^I add a new task$/) do
  homepage.add_task
end

When(/^I add another task$/) do
  homepage.add_another_task
end

When(/^I click the checkbox$/) do
  homepage.complete_task
end

When(/^I remove a task$/) do
  homepage.remove_task
end

######## THEN STEPS ########

Then(/^I should see the task on the list$/) do
  homepage.verify_task
end

Then(/^I should see the task as completed$/) do
  homepage.verify_completed_task
end

Then(/^I should not see that task anymore$/) do
  homepage.verify_task
end
