require 'shellwords'

module Fastlane
  module Actions
    module SharedValues
      FIREBASE_DISTRIBUTION_RELEASES_URL = :FIREBASE_DISTRIBUTION_RELEASES_URL
    end

    class FirebaseDistributionSetupAction < Action
      GOOGLE_APPLICATION_CREDENTIALS = 'GOOGLE_APPLICATION_CREDENTIALS'

      def self.run(params)
        # Print table
        FastlaneCore::PrintTable.print_values(
          config: params,
          title: "Summary for Firebase Distribution Setup"
        )

        cmd = ['xcodebuild', '-showBuildSettings']

        workspace = params[:workspace]
        project = params[:project] || ENV['XC_PROJECT']

        if !workspace.nil? && !workspace.empty? then 
          cmd << "-workspace #{Shellwords.escape(workspace)}" unless workspace.nil? || workspace.empty?
        elsif !project.nil? && !project.empty?
          cmd << "-project #{Shellwords.escape(params[:project])}"
        else 
          UI.error("Both :workspace <#{workspace}> and :project <#{project}> are either empty or not provided. You need to pass at least one of them")
          return
        end
        
        cmd << "-scheme #{Shellwords.escape(params[:scheme])}"

        configuration = params[:configuration]
        cmd << "-configuration #{Shellwords.escape(configuration)}" unless configuration.nil? || configuration.empty?

        prepared_cmd = cmd.compact.join(" ")
        build_settings = `#{prepared_cmd}`

        if build_settings.nil? || build_settings.empty? then
          UI.error("Failed to get Xcode Build Settings after runnning:\n\"#{prepared_cmd}\"")
          return
        end
        
        product_name = build_settings.match(/\b(PRODUCT_NAME\s=\s)(?<value>[\w\d\-\_ ]+)/)[:value]
        if product_name.nil? then
          UI.error("Failed to get a Product Name")
          return
        end

        info_plist_path = File.join(
          params[:xcodebuild_archive] || Actions.lane_context[Actions::SharedValues::XCODEBUILD_ARCHIVE], 
          'Products', 
          'Applications',
           "#{product_name}.app",
           'GoogleService-Info.plist'
        )

        if !File.exist?(info_plist_path) then
          UI.error("No GoogleService-Info.plist has been found in the Project at \"#{info_plist_path}\" Make sure you've added it to the product \"#{product_name}\"")
          return
        end

        firebase_project_id = self.read_plist_value(info_plist_path, 'PROJECT_ID')
        firebase_app_id = self.read_plist_value(info_plist_path, 'GOOGLE_APP_ID')
        bundle_id = self.read_plist_value(info_plist_path, 'BUNDLE_ID')

        UI.message("Firebase Vars: PROJECT_ID = \"#{firebase_project_id}\"; GOOGLE_APP_ID = \"#{firebase_app_id}\"")
        UI.message("Setting FIREBASEAPPDISTRO_APP to \"#{firebase_app_id}\"")
        ENV['FIREBASEAPPDISTRO_APP'] = firebase_app_id

        url = "https://console.firebase.google.com/u/0/project/#{firebase_project_id}/appdistribution/app/ios:#{bundle_id}/releases"
        UI.message("Setting FIREBASE_DISTRIBUTION_RELEASES_URL to \"#{url}\"")
        Actions.lane_context[SharedValues::FIREBASE_DISTRIBUTION_RELEASES_URL] = url

        google_app_credentials = params[:google_application_credentials]
        if !google_app_credentials.nil? && !google_app_credentials.empty? then
          if File.exist?(google_app_credentials) then
            UI.message("#{GOOGLE_APPLICATION_CREDENTIALS} has been set to \"#{google_app_credentials}\"")
            ENV[GOOGLE_APPLICATION_CREDENTIALS] = google_app_credentials
          else
            UI.error("google_application_credentials has been set to \"#{google_app_credentials}\" but no file found at the given path")
          end
          return
        end

        google_application_credentials_dir = params[:google_application_credentials_dir]
        credentials_path = File.join(Dir.pwd, google_application_credentials_dir, "#{firebase_project_id}.json")

        if !File.exist?(credentials_path) then
          UI.error("No Google Application Credentials has been found at \"#{credentials_path}\". Make sure that either have set either :google_application_credentials or :firebase_setup_keys_dir. On a CI Runner ensure that GOOGLE_APPLICATION_CREDENTIALS has been set")
          return
        end        

        UI.message("Setting \"#{GOOGLE_APPLICATION_CREDENTIALS}\" to \"#{credentials_path}\"")
        ENV[GOOGLE_APPLICATION_CREDENTIALS] = credentials_path
      end

      def self.read_plist_value(info_plist_path, key)
        expr = Regexp.new(/(?<=\"\b#{key}\b\"\s\=\>\s)\"(?<value>.+)\"/)
        result = `plutil -p \"#{info_plist_path}\"`.match(expr)
        result.nil? ? '' : result[:value] 
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Setup Yalantis-specific environment for the Firebase Distribution"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "Login to the Firebase using Project's Service Account credentials. Set value for the Firebase Project ID, App ID"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :workspace,
            env_name: 'GYM_WORKSPACE',
            description: 'Path to the workspace file',
            default_value_dynamic: false,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :project,
            env_name: 'GYM_PROJECT',
            description: 'Path to the project file',
            default_value_dynamic: false,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :scheme,
            env_name: 'GYM_SCHEME',
            description: "The project's scheme. Make sure it's marked as `Shared`",
            default_value_dynamic: false,
            optional: false,
          ),
          FastlaneCore::ConfigItem.new(
            key: :configuration,
            env_name: 'GYM_CONFIGURATION',
            description: "The configuration to use when building the app. Defaults to \"Release\"",
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :xcodebuild_archive,
            env_name: 'XCODEBUILD_ARCHIVE',
            description: 'Path to the resulting .xcarchive. Optional if you use the _gym_ or _xcodebuild_ action',
            default_value: Actions.lane_context[SharedValues::XCODEBUILD_ARCHIVE],
            default_value_dynamic: true,
            optional: false,
            verify_block: proc do |value|
              UI.user_error!("firebase_distribution_setup: Couldn't find .xcarchive file at path '#{value}'") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :google_application_credentials_dir,
            env_name: 'GOOGLE_APPLICATION_CREDENTIALS_DIR',
            description: 'Directory for the Google Application Credentials on the local machine. Ignored when `GOOGLE_APPLICATION_CREDENTIALS` has been set',
            default_value: 'google-application-credentials',
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :google_application_credentials,
            env_name: 'GOOGLE_APPLICATION_CREDENTIALS',
            description: 'Custom path for the Google Application Credentials. If not set will be inferred based on the :firebase_setup_keys_dir variable and a Project ID',
            optional: true
          )
        ]
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