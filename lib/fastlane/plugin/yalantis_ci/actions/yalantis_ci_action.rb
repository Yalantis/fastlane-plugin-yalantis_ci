require 'fastlane/action'
require_relative '../helper/yalantis_ci_helper'

module Fastlane
  module Actions
    class YalantisCiAction < Action
      def self.run(params)
        UI.message("The yalantis_ci plugin is working!")
      end

      def self.description
        "Set of utilities and useful actions to help setup CI for Yalantis projects"
      end

      def self.authors
        ["Dima Vorona"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "This plugin provides tools that setup Firebase, setup proper match repo branch name based on the project Unique ID (based on Team ID and a project name), syncs AppStore Connect API keys, kbridges cocoapod keys plugin to sync and share keys, stored in an encrypted repo just as Match does"
      end

      def self.available_options
        [
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "YALANTIS_CI_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
