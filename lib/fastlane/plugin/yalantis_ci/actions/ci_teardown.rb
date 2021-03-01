module Fastlane
  module Actions
    class CiTeardownAction < Action
      def self.run(params)
        if !Helper.ci? 
          UI.important("Not executed by Continuous Integration system")
          return
        end

        other_action.delete_keychain if File.exist?(ENV['KEYCHAIN_PATH'])
      end

	  def self.authors
        ["Dima Vorona", "Yalantis"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
  	end
  end
end
