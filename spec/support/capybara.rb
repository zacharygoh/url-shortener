# Configure Capybara for feature specs (type: :feature).
# driven_by is only available for system specs (type: :system), so we set the driver directly.
require 'capybara/rspec'

Capybara.javascript_driver = :selenium_chrome_headless
