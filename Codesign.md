## Codesign with Fastlane

Before we start, [here is the documentation](https://docs.fastlane.tools/codesigning/getting-started/#codesigning-concepts) where Fastlane marks a concise point, explaining all the possible ways of the signing process. It is also well explained how to approach at each of them.

### Getting started

The purpose of this guidelines is to make our **manually codesigned** lane working, having full control of the process.
Goal is:

- understanding what we do
- make it working

### Lane explained

```
private_lane :manual_code_sign_app
```

That's our focus.
The lane itself works with all the environment variables we've loaded via the .env files.
Before codesigning, as we want everything being done and checked step by step, let's update the project TEAM_ID

```
update_project_team(
  path: xcodeproj_path,
  teamid: team_id,
  targets: [scheme_name]
)
```

Then lets make sure the bundle identifier is the correct one defined in the .env

> Code of conduct tip: whenever I refer to something with ENV['THAT_SOMETHING'] that means we are using it just there, in any other scenario I make ruby constant.

```
update_app_identifier(
  xcodeproj: xcodeproj_path,
  plist_path: ENV['APP_PLIST_ROOT_PATH'] + "#{scheme_name}-Info.plist",
  app_identifier: current_app_bundle_identifier
)
```

Via its proper action we are going to disable the automatic code signing on our project.

```
disable_automatic_code_signing(
  path: xcodeproj_path,
  targets: [scheme_name],
  bundle_identifier: current_app_bundle_identifier
)
```

The next one is quite interesting. Here is where the real magic happens.
If we have a provisioning profile installed locally, then we'll use it as part of our app the singing process.
Otherwise we'll search over the developer portal of that client and recreate it adding all the latest device UDIDs (given the right roles).
The condition whether or not recreate the provisioning profile is checked by the environment variable `RECREATE_PROVISIONING_PROFILE` (default to `true`) at .env level.

```
provisioning_profile_path = ENV['PROVISIONING_PROFILES_PATH']+"/#{provisioning_filename}#{provisioning_filename_extension}"
provisioning_filename_extension = ".mobileprovision"

if File.exist? provisioning_profile_path

  puts "Provisioning profile #{provisioning_filename} found. Going to install and sign the package with it."

  sh "chmod 755 " + ENV['PROVISIONING_PROFILES_INSTALL_SCRIPT_PATH']
  sh "sh " + ENV['PROVISIONING_PROFILES_INSTALL_SCRIPT_PATH'] + " #{provisioning_profile_path}"

  ENV['SIGH_PROFILE_PATH'] = ENV['TO_INSTALL_PROVISIONING_PROFILES_PATH']+"/#{provisioning_filename}#{provisioning_filename_extension}"

  # sets the project provisoning profile UUID to the mobile provisioning profile obtained from sigh

  update_project_provisioning(
      xcodeproj: xcodeproj_path,
      target_filter: ".*#{scheme_name}.*",
      build_configuration: build_configuration,
      profile: ENV['SIGH_PROFILE_PATH']
  )

elsif

  puts "No provisioning profiles found at path #{provisioning_profile_path}. Going to search over your developer portal."

  sigh(
    adhoc: export_method=='ad-hoc',
    readonly: ENV['RECREATE_PROVISIONING_PROFILE'] == 'false',
    cert_id: ENV['CERTIFICATE_ID'],
    skip_certificate_verification: true,
    provisioning_name: provisioning_profile_name,
    filename: "#{provisioning_filename}#{provisioning_filename_extension}",
    output_path: ENV['PROVISIONING_PROFILES_PATH'],
    app_identifier: current_app_bundle_identifier
  )

end

```

### Certificates Import

Here we will import the certificates stored within the _./developer_files/certs_ folder.
Before that, we'll need to create a temporary keychain and unlock it appropriately.

```
desc 'Creates and unlock a temporary keychain'
private_lane :create_temp_keychain do

  create_keychain(
    name: keychain_name,
    password: keychain_password,
    default_keychain: true,
    timeout: false
  )

  unlock_keychain( # If the keychain file is located in the standard location `~/Library/Keychains`, then it is sufficient to provide the keychain file name, or file name with its suffix.
    path: keychain_name,
    password: keychain_password
  )

end

```

Then, it's time to import those certificates in our machine.

```
private_lane :import_certificates do

  import_certificate(
    certificate_path: ENV['CERTIFICATES_PATH']+"/"+ENV['CERTIFICATE_FILENAME'],
    certificate_password: ENV['CERTIFICATE_KEY_PASSWORD'],
    keychain_name: keychain_name,
    keychain_password: keychain_password,
    log_output: true
  )

  if ENV['CERTIFICATE_FILENAME_PUSH'].to_s.empty? == false &&
     ENV['CERTIFICATE_KEY_PASSWORD_PUSH'].to_s.empty? == false

      import_certificate(
        certificate_path: ENV['CERTIFICATES_PATH']+"/"+ENV['CERTIFICATE_FILENAME_PUSH'],
        certificate_password: ENV['CERTIFICATE_KEY_PASSWORD_PUSH'],
        keychain_name: keychain_name,
        keychain_password: keychain_password,
        log_output: true
      )

  end

end

```
