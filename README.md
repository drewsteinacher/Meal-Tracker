# Meal-Tracker
An open-source meal tracker made in [Wolfram Language](https://www.wolfram.com/language/) and hosted in the [Wolfram Cloud](http://www.wolfram.com/cloud/).

## Features
* Easy Food entry via natural language, codes (UPCs, PLUs, USDA NDB numbers), and barcode images
* Custom food and meal logging and editing
* History visualizations (radar plots, time series, gauges)
* Meal recommendations to meet nutrition targets

## Requirements
* A Wolfram Engine product (e.g. [Wolfram|One](http://www.wolfram.com/wolfram-one/) or [Mathematica](http://www.wolfram.com/mathematica/))
* A [Wolfram ID](https://account.wolfram.com/auth/create) and account for the [Wolfram Cloud](https://www.wolfram.com/cloud/)

## Deployment
Deployment to the cloud can be done with some simple code (edit the `CloudObject` path as needed):
```Mathematica
Get["MealTrackerApp.wl"]
DeployMealTrackerApp[CloudObject["YourMealTrackerPath"], "DefaultDirectory" -> Automatic]
```