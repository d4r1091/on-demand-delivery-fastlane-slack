# awesome-pragmaconf-2019 💪🏻🚀#️⃣📱

iOS Deployment - Architecture made up and released open source in occasion of the [#PragmaConf2019](http://pragmaconference.com).

### 🚨This project is being constantly updated🚨

## Getting started

Make sure you have the latest Xcode command lines tools
Run:
```
xcode-select --install
```

### Create project and initialize Fastlane

- Create your Xcode project / Move into an existing one
- `cd "~/your_project_folder“` the your project directory
- [Install Fastlane following the official guide](https://docs.fastlane.tools/getting-started/ios/setup)
- Copy the Fastfile from the example
  - [in case you need help/inspiration/more info](https://docs.fastlane.tools/advanced/lanes/)

### dotenv

Dotenv convention wants you to make files following its convention, which is **absolutely** the way you should go for if you have one project to mantain. In the case studied and explained in the talk, I've mentioned about different environment, projects, variables, so I had to adapt the **dotenv** loading to be controlled manually.
That's why in the project we'll show how to tailor it having:
- targets (partners)
- build configuration (development, staging, uat, production)

If you'd like to make your dotenv files encrypted, follow [secure_dotenv project](https://github.com/psecio/secure_dotenv)

#### Reminder: in the example Fasfile is used the manually loaded procedure.

- Create your dotenv files following the **standard** convention
  - .env (root file)
  - .env.development (development file) .env.staging and so on…

- Create your dotenv files following the **manually loaded** files
  - .env (root file)
  - [partner]-[environment].env (i.e. - partnerA-Staging.env) and so on…

#### Populate .env file

Open the newly created `.env` file and paste this line:

```
ENV_VAR_TEST=Hi there I'm an EVN VAR loaded from the root dotenv file 😁 !
```

#### Testing time 🤞🏽👨🏼‍⚕️

Lets see if our journey is going well, let's try to launch a **fastlane action** from the terminal.
Reminder: you must be in the project directory.

```
bundle exec fastlane test_dotenv
```

That's how the output should look like:

![](/res/testing_dotenv.gif)

## Creating a subsidiary Fastfile

Code separation is always a good practice. We are going to manage our Fastlane's lanes having more or less the same approach.
In the example there are few more Fastfile to be imported.

- BetaDeliveryFastfile: manages the beta delivery through services like Fabric
- PartnerDeliveryFastfile: exsclusively delegated to handle partner facing / production-like releases
- ArchiveFastfile: contains the lane that manages the Archiving process (creates .ipa)
- CodeSignFastfile: manages the process of manually codesign the app processing certificates and provisioning profiles
- AuxiliaryFastfile: contains lane helpers which don't necessarily belong to any of the above

Having the three Fastfiles in our project, by executing the public lane:

```
bundle exec fastlane test_external_fastfile_import
```

In this test we will load the Partner and Beta Delivery Fastfile
The result on your terminal will look like this:

![](/res/testing_external_fastfile_laoding.gif)

## OK! The basic stuff have been setup! 👌

Let's go ahead setting up:

- Jenkins
  - after installing it, please go ahead installing the following plugins:
    - Strict Crumb Issuer Plugin
    - AnsiColor

After doing so, restart Jenkins and make sure this configuration is setup under:
Manage Jenkins -> Configure Global Security -> CSRF Protection

![](/res/jenkins_crumb_check.png)

- Our Slackbot using [Corebot](https://github.com/outofcoffee/corebot)
  - you can either try their cloud based solution (free plan / not recommended)

Skip the docker integration below if you've tried the cloud hosted one

- [Install Docker](https://docs.docker.com/docker-for-mac/install/) in our Machine
- Create Codesigning lanes
- Enrich the BetaDeliveryFastfile
- [Integrate Fabric Crashlytics](https://firebase.google.com/docs/crashlytics/get-started?platform=ios&utm_source=fabric&utm_medium=inline_banner&utm_campaign=fabric_sunset&utm_content=kits_crashlytics) in your project
- Integrate Fabric in your Fastlane solution
  - CRASHLYTICS_APIKEY in your .env file
  - CRASHLYTICS_BUILDSECRET in your .env file

For more info follow:

[Code signing guidelines](Codesign.md)

[Delivery guidelines](Delivery.md)
