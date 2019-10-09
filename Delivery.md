## Delivery with Fastlane

As per the intention of this guideline, we'd like to separate internal and client facing builds.
For that, we are going to use Fabric internal beta testing and Testflight externally.

But first, lets archive the build.

### Archiving

The archiving process as interesting as the signing one.
We follow these steps:

- update pods and reinstall
- increment the build number matching the service's build number
- We will also change the app display name beforehand so we can easily identify which env the app is for.
  - i.e. STA-TED (staging version of the TED app)
- finally: ARCHIVE THE BUILD!
- wiping out useless artifacts (temp files created out of this process)
  - this can be avoided by setting the `SAVE_ARCHIVE` env variable to `true`

```

desc 'Build that app!'
private_lane :archive do

  # Install cocoapods
  cocoapods(repo_update: true, use_bundle_exec: true)

  # Increment build number  
  increment_build_number_in_plist(
    xcodeproj: xcodeproj_path,
    build_configuration_name: build_configuration,
    target: scheme_name,
    build_number: ci_build_number # can be your service build number assigned to that job
  )

  appname_prefix = ENV['APPNAME_PREFIX']
  app_display_name = scheme_name

  unless appname_prefix.to_s.empty?
    app_display_name = appname_prefix +'-'+scheme_name
  do

  # Change the Display Name of your app if needed
  update_info_plist(
    plist_path: "#{plist_path}#{scheme_name}-Info.plist",
    display_name: app_display_name
  )

  # Build your app
  gym(scheme: scheme_name,
      include_bitcode: false,
      export_method: export_method,
      export_options: {
        provisioningProfiles: {
          current_app_bundle_identifier => provisioning_profile_name
        }
      },
      configuration: build_configuration,
      codesigning_identity: ENV['CODESIGNING_IDENTITY'],
      output_name: "#{scheme_name}_#{build}.ipa",
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

In this tutorial (as we _talk_ with one Fabric instance only) we will store them into the root .env file

```
desc 'Submits a newly packaged app to to Fabric'
private_lane :submit_to_fabric do

  crashlytics(
    crashlytics_path: './Pods/Crashlytics/submit', # path to your 'Crashlytics.framework'
    api_token: crashlytics_apikey,
    build_secret: crashlytics_buildsecret,
    groups: ENV['CRASHLYTICS_GROUP'],
    debug: true,
    notes: "#{build_configuration} - #{changelog}"
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
