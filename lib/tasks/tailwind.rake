# frozen_string_literal: true

# Run Tailwind build before asset precompile so production/Heroku get tailwind.css
if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance ["tailwindcss:build"] if Rake::Task.task_defined?("tailwindcss:build")
end
