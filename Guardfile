guard 'rspec', cmd: 'bundle exec rspec', all_on_start: true, all_after_pass: true do
  watch('spec/spec_helper.rb')    { 'spec' }
  watch(%r{^spec/(.+)_spec\.rb$}) { |m| "spec/#{m[1]}_spec.rb"}
  watch(%r{^lib/(.+)\.rb$})       { |m| "spec/#{m[1]}_spec.rb" }
end
