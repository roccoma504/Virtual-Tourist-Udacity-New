[![Build Status](https://travis-ci.org/roccoma504/Virtual-Tourist-Udacity-4.svg)](https://travis-ci.org/roccoma504/Virtual-Tourist-Udacity-4) [![codecov.io](https://codecov.io/github/roccoma504/Virtual-Tourist-Udacity-4/coverage.svg?branch=master)](https://codecov.io/github/roccoma504/Virtual-Tourist-Udacity-4?branch=master)

# Virtual-Tourist-Udacity-4

## Introduction

This repo is project #4 for Udacitys iOS NanaDegree program. This project focuses on Core Data and the Flickr API. This project also uses Travis-CI and CodeCov.

## Requirements

Requirements for the project can be found [here] (https://docs.google.com/document/d/1j-UIi1jJGuNWKoEjEk09wwYf4ebefnwcVrUYbiHh1MI/pub?embedded=true)

## Usage

### MapView

The first view is a map view that allows the user to drop a pin. The user can drop as many pins as they want. Each pin and the corresponding data is saved into Core Data for later retrieval.

### CollectionView

When the user clicks on a pin, a collectionview is formed with images from Flickr based on the location from the pin that the user selected. URLs for the images are stored in Core Data.
