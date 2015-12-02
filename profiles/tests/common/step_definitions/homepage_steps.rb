When(/^add a new task$/) do
  homepage.add_task
end

Then(/^I should see the task on the list$/) do
  homepage.verify_task
end
