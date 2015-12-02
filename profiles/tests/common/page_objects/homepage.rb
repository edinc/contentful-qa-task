require 'singleton'

class Homepage < AbstractPageObject
  include Singleton

  def add_task
    find('.new-todo').set("Task1")
    find(".new-todo").set("\n")
  end

  def verify_task
    page.should have_css "[type='checkbox']"
  end

end

module HomepagePageModule
  def homepage
    Homepage.instance
  end
end

World(HomepagePageModule)
