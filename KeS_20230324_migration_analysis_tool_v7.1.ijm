macro "Scratch assay migration analysis" {
	//version	
	programmID = "KeS_migration_analysis_tool_version7.1";
	
//user interface and parameter setting
	dir=getDirectory("Choose a folder with the images that should be analysed...");
	
	Dialog.create("Migration Assay Analysis");
	Dialog.addString("User name:", "KeS", 22);
	Dialog.addString("Name of the experiment:", "experiment 1", 22);
	Dialog.addChoice("Specify the orientation of the wounds.", newArray("horizontal", "vertical"));
	Dialog.addSlider("Specify background intensity.", 0, 255, 50)
	Dialog.addNumber("Specify minimal cell size.", 20);
	Dialog.addSlider("Specify wound detection accuracy.", 0, 10, 8);
	Dialog.addSlider("Specify max deviation of wound from orientation [degrees].", 1, 45, 20);
	Dialog.addNumber("Apply additional blur? (If not, enter 0)", 0);
	Dialog.addMessage("");
	Dialog.addMessage("Are following parameters clearly separated in the image file names?");
	Dialog.addCheckbox("Well identifier and time point (if not, images will be analyzed without timeline-based correction)", true);
	Dialog.addCheckbox("Imaging Channel", true);
	Dialog.show();
	
	//read user input
	userName = Dialog.getString();
	experimentName = Dialog.getString();
	woundOrientation = Dialog.getChoice();
	threshold = Dialog.getNumber();
	particleExclusion = Dialog.getNumber();
	accuracyInput = Dialog.getNumber();
	toleranceNumber = Dialog.getNumber();
	addBlur = Dialog.getNumber();

	timeline = Dialog.getCheckbox();
	channelsSep = Dialog.getCheckbox();
	
	//adjust for false accuracyInput
	if (accuracyInput > 10) {
		accuracyInput = 10;			
	}
	if (accuracyInput < 0) {
		accuracyInput = 0;
	}
	
	//calculate parameters based on user input 
	accuracy = (10-round(accuracyInput))*100;
	deviationLimit = particleExclusion + (2000/accuracy) + 20; //+20 to deal with cytation stitching error
	
	
	//prepare image list
	rawImages=getFileList(dir);
	images=Array.sort(rawImages);

//characterize naming of images
	separator = "";
	wellIdentifier = 0;
	timepointIdentifier = 0;
	channelIdentifier = 0;
	
	if (timeline == true && channelsSep == true) {
		Dialog.create("Characterize image file names");
		Dialog.addString("How are the items in image file names separated?", "_", 3);
		Dialog.show();
		separator = Dialog.getString();

		exampleName = split(images[0], separator);
		exampleString = "";
		itemNumbers = newArray();
		
		for (item = 0; item < exampleName.length; item++) {
			exampleString = exampleString+"("+item+1+") "+exampleName[item]+"\n";
			itemNumbers = Array.concat(itemNumbers,d2s(item+1, 0));
		}

		Dialog.create("Characterize image file names");
		Dialog.addMessage("Based on your input, your image file names are structured as follows:\n"+exampleString);
		Dialog.addChoice("Which item identifies the well?", itemNumbers);
		Dialog.addChoice("Which item identifies the timepoint?", itemNumbers);
		Dialog.addChoice("Which item identifies the imaging channel?", itemNumbers);
		Dialog.show();

		wellIdentifier = parseInt(Dialog.getChoice())-1;
		timepointIdentifier = parseInt(Dialog.getChoice())-1;
		channelIdentifier = parseInt(Dialog.getChoice())-1;
	} else if (timeline == true) {
		Dialog.create("Characterize image file names");
		Dialog.addString("How are the items in image filen names separated?", "_", 3);
		Dialog.show();
		separator = Dialog.getString();

		exampleName = split(images[0], separator);
		exampleString = "";
		itemNumbers = newArray();
		
		for (item = 0; item < exampleName.length; item++) {
			exampleString = exampleString+"("+item+1+") "+exampleName[item]+"\n";
			itemNumbers = Array.concat(itemNumbers,d2s(item+1, 0));
		}

		Dialog.create("Characterize image file names");
		Dialog.addMessage("Based on your input, your image file names are structured as follows:\n"+exampleString);
		Dialog.addChoice("Which item identifies the well?", itemNumbers);
		Dialog.addChoice("Which item identifies the timepoint?", itemNumbers);
		Dialog.show();

		wellIdentifier = parseInt(Dialog.getChoice())-1;
		timepointIdentifier = parseInt(Dialog.getChoice())-1;
	} else if (channelsSep == true) {
		Dialog.create("Characterize image file names");
		Dialog.addString("How are the items in image filen names separated?", "_", 3);
		Dialog.show();
		separator = Dialog.getString();

		exampleName = split(images[0], separator);
		exampleString = "";
		itemNumbers = newArray();
		
		for (item = 0; item < exampleName.length; item++) {
			exampleString = exampleString+"("+item+1+") "+exampleName[item]+"\n";
			itemNumbers = Array.concat(itemNumbers,d2s(item+1, 0));
		}

		Dialog.create("Characterize image file names");
		Dialog.addMessage("Based on your input, your image file names are structured as follows:\n"+exampleString);
		Dialog.addChoice("Which item identifies the imaging channel?", itemNumbers);
		Dialog.show();

		channelIdentifier = parseInt(Dialog.getChoice())-1;
	}

//select input channel and reference timepoint
	imagedChannelsString = "";
	imagedChannels = newArray();
	inputChannel = "";
	subtractChannel = "no";
	imagedTimesString = "";
	imagedTimes = newArray();
	referenceTime = "";
	
	if (channelsSep == true && timeline == true) {
		for (i = 0; i < images.length; i++) {
			ImageName = split(images[i], separator);
			if (indexOf(imagedChannelsString, ImageName[channelIdentifier]+separator) < 0) {
				imagedChannelsString = imagedChannelsString + ImageName[channelIdentifier] + separator;	
			}
			if (indexOf(imagedTimesString, ImageName[timepointIdentifier]+separator) < 0) {
				imagedTimesString = imagedTimesString + ImageName[timepointIdentifier] + separator;	
			}
		}
		imagedChannels = split(imagedChannelsString, separator);
		imagedTimes = split(imagedTimesString, separator);

		//select input channel
		Dialog.create("Select image channel and reference timepoint");
		Dialog.addChoice("Please select an imaging channel that should be analyzed", imagedChannels);
		Dialog.addChoice("Do you want to substract another channel?", Array.concat("no",imagedChannels));
		Dialog.addChoice("Which time point should be used as reference?", imagedTimes);
		Dialog.show();

		inputChannel = Dialog.getChoice();
		subtractChannel = Dialog.getChoice();
		referenceTime = Dialog.getChoice();
	} else if (channelsSep == true) {
		for (i = 0; i < images.length; i++) {
			ImageName = split(images[i], separator);
			if (indexOf(imagedChannelsString, ImageName[channelIdentifier]+separator) < 0) {
				imagedChannelsString = imagedChannelsString + ImageName[channelIdentifier] + separator;	
			}
		}
		imagedChannels = split(imagedChannelsString, separator);

		//select input channel
		Dialog.create("Select image channel and reference timepoint");
		Dialog.addChoice("Please select an imaging channel that should be analyzed", imagedChannels);
		Dialog.show();

		inputChannel = Dialog.getChoice();
	} else if (timeline == true) {
		for (i = 0; i < images.length; i++) {
			ImageName = split(images[i], separator);
			if (indexOf(imagedTimesString, ImageName[timepointIdentifier]+separator) < 0) {
				imagedTimesString = imagedTimesString + ImageName[timepointIdentifier] + separator;	
			}
		}
		imagedTimes = split(imagedTimesString, separator);

		//select input channel
		Dialog.create("Select image channel and reference timepoint");
		Dialog.addChoice("Which time point should be used as reference?", imagedTimes);
		Dialog.show();
		
		referenceTime = Dialog.getChoice();
	}

			
	setBatchMode(true);

//sort times array and put ref time at pos 0
	timelineSequence = "";

	if (timeline == true) {
		imagedTimes = Array.deleteValue(imagedTimes, referenceTime);
		imagedTimes = Array.sort(imagedTimes);
		imagedTimes = Array.concat(referenceTime, imagedTimes);
		for (time = 0; time < imagedTimes.length; time++) {
			timelineSequence = timelineSequence+imagedTimes[time]+",";
		}
	}

	
//create well name text with well names separated by separator + newSeparator and array with well names
	ImageName = 0;
	imageID = 0;
	wells = "";
	
	if (timeline == true) {
		for (i = 0; i < images.length; i++) {
			ImageName = split(images[i], separator);
			if (endsWith(wells, ImageName[wellIdentifier]+separator) == false) {
				wells = wells+ImageName[wellIdentifier]+separator;	
			}
		}
	}
	
	wellArray = split(wells, separator);
	wellArray = Array.sort(wellArray);


	saveDir = getDirectory("Choose a saving destination...");


//state parameters
	//create date string
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	TimeString = "_"+year;
    if (month<9) {
		TimeString = TimeString+"0";
	}
	TimeString = TimeString+month+1;
	if (dayOfMonth<10) {
		TimeString = TimeString+"0";
	}
    TimeString = TimeString+dayOfMonth;

	print("Migration Assay Analysis");
	print("Tool:,"+programmID);
	print("User:,"+userName);
	print("Date:,"+TimeString);
	print("Experiment:,"+experimentName);
	print("Source Images:,"+dir);
	print("Orientation:,"+woundOrientation);
	print("Threshold:,"+threshold);
	print("Exclusion:,"+particleExclusion);
	print("Accuracy:,"+accuracyInput);
	print("Tolerance:,"+toleranceNumber);
	print("Additional Blur:,"+addBlur);

	if (timeline == true && channelsSep == true) {
		print("Separator:,"+separator);
		print("Well identifier:,"+wellIdentifier+1);
		print("Time point identifier:,"+timepointIdentifier+1);
		print("Channel identifier:,"+channelIdentifier+1);
		print("Number of imaged channels:,"+imagedChannels.length);
		print("Input channel:,"+inputChannel);
		print("Subtracted channel:,"+subtractChannel);
		print("Number of imaged time points:,"+imagedTimes.length);
		print("Reference time point:,"+referenceTime);
	} else if (timeline == true) {
		print("Separator:,"+separator);
		print("Well identifier:,"+wellIdentifier+1);
		print("Time point identifier:,"+timepointIdentifier+1);
		print("Number of imaged time points:,"+imagedTimes.length);
		print("Reference time point:,"+referenceTime);
	} else if (channelsSep == true) {
		print("Separator:,"+separator);
		print("Channel identifier:,"+channelIdentifier+1);
		print("Number of imaged channels:,"+imagedChannels.length);
		print("Input channel:,"+inputChannel);
	}

	print("\n\nWound Areas");

//prepare list of analyzed (and subtraction) images
	inputImages = newArray();
	subtractImages = newArray();
	if (imagedChannels.length > 1) {
		for (i = 0; i < images.length; i++) {
			currentImage = split(images[i], separator);
			if (currentImage[channelIdentifier] == inputChannel) {
				inputImages = Array.concat(inputImages, images[i]);
			}
			if (subtractChannel != "no" && currentImage[channelIdentifier] == subtractChannel) {
				subtractImages = Array.concat(subtractImages, images[i]);
			}
		}
	} else {
		inputImages = images;
	}

	
//analyze images individually if no time point or well identifiers	
	if (timeline == false) {
		
		//loop through image list
		for (j = 0; j < inputImages.length; j++) {
			
			showProgress(-(j)/wellArray.length);

			woundAreasOfWell = inputImages[j];
			
			//wound detection restrictions for every rectangle
			woundDetRestrLeft = newArray();
			woundDetRestrRight = newArray();

			//open image
			path=dir+inputImages[j];	
			open(path);
			imageID=getImageID();
			InputDup = "InputDup";
			run("Duplicate...", "title="+InputDup);
			selectImage(imageID);
			close();
			selectWindow(InputDup);
			newName = "Result of "+InputDup;
			rename(newName);
			imageID = getImageID();

			//make scratch appear vertically
			if (woundOrientation == "horizontal") {
				run("Rotate 90 Degrees Left");
			}
				
			//crop rectangle from middle to exclude black borders
			imageWidth = getWidth();
			imageHeight = getHeight();
			croppedHeight = 0.95*imageHeight;
			kmax = floor(croppedHeight*accuracy/2000);
			analyzedHeight = kmax*2000/accuracy;
			ROIy = round((imageHeight-analyzedHeight)/2);
			run("Specify...", "width="+imageWidth+" height="+analyzedHeight+" x=0 y="+ROIy);
			run("Crop");

			//set tolerance for later outlier detection based on analyzed image height
			tolerance = 0.5*analyzedHeight*tan(toleranceNumber*PI/180);
			if (tolerance < deviationLimit) {
				tolerance = deviationLimit;
			}

			
			//prepare restrictions for first image == image borders left and right
			for (q = 0; q < (kmax+1); q++) {
				woundDetRestrLeft = Array.concat(woundDetRestrLeft, 0);
				woundDetRestrRight = Array.concat(woundDetRestrRight, (imageWidth-1));
			}
				
			//modify image for migration analysis
			run("Subtract Background...", "rolling="+particleExclusion*2);
			run("Enhance Contrast", "saturated=0.35");
			run("Apply LUT");
			setOption("ScaleConversions", true);
			run("8-bit");
			if (addBlur > 0) {
				run("Gaussian Blur...", "sigma="+addBlur);
			}
			run("Variance...", "radius="+particleExclusion);

			//arrays to store border coordinates
			leftBCy = newArray();
			leftBCx = newArray();
			rightBCy = newArray();
			rightBCx = newArray();
			
			//draw and measure rectangles for border detection
			for (k = 0; k < kmax; k++) {
				yCoordinate = k*(2000/accuracy);
				screenFrom = woundDetRestrLeft[k] - deviationLimit;
				screenTo = woundDetRestrRight[k] + deviationLimit;
				if (screenFrom < 0) {
					screenFrom = 0;
				}
				if (screenTo >= imageWidth) {
					screenTo = imageWidth-1;
				}
				makeRectangle(0, yCoordinate, imageWidth, 2000/accuracy);
				grayValuesRect = getProfile();
				lowerValues = newArray();
				upperValues = newArray();
				correctedLowerValues = newArray();
				correctedUpperValues = newArray();
				searchingFor = "unknown";
				maxDistance = 0;
				maxDistanceAt = 0;


				//find all left and right edges
				for (l = screenFrom; l < screenTo; l++) {
					if (searchingFor == "unknown") {
						if (grayValuesRect[l] > threshold) {
							searchingFor = "lower";
						} else {
							searchingFor = "upper";
							lowerValues = Array.concat(lowerValues, l);
						}
					} else if (searchingFor == "lower") {
						if (grayValuesRect[l-1] >= threshold && grayValuesRect[l] < threshold) {
							lowerValues = Array.concat(lowerValues, l);
							searchingFor = "upper";
						}
					} else {
						if (grayValuesRect[l] > threshold) {
							upperValues = Array.concat(upperValues, l);
							searchingFor = "lower";
						}
					}
				}

				//check raw values and insert coordinates
				if (lowerValues.length > upperValues.length) {
					upperValues = Array.concat(upperValues, screenTo);
				}
				if (lowerValues.length < 1) {
					woundClosed = (woundDetRestrLeft[k]+woundDetRestrRight[k])/2;
					leftBCx = Array.concat(leftBCx, woundClosed);
					rightBCx = Array.concat(rightBCx, woundClosed);
				} else {
					//correct for particles that should be excluded
					correctedLowerValues = Array.concat(correctedLowerValues,lowerValues[0]);						
					for (r = 0; r < lowerValues.length; r++) {
						if (r < lowerValues.length-1) {
							pointDist = lowerValues[r+1] - upperValues[r];
							if (pointDist > particleExclusion) {
								correctedLowerValues = Array.concat(correctedLowerValues, lowerValues[r+1]);
								correctedUpperValues = Array.concat(correctedUpperValues, upperValues[r]);
							}
						}
						if (r == lowerValues.length-1) {
							correctedUpperValues = Array.concat(correctedUpperValues, upperValues[r]);
						}
					}
					//search for maximal distance between borders to find wound
					for (m = 0; m < correctedLowerValues.length; m++) {
						distance = correctedUpperValues[m]-correctedLowerValues[m];
						if (distance > maxDistance) {
							maxDistance = distance;
							maxDistanceAt = m;
						}
					}
					leftBCx = Array.concat(leftBCx, correctedLowerValues[maxDistanceAt]);
					rightBCx = Array.concat(rightBCx, correctedUpperValues[maxDistanceAt]);
				}
				leftBCy = Array.concat(leftBCy, yCoordinate);
				rightBCy = Array.concat(rightBCy, yCoordinate);
			}
				
			//set thresholds for outlier detection
			//determine median of each border array
			sortedL = newArray();
			sortedR = newArray();
			sortedL = Array.concat(sortedL,leftBCx);
			sortedR = Array.concat(sortedR,rightBCx);		
			Array.sort(sortedL);
			Array.sort(sortedR);				
			medianPos = floor(sortedL.length/2);			
			toleranceLeft = sortedL[medianPos] - tolerance;
			if (toleranceLeft < 0) {
				toleranceLeft = 0;
			}
			toleranceRight = sortedR[medianPos] + tolerance;
			if (toleranceRight >= imageWidth) {
				toleranceRight = imageWidth-1;
			}
				
				
			//check for outliers
			for (n = 0; n < leftBCx.length; n++) {
				if (leftBCx[n] < toleranceLeft || rightBCx[n] > toleranceRight) {
					//recalculate BCx[n]
					yCoordinateNew = n*(2000/accuracy);
					makeRectangle(0, yCoordinateNew, imageWidth, 2000/accuracy);
					grayValuesRectNew = getProfile();
					lowerValuesNew = newArray();
					upperValuesNew = newArray();
					correctedLowerValuesNew = newArray();
					correctedUpperValuesNew = newArray();
					searchingForNew = "unknown";
					maxDistanceNew = 0;
					maxDistanceAtNew = 0;
					for (o = toleranceLeft; o < toleranceRight; o++) {
						if (searchingForNew == "unknown") {
							if (grayValuesRectNew[o] > threshold) {
								searchingForNew = "lower";
							} else {
								searchingForNew = "upper";
								lowerValuesNew = Array.concat(lowerValuesNew, o);
							}
						} else if (searchingForNew == "lower") {
							if (grayValuesRectNew[o-1] >= threshold && grayValuesRectNew[o] < threshold) {
								lowerValuesNew = Array.concat(lowerValuesNew, o);
								searchingForNew = "upper";
							}
						} else {
							if (grayValuesRectNew[o] > threshold) {
								upperValuesNew = Array.concat(upperValuesNew, o);
								searchingForNew = "lower";
							} 
						}
					}

						
					if (lowerValuesNew.length > upperValuesNew.length) {
						upperValuesNew = Array.concat(upperValuesNew, toleranceRight);
					}
					if (lowerValuesNew.length < 1) {
						woundClosedNew = (woundDetRestrLeft[n]+woundDetRestrRight[n])/2;
						leftBCx[n] = woundClosedNew;
						rightBCx[n] = woundClosedNew;
					} else {
						correctedLowerValuesNew = Array.concat(correctedLowerValuesNew,lowerValuesNew[0]);
						for (s= 0; s < lowerValuesNew.length; s++) {
							if (s < lowerValuesNew.length-1) {
								pointDistNew = lowerValuesNew[s+1] - upperValuesNew[s];
								if (pointDistNew > particleExclusion) {
									correctedLowerValuesNew = Array.concat(correctedLowerValuesNew, lowerValuesNew[s+1]);
									correctedUpperValuesNew = Array.concat(correctedUpperValuesNew, upperValuesNew[s]);
								}
							}
							if (s == correctedLowerValuesNew.length-1) {
								correctedUpperValuesNew = Array.concat(correctedUpperValuesNew, upperValuesNew[s]);
							}
						}
						for (p = 0; p < correctedLowerValuesNew.length; p++) {
							distanceNew = correctedUpperValuesNew[p] - correctedLowerValuesNew[p];
							if (distanceNew > maxDistanceNew) {
								maxDistanceNew = distanceNew;
								maxDistanceAtNew = p;
							}
						}
						leftBCx[n] = correctedLowerValuesNew[maxDistanceAtNew];
						rightBCx[n] = correctedUpperValuesNew[maxDistanceAtNew];	
					}
				}
			}

			//sort coordinates for area creation
			for (c = 0; c < leftBCx.length; c++) {
				borderDifference = rightBCx[c] - leftBCx[c];
				if (borderDifference < 2*particleExclusion) {
					if (c == 0) {
						leftBCx[c] = (rightBCx[c+1]+leftBCx[c+1])/2;
						rightBCx[c] = (rightBCx[c+1]+leftBCx[c+1])/2;
					} else if (c == (leftBCx.length-1)) {
						leftBCx[c] = (rightBCx[c-1]+leftBCx[c-1])/2;
						rightBCx[c] = (rightBCx[c-1]+leftBCx[c-1])/2;
					} else {
						leftBCx[c] = (rightBCx[c-1]+leftBCx[c-1]+rightBCx[c+1]+leftBCx[c+1])/4;
						rightBCx[c] = (rightBCx[c-1]+leftBCx[c-1]+rightBCx[c+1]+leftBCx[c+1])/4;
					}
				}
			}
				
			woundDetRestrLeft = leftBCx;
			woundDetRestrRight = rightBCx;
				
			//add last coordinates to draw wound edge to edge
			leftBCy = Array.concat(leftBCy, analyzedHeight-1);
			rightBCy = Array.concat(rightBCy, analyzedHeight-1);
			leftBCx = Array.concat(leftBCx, leftBCx[leftBCx.length-1]);
			rightBCx = Array.concat(rightBCx, rightBCx[rightBCx.length-1]);
				
			totalBCx = Array.concat(leftBCx, Array.reverse(rightBCx));
			Array.getStatistics(totalBCx, min4, max4, mean4, stdDev4);
			totalBCy = Array.concat(leftBCy, Array.reverse(rightBCy));
			//create polygon based on border values
			makeSelection("freehand", totalBCx, totalBCy);
			Overlay.addSelection("red", 10);
			woundArea = getValue("Area");
			run("Flatten");
			woundAreasOfWell = woundAreasOfWell+","+woundArea;
			imageWithOverlay = "Overlay"+InputDup;
			rename(imageWithOverlay);
			selectImage(imageID);
			close();
			selectWindow(imageWithOverlay);
			imageID = getImageID();

			if (isOpen(imageID) == true) {
				//create saving paths and save image
				imageSavingPath = userName+TimeString+"_"+experimentName+"_"+"_migration_analysis_"+inputImages[j];
				saveAs("tiff", saveDir+imageSavingPath);
				run("Close All");
			}

			//write calculated areas for respective well into Log window
			print(woundAreasOfWell);
		}
	} else {
//analyze images if time point and well identifiers are specified
		print("Time,"+timelineSequence);
		
		//iterate through wells
		for (i = 0; i < wellArray.length; i++) {
			showProgress(-(i)/wellArray.length);

			//current well related parameters
			currentWell = wellArray[i];
			kmax = 0;

			//string with areas separated by comma
			woundAreasOfWell = currentWell;

			//wound detection restrictions for every rectangle
			woundDetRestrLeft = newArray();
			woundDetRestrRight = newArray();

			//iterate through time points
			for (time = 0; time < imagedTimes.length; time++) {
				
				//loop through image list
				for (j = 0; j < inputImages.length; j++) {
					currentInputImage = split(inputImages[j], separator);
					//select images of specific well i
					if (currentInputImage[wellIdentifier] == currentWell && currentInputImage[timepointIdentifier] == imagedTimes[time]) {

						//open input image
						path=dir+inputImages[j];	
						open(path);
						imageID=getImageID();
					
						InputDup = "Input"+imagedTimes[time];
						run("Duplicate...", "title="+InputDup);
						selectImage(imageID);
						close();

						//subtract image if necessary
						if (subtractChannel != "no") {
							for (e = 0; e < subtractImages.length; e++) {
								currentSubImage = split(subtractImages[e], separator);
								if (currentSubImage[wellIdentifier] == currentWell && currentSubImage[timepointIdentifier] == imagedTimes[time]) {
									pathSub=dir+subtractImages[e];	
									open(pathSub);
									imageIDsub=getImageID();
									SubDup = "Sub"+imagedTimes[time];
									run("Duplicate...", "title="+SubDup);
									selectImage(imageIDsub);
									close();
								}
							}
							selectWindow(InputDup);
							imageCalculator("Subtract create", InputDup, SubDup);
							selectWindow("Result of "+InputDup);
							selectWindow(InputDup);
							close();
							selectWindow(SubDup);
							close();
							selectWindow("Result of "+InputDup);
							imageID = getImageID();
						} else {
							selectWindow(InputDup);
							newName = "Result of "+InputDup;
							rename(newName);
							imageID = getImageID();
						}
						
						//make scratch appear vertically
						if (woundOrientation == "horizontal") {
							run("Rotate 90 Degrees Left");
						}
				
						//crop rectangle from middle to exclude black borders
						imageWidth = getWidth();
						imageHeight = getHeight();

						//determine analysed height with image height of first image
						if (imagedTimes[time] == referenceTime) {
							croppedHeight = imageHeight - 0.08*imageHeight;
							kmax = floor(croppedHeight*accuracy/2000);
						}

						analyzedHeight = kmax*2000/accuracy;
						ROIy = round((imageHeight-analyzedHeight)/2);
						run("Specify...", "width="+imageWidth+" height="+analyzedHeight+" x=0 y="+ROIy);
						run("Crop");

						//set tolerance for later outlier detection based on analyzed image height
						tolerance = 0.5*analyzedHeight*tan(toleranceNumber*PI/180);
						if (tolerance < deviationLimit) {
							tolerance = deviationLimit;
						}


						//prepare restrictions for first image == image borders left and right
						if (woundDetRestrLeft.length < 1) {
							for (q = 0; q < (kmax+1); q++) {
								woundDetRestrLeft = Array.concat(woundDetRestrLeft, 0);
								woundDetRestrRight = Array.concat(woundDetRestrRight, (imageWidth-1));
							}
						}
				
						//modify image for migration analysis
						run("Subtract Background...", "rolling="+particleExclusion*2);
						run("Enhance Contrast", "saturated=0.35");
						run("Apply LUT");
						setOption("ScaleConversions", true);
						run("8-bit");
						if (addBlur > 0) {
							run("Gaussian Blur...", "sigma="+addBlur);
						}
						run("Variance...", "radius="+particleExclusion);
						
						//arrays to store border coordinates
						leftBCy = newArray();
						leftBCx = newArray();
						rightBCy = newArray();
						rightBCx = newArray();


						//draw and measure rectangles for border detection
						for (k = 0; k < kmax; k++) {
							yCoordinate = k*(2000/accuracy);
							screenFrom = woundDetRestrLeft[k] - deviationLimit;
							screenTo = woundDetRestrRight[k] + deviationLimit;
							if (screenFrom < 0) {
								screenFrom = 0;
							}
							if (screenTo >= imageWidth) {
								screenTo = imageWidth-1;
							}
							makeRectangle(0, yCoordinate, imageWidth, 2000/accuracy);
							grayValuesRect = getProfile();
							lowerValues = newArray();
							upperValues = newArray();
							correctedLowerValues = newArray();
							correctedUpperValues = newArray();
							searchingFor = "unknown";
							maxDistance = 0;
							maxDistanceAt = 0;


							//find all left and right edges
							for (l = screenFrom; l < screenTo; l++) {
								if (searchingFor == "unknown") {
									if (grayValuesRect[l] > threshold) {
										searchingFor = "lower";
									} else {
										searchingFor = "upper";
										lowerValues = Array.concat(lowerValues, l);
									}
								} else if (searchingFor == "lower") {
									if (grayValuesRect[l-1] >= threshold && grayValuesRect[l] < threshold) {
										lowerValues = Array.concat(lowerValues, l);
										searchingFor = "upper";
									}
								} else {
									if (grayValuesRect[l] > threshold) {
										upperValues = Array.concat(upperValues, l);
										searchingFor = "lower";
									}
								}
							}

							//check raw values and insert coordinates
							if (lowerValues.length > upperValues.length) {
								upperValues = Array.concat(upperValues, screenTo);
							}
							if (lowerValues.length < 1) {
								woundClosed = (woundDetRestrLeft[k]+woundDetRestrRight[k])/2;
								leftBCx = Array.concat(leftBCx, woundClosed);
								rightBCx = Array.concat(rightBCx, woundClosed);
							} else {
								//correct for particles that should be excluded
								correctedLowerValues = Array.concat(correctedLowerValues,lowerValues[0]);						
								for (r = 0; r < lowerValues.length; r++) {
									if (r < lowerValues.length-1) {
										pointDist = lowerValues[r+1] - upperValues[r];
										if (pointDist > particleExclusion) {
											correctedLowerValues = Array.concat(correctedLowerValues, lowerValues[r+1]);
											correctedUpperValues = Array.concat(correctedUpperValues, upperValues[r]);
										}
									}
									if (r == lowerValues.length-1) {
										correctedUpperValues = Array.concat(correctedUpperValues, upperValues[r]);
									}
								}
								//search for maximal distance between borders to find wound
								for (m = 0; m < correctedLowerValues.length; m++) {
									distance = correctedUpperValues[m]-correctedLowerValues[m];
									if (distance > maxDistance) {
										maxDistance = distance;
										maxDistanceAt = m;
									}
								}
								leftBCx = Array.concat(leftBCx, correctedLowerValues[maxDistanceAt]);
								rightBCx = Array.concat(rightBCx, correctedUpperValues[maxDistanceAt]);
							}
							leftBCy = Array.concat(leftBCy, yCoordinate);
							rightBCy = Array.concat(rightBCy, yCoordinate);
						}
				
						//set thresholds for outlier detection
						//determine median of each border array
						sortedL = newArray();
						sortedR = newArray();
						sortedL = Array.concat(sortedL,leftBCx);
						sortedR = Array.concat(sortedR,rightBCx);		
						Array.sort(sortedL);
						Array.sort(sortedR);				
						medianPos = floor(sortedL.length/2);			
						toleranceLeft = sortedL[medianPos] - tolerance;
						if (toleranceLeft < 0) {
							toleranceLeft = 0;
						}
						toleranceRight = sortedR[medianPos] + tolerance;
						if (toleranceRight >= imageWidth) {
							toleranceRight = imageWidth-1;
						}
				
				
						//check for outliers
						for (n = 0; n < leftBCx.length; n++) {
							if (leftBCx[n] < toleranceLeft || rightBCx[n] > toleranceRight) {
								//recalculate BCx[n]
								yCoordinateNew = n*(2000/accuracy);
								makeRectangle(0, yCoordinateNew, imageWidth, 2000/accuracy);
								grayValuesRectNew = getProfile();
								lowerValuesNew = newArray();
								upperValuesNew = newArray();
								correctedLowerValuesNew = newArray();
								correctedUpperValuesNew = newArray();
								searchingForNew = "unknown";
								maxDistanceNew = 0;
								maxDistanceAtNew = 0;
								for (o = toleranceLeft; o < toleranceRight; o++) {
									if (searchingForNew == "unknown") {
										if (grayValuesRectNew[o] > threshold) {
											searchingForNew = "lower";
										} else {
											searchingForNew = "upper";
											lowerValuesNew = Array.concat(lowerValuesNew, o);
										}
									} else if (searchingForNew == "lower") {
										if (grayValuesRectNew[o-1] >= threshold && grayValuesRectNew[o] < threshold) {
											lowerValuesNew = Array.concat(lowerValuesNew, o);
											searchingForNew = "upper";
										}
									} else {
										if (grayValuesRectNew[o] > threshold) {
											upperValuesNew = Array.concat(upperValuesNew, o);
											searchingForNew = "lower";
										} 
									}
								}

						
								if (lowerValuesNew.length > upperValuesNew.length) {
									upperValuesNew = Array.concat(upperValuesNew, toleranceRight);
								}
								if (lowerValuesNew.length < 1) {
									woundClosedNew = (woundDetRestrLeft[n]+woundDetRestrRight[n])/2;
									leftBCx[n] = woundClosedNew;
									rightBCx[n] = woundClosedNew;
								} else {
									correctedLowerValuesNew = Array.concat(correctedLowerValuesNew,lowerValuesNew[0]);
									for (s= 0; s < lowerValuesNew.length; s++) {
										if (s < lowerValuesNew.length-1) {
											pointDistNew = lowerValuesNew[s+1] - upperValuesNew[s];
											if (pointDistNew > particleExclusion) {
												correctedLowerValuesNew = Array.concat(correctedLowerValuesNew, lowerValuesNew[s+1]);
												correctedUpperValuesNew = Array.concat(correctedUpperValuesNew, upperValuesNew[s]);
											}
										}
										if (s == correctedLowerValuesNew.length-1) {
											correctedUpperValuesNew = Array.concat(correctedUpperValuesNew, upperValuesNew[s]);
										}
									}
									for (p = 0; p < correctedLowerValuesNew.length; p++) {
										distanceNew = correctedUpperValuesNew[p] - correctedLowerValuesNew[p];
										if (distanceNew > maxDistanceNew) {
											maxDistanceNew = distanceNew;
											maxDistanceAtNew = p;
										}
									}
									leftBCx[n] = correctedLowerValuesNew[maxDistanceAtNew];
									rightBCx[n] = correctedUpperValuesNew[maxDistanceAtNew];	
								}
							}
						}

						//sort coordinates for area creation
						for (c = 0; c < leftBCx.length; c++) {
							borderDifference = rightBCx[c] - leftBCx[c];
							if (borderDifference < 2*particleExclusion) {
								if (c == 0) {
									leftBCx[c] = (rightBCx[c+1]+leftBCx[c+1])/2;
									rightBCx[c] = (rightBCx[c+1]+leftBCx[c+1])/2;
								} else if (c == (leftBCx.length-1)) {
									leftBCx[c] = (rightBCx[c-1]+leftBCx[c-1])/2;
									rightBCx[c] = (rightBCx[c-1]+leftBCx[c-1])/2;
								} else {
									leftBCx[c] = (rightBCx[c-1]+leftBCx[c-1]+rightBCx[c+1]+leftBCx[c+1])/4;
									rightBCx[c] = (rightBCx[c-1]+leftBCx[c-1]+rightBCx[c+1]+leftBCx[c+1])/4;
								}
							}
						}
				
						woundDetRestrLeft = leftBCx;
						woundDetRestrRight = rightBCx;
					
						//add last coordinates to draw wound edge to edge
						leftBCy = Array.concat(leftBCy, analyzedHeight-1);
						rightBCy = Array.concat(rightBCy, analyzedHeight-1);
						leftBCx = Array.concat(leftBCx, leftBCx[leftBCx.length-1]);
						rightBCx = Array.concat(rightBCx, rightBCx[rightBCx.length-1]);
				
						totalBCx = Array.concat(leftBCx, Array.reverse(rightBCx));
						Array.getStatistics(totalBCx, min4, max4, mean4, stdDev4);
						totalBCy = Array.concat(leftBCy, Array.reverse(rightBCy));
						//create polygon based on border values
						makeSelection("freehand", totalBCx, totalBCy);
						Overlay.addSelection("red", 10);
						woundArea = getValue("Area");
						run("Flatten");
						woundAreasOfWell = woundAreasOfWell+","+woundArea;
						imageWithOverlay = "Overlay"+InputDup;
						rename(imageWithOverlay);
						selectImage(imageID);
						close();
						selectWindow(imageWithOverlay);
						imageID = getImageID();					
					}
				}
			}
			//stack and save modified images
			if (isOpen(imageID) == true) {
				//create saving paths
				imageSavingPath = userName+TimeString+"_"+experimentName+"_"+wellArray[i]+"_migration_analysis_"+inputChannel;			
				//create and save stack
				run("Images to Stack", "default");
				saveAs("tiff", saveDir+imageSavingPath);
				run("Close All");
			}
			//write calculated areas for respective well into Log window
			print(woundAreasOfWell);
		}
		
	}
	
	resultsSavingPath = userName+TimeString+"_"+experimentName+"_results_"+inputChannel;
	selectWindow("Log");
	saveAs("txt", saveDir + resultsSavingPath);
	run("Close");
	exit("Migration analysis finished!");
}
