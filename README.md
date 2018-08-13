# Meal-Tracker
An open-source meal tracker made in [Wolfram Language](https://www.wolfram.com/language/) and hosted in the [Wolfram Cloud](http://www.wolfram.com/cloud/).

![Home page](https://raw.githubusercontent.com/drewsteinacher/Meal-Tracker/master/Screenshots/HomePage.PNG)

## Features
* Easy Food entry via natural language, codes (UPCs, PLUs, USDA NDB numbers), and barcode images
* Custom food and meal logging and editing
* History visualizations (radar plots, time series, gauges)
* Meal recommendations to meet nutrition targets

## Requirements
* A Wolfram Engine product (e.g. [Wolfram|One](http://www.wolfram.com/wolfram-one/) or [Mathematica](http://www.wolfram.com/mathematica/))
* A [Wolfram ID](https://account.wolfram.com/auth/create) and account for the [Wolfram Cloud](https://www.wolfram.com/cloud/)

## Initial Setup
Deployment to the cloud can be done with some simple code (edit the `CloudObject` path and `Databin` for your needs):
```Mathematica
Get["MealTrackerApp.wl"]
DeployMealTrackerApp[CloudObject["MealTracker/YourNameHere"], "HistoryDatabin" -> Databin["YourDatabinIDGoesHere"]]
```

Check out the [deployment notebook](https://github.com/drewsteinacher/Meal-Tracker/blob/master/Setup.nb) for more information.

## Custom Data Analysis
Have a look at the example [custom data analysis notebook](https://github.com/drewsteinacher/Meal-Tracker/blob/master/DataAnalysis.nb) for ideas and useful code.

## Development, Questions and How to Contribute
Feel free to fork this repo and/or make issues and pull requests!

The [development notebook](https://github.com/drewsteinacher/Meal-Tracker/blob/master/Develop.nb) has information and code examples for
* Running the test suites (deployment, specific sub packages, etc...)
* Redeploying updated code and `EntityStore`s
