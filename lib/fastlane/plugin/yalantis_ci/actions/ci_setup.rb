module Fastlane
  module Actions
    module SharedValues
      CI_UNIQUE_PROJECT_ID = :CI_UNIQUE_PROJECT_ID
    end

    class CiSetupAction < Action
      def self.run(params)
        # Print table
        FastlaneCore::PrintTable.print_values(
          config: params,
          title: "Summary for CI Setup Action"
        )

        id = self.unique_id(params[:project])
        UI.message("Setting CI_UNIQUE_PROJECT_ID to: \"#{id}\"")
        Actions.lane_context[SharedValues::CI_UNIQUE_PROJECT_ID] = id
        ENV['CI_UNIQUE_PROJECT_ID'] = id

        # We want to setup match repo regardless of the environment. 
        # On both local and remote machine this should be set to the same value
        self.setup_match_repo(id)

        if !Helper.ci?
          return
        end

        self.setup_temp_keychain(id)

        # Set output directory
        if params[:output_directory]
          output_directory_path = File.expand_path(params[:output_directory])
          UI.message("Setting output directory path to: \"#{output_directory_path}\".")
          ENV['GYM_BUILD_PATH'] = output_directory_path
          ENV['GYM_OUTPUT_DIRECTORY'] = output_directory_path
          ENV['SCAN_OUTPUT_DIRECTORY'] = output_directory_path
          ENV['BACKUP_XCARCHIVE_DESTINATION'] = output_directory_path

          if params[:archive_name]
            extension = "xcarchive"
            archive_name = File.basename(params[:archive_name], File.extname(params[:archive_name])) + extension
            archive_path = File.join(output_directory_path, params[:archive_name])

            UI.message("Setting archive path to: \"#{output_directory_path}\".")
            ENV['GYM_ARCHIVE_PATH'] = archive_path
          end
        end

        # Set derived data
        if params[:derived_data_path]
          derived_data_path = File.expand_path(params[:derived_data_path])
          UI.message("Setting derived data path to: \"#{derived_data_path}\".")
          ENV['DERIVED_DATA_PATH'] = derived_data_path # Used by clear_derived_data.
          ENV['XCODE_DERIVED_DATA_PATH'] = derived_data_path
          ENV['GYM_DERIVED_DATA_PATH'] = derived_data_path
          ENV['SCAN_DERIVED_DATA_PATH'] = derived_data_path
          ENV['FL_CARTHAGE_DERIVED_DATA'] = derived_data_path
          ENV['FL_SLATHER_BUILD_DIRECTORY'] = derived_data_path
        end
      end

      def self.unique_id(project)
        # Ensure that MATCH_GIT_BRANCH is set to a unique name to not commit to the master.
        normalized_xcodeproj = File.basename(project, File.extname(project)).gsub(/[^0-9a-z]/i, '-').downcase
        team_id = CredentialsManager::AppfileConfig.try_fetch_value(:team_id) || ENV['FASTLANE_TEAM_ID']
        
        team_id.empty? ? normalized_xcodeproj : "#{normalized_xcodeproj}-#{team_id}"
      end

      def self.setup_match_repo(branch_name)
        # We need to setup a unique name for Match Repo to not interfere with any other
        # project. Project name includes normalized xcodeproj name and team id.
        # This ensures that same project can use different teams simultaniously.
        UI.message("Setting Match repo branch to: \"#{branch_name}\"")
        ENV['MATCH_GIT_BRANCH'] = branch_name
      end

      def self.setup_temp_keychain(id)
        name = "#{id}-fastlane"
        password = "#{name}-password"
        path = File.expand_path("~/Library/Keychains/#{name}.keychain-db")

        ENV['KEYCHAIN_PASSWORD'] = password
        ENV['KEYCHAIN_PATH'] = path
        ENV['MATCH_KEYCHAIN_NAME'] = name
        ENV['MATCH_KEYCHAIN_PASSWORD'] = password

        # In case job has been cancelled, Fastlane's hooks don't get invoked.
        # It may lead to a keychain creation failures. Therefore we need to wipe-out
        # previous keychain (if exists).
        if File.exist?(ENV['KEYCHAIN_PATH'])
          UI.message("Removing dangling temporary keychain at: \"#{ENV['KEYCHAIN_PATH']}\"")
          other_action.delete_keychain
        end

        UI.message("Setting temporary keychain path to: \"#{path}\"")
        other_action.create_keychain(unlock: true, timeout: false, add_to_search_list: true)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Setup Yalantis-specific settings for CI"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "CI Setup action setups CI-specific variables such as build path, derived data path, etc"
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :derived_data_path,
                                       env_name: "CI_DERIVED_DATA_PATH",
                                       description: "Path to the derived data to be used",
                                       is_string: true,
                                       default_value: "./build/DerivedData"
                                       ),
          FastlaneCore::ConfigItem.new(key: :output_directory,
                                       env_name: "CI_OUTPUT_DIRECTORY",
                                       description: "The directory in which the ipa file should be stored in as well as .xcarchive",
                                       is_string: true,
                                       default_value: "./build"
                                       ),
          FastlaneCore::ConfigItem.new(key: :archive_name,
                                       env_name: "CI_ARCHIVE_NAME",
                                       description: "The name of the .xcarchive to be used. Valid only when :output_directory is passed",
                                       is_string: true,
                                       optional: true
                                       ),
          FastlaneCore::ConfigItem.new(key: :project,
                                       env_name: "XC_PROJECT",
                                       description: "Path to the .xcodeproj to be used or any project-related description. Used during CI_UNIQUE_PROJECT_ID generation",
                                       is_string: true,
                                       optional: false
                                       ),

        ]
      end

      def self.output
        [
          ['CI_UNIQUE_PROJECT_ID', 'A unique project id being used for the match branch name, keychain name, etc']
        ]
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
