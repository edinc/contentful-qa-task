require 'singleton'

class Homepage < AbstractPageObject
  include Singleton

  def add_task
    find('.new-todo').set("Task1")
    find(".new-todo").set("\n")
  end

  def add_another_task
    find('.new-todo').set("Task2")
    find(".new-todo").set("\n")
  end

  def verify_task
    page.should have_css "[type='checkbox']"
  end

  def complete_task
    first('.toggle').click
  end

  def verify_completed_task
    page.should have_css ".completed"
  end

  def remove_task
    find('.destroy').click
  end

  def verify_task
    page.should_not have_css ".completed"
  end

end

module HomepagePageModule
  def homepage
    Homepage.instance
  end
end

World(HomepagePageModule)
