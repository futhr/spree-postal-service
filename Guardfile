group :red_green_refactor, halt_on_fail: true do

  guard 'rspec', cmd: 'bundle exec rspec' do
    watch('spec/spec_helper.rb')    { 'spec' }
    watch(%r{^spec/(.+)_spec\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^lib/(.+)\.rb$})       { |m| "spec/#{m[1]}_spec.rb" }
  end

  guard :rubocop, all_on_start: false, cli: ['--format', 'clang', '--rails'] do
    watch(%r{.+\.rb$})
    watch(%r{(?:.+/)?\.(rubocop|hound)\.yml$}) { |m| File.dirname(m[0]) }
  end
end
