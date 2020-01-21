## Delivery with Fastlane

As per the intention of this guideline, we'd like to separate internal and partner facing builds.
For that, we are going to use Fabric internal beta testing and [Testflight](https://developer.apple.com/testflight/) externally.

But first, lets archive the build.

### Archiving

The archiving process as interesting as the signing one.
We follow these steps:

- update pods and reinstall
- increment the build number matching the service's build number
- We will also change the app display name beforehand so we can easily identify which env the app is for.
  - i.e. STA-Tictrac (staging version of the Tictrac app)
- finally: ARCHIVE THE BUILD! 📦
- wiping out useless artifacts (temp files created out of this process)
  - this can be avoided by setting the `SAVE_ARCHIVE` env variable to `true`

```

desc 'Build that app!'
private_lane :archive do |options|

  scheme_name = options[:scheme_name]
  build_number = ci_build_number

  # Changing the name adding a prefix
  # i.e.: STA-[PARTNER] meaning: Staging version of one PARTNER
  appname_prefix = ENV['APPNAME_PREFIX']
  app_display_name = scheme_name

  # Change the Display Name of your app if needed
  unless appname_prefix.to_s.empty?
    app_display_name = appname_prefix +'-'+scheme_name
  end

  update_info_plist(
    plist_path: "#{options[:plist_path]}#{scheme_name}-Info.plist",
    display_name: app_display_name,
    xcodeproj: options[:xcodeproj_path]
  )

  # Build your app
  build_ios_app(
    scheme: scheme_name,
    configuration: options[:build_configuration],
    include_bitcode: false,
    export_method: options[:export_method],
    export_options: {
      provisioningProfiles: {
        options[:bundle_identifier] => options[:provisioning_profile_name]
      }
    },
    configuration: options[:build_configuration],
    codesigning_identity: ENV['CODESIGNING_IDENTITY'],
    output_name: "#{scheme_name}_#{build_configuration}_#{build_number}.ipa",
    output_directory: ENV['OUTPUTS_PATH'],
    skip_package_ipa: ENV['SKIP_PACKAGE_IPA']
  )

end

```

### Beta testing delivery

Fabric Crashlytics requires its API KEY and APP SECRET.
You can store those wherever you want:
- env var in Jenkins
- .env file
- User Defined build settings
- Plist file (less secure)

> We were using Crashlytics and Fabric but since the recent decomission we decided to switch over Firebase app distribution. Below you'll find the old deprecated documentation in case you'd like to take a look. We are planning to remove it completely soon.

The `submit_to_firebase` lane handles the Firebase submission given two main parameters:

- Firebase token to authenticate via Session token with Firebase CLI
  - Store a `FIREBASE_TOKEN` environment variable in our Continuous Delivery provider (i.e. Jenkins). Firebase detects it and run the `firebase_app_distribution` getting the token from it. To generate a new token please look at the [Firebase Documentation](https://firebase.google.com/docs/cli/#cli-ci-systems). To generate tokens a Google Account is needed.
- `FIREBASE_APP_ID` identifying the Application ID on Firebase for certain Project. i.e. for `TED` project we have three apps on iOS: `Production` and `Internal` corresponding to two different Firebase App IDs.

```
desc 'Submits a newly packaged app to to Firebase'
private_lane :submit_to_firebase do |options|

  puts "Installing Firebase CLI"
  sh "curl -sL https://firebase.tools | bash"

  # The firebase_cli_path is the default one in which Firebase place the executable
  # it is not a mandatory parameter.
  # However, for some reason, on CircleCI, we need to explicitly specify it

  firebase_app_distribution(
    app: ENV['FIREBASE_APP_ID'],
    firebase_cli_path: "/usr/local/bin/firebase",
    groups: ENV['CRASHLYTICS_GROUP'],
    release_notes: "#{options[:build_configuration]} - #{options[:release_notes]}"
  )

end
```

#### Deprecated Fabric implementation

The `submit_to_fabric` lane can comes without the build settings script (shown below - right before the `crashlytics` Fastlane action) if you setup the crashlytics keys at root .env (info about dotenv [here](./README.md)) level.
In that case, the entire script before the `crashlytics` Fastlane action can be omitted.

```
desc 'Submits a newly packaged app to to Fabric'
private_lane :submit_to_fabric do

  # look for CRASHLITYCS_APIKEY and CRASHLYTICS_BUILDSECRET set into our project Build Settings

  crashlytics_apikey = ''
  crashlytics_buildsecret = ''
  project = Xcodeproj::Project.open("../#{options[:xcodeproj_path]}")
  project.targets.each do |mtarget|
      if mtarget.name == options[:scheme_name]
          mtarget.build_configurations.each do |mbuild|
              if mbuild.name == options[:build_configuration]
                  crashlytics_apikey =  mbuild.build_settings['CRASHLYTICS_APIKEY'].chomp
                  crashlytics_buildsecret =  mbuild.build_settings['CRASHLYTICS_BUILDSECRET'].chomp
              end
          end
      end
  end

  crashlytics(
    crashlytics_path: './Pods/Crashlytics/submit', # path to your 'Crashlytics.framework'
    api_token: crashlytics_apikey,
    build_secret: crashlytics_buildsecret,
    groups: ENV['CRASHLYTICS_GROUP'],
    notes: "#{options[:build_configuration]} - #{options[:release_notes]}"
  )

end
```

### Testflight delivery

```
desc 'Submits a newly packaged app to Testflight'
private_lane upload_testflight do

  # Having skip_waiting_for_build_processing set to _true_
  # won't apply any changelog

  upload_to_testflight ({   
   skip_submission:true,
   skip_waiting_for_build_processing:true,
   distribute_external: false,
   changelog: changelog,
   team_id: ENV['ITUNESCONNECT_TEAM_ID']
  })

end
```
