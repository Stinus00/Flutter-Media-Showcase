# Flutter Media Showcase

A flutter project for viewing video's, images, frames and tickers, managed by the BCM Media Control Center.

## Setup:
  Install flutter using this guide: https://docs.flutter.dev/install
  You might have to reload Visual Studio Code.

  Create a secret.json file in the assets/json folder containing API key, header and link. (Will be changed later)

  Use either "flutter run" and follow the instructions or click on "Start Debugging".

  Now the program should start running based on the schedule in the Media Control Center

## Building executables
  This program has 3 shell scripts which can be used to build the executables.
  You can run these scripts using "sh *script name*.sh" in the project terminal.

  **build-for-web.sh** - Builds the program for web and starts a localhost server on which it runs
  
  **build-universal.sh** - Used to create APK's for Android. Open the zip file in build/app/outputs/bundle/release/ and transfer the APK to your Android device.
  
  **clean-and-build.sh** - Cleans the project and builds for all available platforms.


  **!! PROJECTS CAN ONLY BE BUILD ON THEIR RESPECTIVE PLATFORMS !!** For example: You can't build a Windows application on a MacOS device
