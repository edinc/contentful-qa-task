######## WHN STEPS ########
When(/^add a new task$/) do
  homepage.add_task
end

When(/^add another task$/) do
  homepage.add_another_task
end

When(/^I click the checkbox$/) do
  homepage.complete_task
end

######## WHN STEPS ########

Then(/^I should see the task on the list$/) do
  homepage.verify_task
end

Then(/^I should see the task as completed$/) do
  homepage.verify_completed_task
end
