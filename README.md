# Emoji-Detector
An iOS app that uses a machine learning model to predict Emojis based off of your facial expression, all right in the Apple Messages app!

This app is available on the iOS App Store! [View App Store preview.](https://itunes.apple.com/us/app/emoji-detector/id1394772831?ls=1&mt=8)

## Features
* Display camera preview to the left to show user real-time input.
* Upon app launch, take a picture to use for determining Emojis.
* Display reload button for the user to use an updated photo for processing.
* Does not contain any Storyboards, and instead was written programatically in Swift.

## ML Model
A list of really cool Core ML models can be found at [Awesome CoreML Models Github](https://github.com/likedan/Awesome-CoreML-Models). This is where I first discovered the model that I used, CNNEmotions. This model was developed by Gil Levi and Tal Hassner. More information can be found at <https://talhassner.github.io/home/publication/2015_ICMI>.

I did consider and try creating my own ML model to go straight from an image to an Emoji classification using [Apple's Turi Create Framework](https://github.com/apple/turicreate). Upon realizing that I might need to label thousands of selfies with Emojis, I decided it might be much more efficient to move on to other projects.

## Room / Ideas for Improvement
* Continuous learning! Not only would this be super sick, but it would likely also greatly increase accuracy of the Emoji suggestions. However, such a feature would need a backend.
* Highlighted facial features in camera preview. Showing tracking lines in the camera preview would make the app appear smarter.
* Live Emoji suggestions. Instead of having to press the reload button to get new Emoji suggestions, the app would automatically update its suggestions.
