module Fastlane
  module Actions
    class InstallBrewDependenciesAction < Action
      def self.run(params)
    	brewfile = File.join(ENV['PWD'], 'Brewfile')
    	sh('brew', 'bundle', '--file', Shellwords.escape(brewfile), '--no-upgrade') if File.exists?(brewfile)
      end

	  def self.authors
        ["Dima Vorona", "Yalantis"]
      end

      def self.is_supported?(platform)
        true
      end
  	end
  end
end
