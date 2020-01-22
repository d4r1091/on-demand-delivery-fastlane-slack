<p align="center" >
  <img src="https://repository-images.githubusercontent.com/212916519/1d1ea380-2ffd-11ea-97c3-58fb8fac67dc" width=600 height=auto>
</p>

## Thanks to
- [#PragmaConference](http://pragmaconference.com) 💪🏻🚀#️⃣📱
The following architecture was made up and released open source in occasion of the [#PragmaConf2019](https://twitter.com/pragmamarkorg).
- [ChatOps](https://www.atlassian.com/blog/software-teams/what-is-chatops-adoption-guide) collaboration model

## Purpose

- _Automate_, or better **delegate**, the process of building and delivering *that specific version of your app* to a different source.
- Make your app delivery more **reliable**
- **Save** you **time**, a lot.

### Introduction

Let's provide some context and real use-case scenario this architecture can be applied to.

Imagine having your App to match:
- different theme/style
- specific add-ons
- different settings

The codebase will be the same, apart from some details.

You can come up with many ideas like:
- building up a Framework and import that framework to each specific Xcode Project (or Workspace of course)
- having different *targets* in one Xcode Project (or Workspace of course)

In this example we've chosen the second option, the *targets* one.

This is applicable to any project of any scale (even single-target project).
The example is meant to cover the scenario in which more than an App delivery is involved.

### Tools 🧰

Can be an instance of a Mac Machine _somewhere_ as well as your in-house Mac machine.

### Getting started

In the machine you would like to set-up your architecture...

Make sure you have the latest Xcode command lines tools
Run:
```
xcode-select --install
```

#### Create project and initialize Fastlane

- Create your Xcode project / Move into an existing one
- `cd "~/your_project_folder“` the your project directory
- [Install Fastlane following the official guide](https://docs.fastlane.tools/getting-started/ios/setup)
- Copy the Fastfile from the example
  - [in case you need help/inspiration/more info](https://docs.fastlane.tools/advanced/lanes/)

##### dotenv

To facilitate our work of _mix and match_ we introduced the _.env_ environment as recommended from the [fastlane doc](https://docs.fastlane.tools/best-practices/keys/#dotenv), storing environment that is _target specific_.

Dotenv wants you to make files following its convention, which is **absolutely** the way you should go for if you have one project to maintain. In the case studied and explained in the talk, I've mentioned about different environment, projects, variables, so I had to adapt the **dotenv** loading to be controlled manually.
That's why in the project we'll show how to tailor it having:
- target
  - we will call it **partner** within the `dotenv` structure
- build configuration (development, staging, uat, production)
  - we will call it **environment** within the `dotenv` structure

If you'd like to make your `dotenv` files encrypted, follow [secure_dotenv project](https://github.com/psecio/secure_dotenv)

##### Reminder 🚨: in the example Fasfile is used the manually loaded procedure.

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

- Homebrew
  - open your terminal and paste `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
- Jenkins following its [dedicated doc](docs/Jenkins-setup.md)

_Skip the docker integration below if you've tried the cloud hosted one_

- [Install Docker](https://docs.docker.com/docker-for-mac/install/) in our Machine

In your Xcode Project:

> In oder to deliver ready-to-test builds, we choose Firebase App Distribution as provider of such.

- [Integrate Firebase Crashlytics](https://firebase.google.com/docs/crashlytics/get-started) in your project
- Integrate [Firebase App Distribution](https://firebase.google.com/docs/app-distribution/ios/distribute-fastlane) in your Fastlane solution
  - Two choices here (check the [Delivery doc](docs/Delivery.md) for more info):
    - Have your keys defined as User Defined Settings
    - Have your keys defined at .env level

For further setup and more info follow:

- [Code signing guidelines](docs/Codesign.md)
- [Delivery guidelines](docs/Delivery.md)
