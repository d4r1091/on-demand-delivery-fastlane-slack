## Jenkins + Slackbot setup

This little and easy to follow guide will help us installing Jenkins + all its settings needed


Install Jenkins through [Homebrew](https://brew.sh) (recommended) [Source: Fastlane doc](https://docs.fastlane.tools/best-practices/continuous-integration/jenkins/#jenkins-integration)
  - open your terminal and paste `brew update && brew install jenkins`
  - after installing it, please go ahead installing the following plugins:
    - [Strict Crumb Issuer](https://plugins.jenkins.io/strict-crumb-issuer)
    - [AnsiColor](https://plugins.jenkins.io/ansicolor)
    - [Build Name and Description Setter](https://plugins.jenkins.io/build-name-setter)
    - [Rebuilder](https://plugins.jenkins.io/rebuild)

Follow the Jenkins installation running `jenkins` and finalize it.

After doing so, restart Jenkins and make sure the following configuration is setup go to:
- Manage Jenkins
  - Configure Global Security
    - CSRF Protection (setup as shown below)

![](/res/jenkins_crumb_check.png)

- Setup MacOS to run `jenkins` automatically at startup via [brewed-jenkins](https://github.com/fastlane/brewed-jenkins)
- [Create a Bot](Slack-Configuration.md) and get a Slack WebHook
- Our Slackbot using [Corebot](https://github.com/outofcoffee/corebot)
  - you can either try their [cloud based solution](https://www.remotebot.io)
    - free plan 20 monthly deployments - not recommended

### Store GITHUB credentials in Jenkins

#### Generating a ssh-key

- Go on the Mac machine in which Jenkins is installed
- open the terminal
- Generate a valid SSH Key via terminal pasting `ssh-keygen -t rsa -b 4096 -C "YOUR_GITHUB_EMAIL"`
- the terminal will print... `> Generating public/private rsa key pair.`
- When you're prompted to "Enter a file in which to save the key," press Enter. It will save the generated key into the default file location.
- At the second and third prompt, type a secure passphrase if necessary

Now you have got a new valid ssh-key. Let's add it as Github deploy keys.

To do so...
- move onto your repository page on Github.
- from your repository, click Settings.
- in the sidebar, click **Deploy Keys**
- then click **Add deploy key**
- open the terminal
- paste `pbcopy < ~/.ssh/id_rsa.pub`
- provide a title, paste in your public key just gotten from the command above
- Select **Allow write access** if you want this key to have write access to the repository. A deploy key with write access lets a deployment push to the repository.
- Click **Add key**

[Step-by-step modified version of the Github guide](https://developer.github.com/v3/guides/managing-deploy-keys/#setup-2)

#### Adding the ssh-key to Jenkins

- Go on the Mac machine in which Jenkins is installed
- open the terminal
- paste `pbcopy < ~/.ssh/id_rsa`
- hit Enter
- Move onto your Jenkins on web browser
- on the left side menu go to _Credentials_
- then click on sub item _System_
- on the main window click on _Global credentials (unrestricted)_
- on the left side then click on _Add _Credentials_
- follow as screenshot below

![](/res/adding_slackbot_user.png)

The pipeline below will use the `github` credentials stored as result of this process to checkout the code.

### Create a Pipeline JOB

Let's create our Pipeline Jenkins JOB and call it `ios_build_demo`

![](/res/ios_build_demo_pipeline.png)

- give it a description if you like
  - _Awesome Jenkins pipeline example_ cause why not 🤷
- copy the content of the below pipeline in the Job's pipeline's section
- make sure to replace `[YOUR_GITHUB_URL]` with your current Github project
- define default Environment Variables for the Pipeline as shown below

![](/res/pipeline_job_parameters.png)

### Pipeline

Replace YOUR_GITHUB_URL with your SSH enabled URL.

> i.e. git@github.com:[COMPANY/ORG/USERNAME]/[REPO_NAME].git

The below is a 4 stages Pipeline

- Setup ruby
  - setup the ruby environment
- Checkout
  - executes a `git checkout` for the specified `BRANCH_NAME`
- Check bundles
  - executes a `bundle install` of the necessary gems defined if the Gemfile.lock
- Build
  - executes the fastlane lane `deliver_build` defined within the Fastfile

```
node {

  def iosenv=[
    'TERM=xterm-256color',
    'LANG=en_US.UTF-8',
    'LANGUAGE=en_US.UTF-8',
    'LC_ALL=en_US.UTF-8',
    'RUBY_VERSION=2.6.3'
  ]

  withEnv(iosenv) {

      stage ('Setup ruby') {
        sh """
        export PATH=$PATH:/usr/local/bin:$HOME/.rbenv/bin:$HOME/.rbenv/shims
        eval "\$(rbenv init -)"
        rbenv global $RUBY_VERSION
        """
      }

      stage ('Checkout') {
        ansiColor('xterm'){
          echo "Checking out ${BRANCH_NAME}"
          checkout([$class: 'GitSCM',
                    branches: [[name: "${BRANCH_NAME}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'CleanBeforeCheckout'],
                                 [$class: 'SubmoduleOption',
                                  disableSubmodules: false,
                                  recursiveSubmodules: true,
                                  reference: '',
                                  trackingSubmodules: false]],
                    submoduleCfg: [],
                    userRemoteConfigs: [[credentialsId: 'github',
                                        url: '[YOUR_GITHUB_URL]']]])
      }
    }

    stage ('Check bundles') {
      ansiColor('xterm'){
        sh """
        export PATH=$PATH:/usr/local/bin:$HOME/.rbenv/bin:$HOME/.rbenv/shims
        bundle install
        """
      }
    }

    stage ('Build') {
      ansiColor('xterm'){
        sh """
        export PATH=$PATH:/usr/local/bin:$HOME/.rbenv/bin:$HOME/.rbenv/shims
        bundle exec fastlane deliver_build --verbose
        """
      }
    }

  }
}
```
