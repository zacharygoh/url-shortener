# frozen_string_literal: true

# Run Tailwind build before asset precompile so production/Heroku get tailwind.css
if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance do
    Rake::Task["tailwindcss:build"].invoke if Rake::Task.task_defined?("tailwindcss:build")
  end
end
