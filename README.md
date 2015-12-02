# Using the tests

An automation framework using Ruby, Cucumber, Selenium and Capybara.

# Requirements

* curl
* rvm
* ruby
* bundler

# Instalation

Install CURL
```
sudo apt-get install curl
```
Install RVM and Ruby
```
\curl -L https://get.rvm.io | bash -s stable
```
After it is done installing, load rvm. You may first need to exit out of your shell session and start up a new one. In order to work, rvm has some of own dependencies that need to be installed. So, for both dependencies and ruby installation, navigate to:
**~/.rvm/scripts/**
```
rvm requirements
rvm install ruby
```

## gems

Install bundler
```
sudo gem install bundler
```
Now checkout the cucumber project and execute bundle in the project root dir. You need to have access to the contentful-qa-task master branch on GitHub.
```
git clone git@github.com:edinc/contentful-qa-task.git
cd contentful-qa-task
bundle install
```

# Running the tests

For running the tests type:
```
bundle exec cucumber -p todomvc.live.com
```

# Scenarios
* 01_add_todo.feature
* 02_mark_todo_completed.feature
* 03_remove_task.feature
* 04_clear_completed_tasks.feature

# Example
![alt tag](https://dl.dropboxusercontent.com/u/22526332/Screen%20Shot%202015-12-02%20at%2022.34.37.png)
