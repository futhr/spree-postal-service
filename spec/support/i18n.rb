require 'rspec'
require 'i18n-spec'

RSpec.configure do |config|

  config.before(:suite) do
    I18n.locale = :en
  end
end
