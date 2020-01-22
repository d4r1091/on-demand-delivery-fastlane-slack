## Codesign with Fastlane

Before we start, [here is the documentation](https://docs.fastlane.tools/codesigning/getting-started/#codesigning-concepts) where Fastlane marks a concise point, explaining all the possible ways of the signing process. It is also well explained how to approach at each of them.

### Getting started

The purpose of this guidelines is to make our **manually codesigned** lane working, having full control of the process.
Goal is:

- understanding what we do
- make it working

Make sure you've got exported your Apple Certificates in the .p12 format and replaced it within the .env files appropriately
If your app doesn't support Push Notification, feel free to remove these two from your .env files:

- CERTIFICATE_FILENAME_PUSH
- CERTIFICATE_KEY_PASSWORD_PUSH

### How we authenticate with Apple?

Fastlane provides certain ways to authenticate with Apple and perform operations like:

- validate Certificates
- recreate, download, validate provisioning profile
- upload builds

In order to achieve all the above, we need certain variables to setup.
It's up to us how to store it, either as Jenkins credentials or within _Manage Jenkins -> Configure System_

Please read the info below:

> If the account in place is the Account Holder, hence the 2FA is enabled by default, hence a FASTLANE_SESSION is required.
If the account you'll be using IS NOT the Account Holder, you won't need any FASTLANE_SESSION, as long as the Account is setup with the required permission to access to Certificates and provisioning profiles.

`FASTLANE_USER`: Your App Store Connect / Apple Developer Portal user.

`FASTLANE_PASSWORD`: Your App Store Connect / Apple Developer Portal user password.

`FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`: provided in case you have 2-factor enabled and use pilot or deliver to upload a binary to App Store Connect

`FASTLANE_SESSION`: You need to provide a pregenerated session via `fastlane spaceauth` if you have 2-factor authentication enabled and want to use any actions that communicates with App Store Connect.

In case That's *the one* we are going to work with the most in case of 2FA enabled.
Basically, as we want to _skip_ the 2FA for the Account Holder, we need to the generate a new session.
This session will last for ~30days.

To generate a new session - from machine with Fastlane installed execute:

`fastlane spaceauth -u [APPLE_ID]`

You'll be prompted to input the password if you don't have it stored in your Keychain.
> If you want to store it follow [this fastlane doc](https://docs.fastlane.tools/advanced/other/#adding-credentials)

Then you'll be asked to add the 6 digit code from the 2FA and after that, the session will be printed out as summary.

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
Otherwise we'll search over the developer portal of that partner and recreate it adding all the latest device UDIDs (given the right roles).
The condition whether or not recreate the provisioning profile is checked by the environment variable `RECREATE_PROVISIONING_PROFILE` (default to `true`) at .env level.

```
provisioning_filename_extension = ".mobileprovision"
provisioning_profile_path = ENV['PROVISIONING_PROFILES_PATH']+"/#{provisioning_filename}#{provisioning_filename_extension}"

if File.exist? provisioning_profile_path

  puts "Provisioning profile #{provisioning_filename} found. Going to install and sign the package with it."

  sh "chmod 755 " + ENV['PROVISIONING_PROFILES_INSTALL_SCRIPT_PATH']
  sh "sh " + ENV['PROVISIONING_PROFILES_INSTALL_SCRIPT_PATH'] + " #{provisioning_profile_path}"

  ENV['SIGH_PROFILE_PATH'] = ENV['TO_INSTALL_PROVISIONING_PROFILES_PATH']+"/#{provisioning_filename}#{provisioning_filename_extension}"

else

  puts "No provisioning profiles found at path #{provisioning_profile_path}. Going to search over your developer portal."

  if ENV['RECREATE_PROVISIONING_PROFILE'] == 'true'

    get_provisioning_profile(
      adhoc: export_method=='ad-hoc',
      force: true,
      cert_id: ENV['CERTIFICATE_ID'],
      skip_certificate_verification: true,
      provisioning_name: options[:provisioning_profile_name],
      filename: "#{provisioning_filename}#{provisioning_filename_extension}",
      output_path: ENV['PROVISIONING_PROFILES_PATH'],
      app_identifier: bundle_identifier
    )

  else

    get_provisioning_profile(
      adhoc: export_method=='ad-hoc',
      readonly: true,
      cert_id: ENV['CERTIFICATE_ID'],
      skip_certificate_verification: true,
      provisioning_name: options[:provisioning_profile_name],
      filename: "#{provisioning_filename}#{provisioning_filename_extension}",
      output_path: ENV['PROVISIONING_PROFILES_PATH'],
      app_identifier: bundle_identifier
    )

  end

```

### Certificates Import

Here we will import the certificates stored within the _./developer_files/certs_ folder.
Before that, we'll need to create a temporary keychain and unlock it appropriately.

```
desc 'Creates and unlock a temporary keychain'
private_lane :create_temp_keychain do |options|

  create_keychain(
    name: options[:name],
    password: options[:password],
    default_keychain: false,
    timeout: false
  )

  unlock_keychain( # If the keychain file is located in the standard location `~/Library/Keychains`, then it is sufficient to provide the keychain file name, or file name with its suffix.
    path: options[:name],
    password: options[:password]
  )

end

```

Then, it's time to import those certificates in our machine.

```
private_lane :import_certificates do |options|

  import_certificate(
    certificate_path: ENV['CERTIFICATES_PATH']+"/"+ENV['CERTIFICATE_FILENAME'],
    certificate_password: ENV['CERTIFICATE_KEY_PASSWORD'],
    keychain_name: options[:keychain_name],
    keychain_password: options[:keychain_password],
    log_output: true
  )

  if ENV['CERTIFICATE_FILENAME_PUSH'].to_s.empty? == false &&
     ENV['CERTIFICATE_KEY_PASSWORD_PUSH'].to_s.empty? == false

      import_certificate(
        certificate_path: ENV['CERTIFICATES_PATH']+"/"+ENV['CERTIFICATE_FILENAME_PUSH'],
        certificate_password: ENV['CERTIFICATE_KEY_PASSWORD_PUSH'],
        keychain_name: options[:keychain_name],
        keychain_password: options[:keychain_password],
        log_output: true
      )

  end

end
```
