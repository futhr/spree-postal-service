module SpreePostalService

  # Returns the version of the currently loaded SpreePostalService as a
  # <tt>Gem::Version</tt>.
  def self.version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    MAJOR = 3
    MINOR = 3
    TINY  = 0
    PRE   = 'alpha'

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end
end
