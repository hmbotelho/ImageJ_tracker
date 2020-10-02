// Initialize
run("Close All");
print("\\Clear");
sourcefolder = "C:/Users/Hugo/Desktop/test_data/simulated";
targetfolder = "C:/Users/Hugo/Desktop/test_data/simulated_out";
allfiles = newArray(sourcefolder + "/AnalyzeParticles--T0000.tif", sourcefolder + "/AnalyzeParticles--T0001.tif", sourcefolder + "/AnalyzeParticles--T0002.tif", sourcefolder + "/AnalyzeParticles--T0003.tif");




trackOrganoidLabels(allfiles, targetfolder, "--tracked");






// ====== FUNCTIONS ================================

function trackOrganoidLabels(files, targetfolder, suffix) { 

	// Initialize
	images_tracked = newArray();	// Image names after tracking
	Ttime = newArray();				// Time values
	ToriginalID = newArray();		// The original labels
	TtrackedID = newArray();		// Label after tracking
	ThistoryROI = newArray();		// The most common label at a ROI in all previous time points
	maxID = 0;						// Keep track of the labels which have already been assigned
	previous_batch_mode = is("Batch Mode");
	setBatchMode(true);
		
	// <<<<<< T=0 >>>>>>>>
	
		open(files[0]);
		img_before = getTitle();
		getDimensions(width, height, channels, slices, frames);
		available_labels = unique_labels();
		maxID = lengthOf(available_labels);

		// Create relabeled image
		img_tracked = basename(files[0]);
		img_tracked = addFileSuffix(img_tracked, "--tracked");
		images_tracked = Array.concat(images_tracked, img_tracked);
		newImage(img_tracked, "16-bit black", width, height, 1);
		setMinAndMax(0, 255);
		run("glasbey_inverted");
		for(ID=1; ID<=lengthOf(available_labels); ID++){
			selectlabel(ID, img_before);
			selectWindow(img_tracked);
			run("Restore Selection");
			run("Set...", "value=" + ID);
			run("Select None");
		}
		close(img_before);

		// Save relabeled image
		selectWindow(img_tracked);
		saveAs("Tiff", targetfolder + "/" + img_tracked);

		// Make all background pixels NaN
		selectWindow(img_tracked);
		run("32-bit");
		changeValues(0, 0, NaN);
		run("glasbey_inverted");

		// Generate dataset
			
			// Time values
			Ttime = newArray(maxID);
			Array.fill(Ttime, 0);

			// The original labels
			ToriginalID = available_labels;
	
			// The final label assigned to the object
			TtrackedID = newArray(maxID);
			for(i=0; i<maxID; i++){
				TtrackedID[i] = i+1;
			}

			// The most common label in that position through time
			ThistoryROI = TtrackedID;
			

	
	// <<<<<< T>=1 >>>>>>>>

		for(t=1; t<lengthOf(files); t++){
			
			open(files[t]);
			img_before = getTitle();										// This is the image coming from 'Analyze Particles'
			available_labels = unique_labels();								// These are the labels contained in the image
			nID = lengthOf(available_labels);


			// Update dataset: time values
			temp_Ttime = newArray(nID);										// These are the values for this time point only
			Array.fill(temp_Ttime, t);
			Ttime = Array.concat(Ttime, temp_Ttime);

	
			// Update dataset: original labels
			temp_ToriginalID = available_labels;							// These are the values for this time point only
			ToriginalID = Array.concat(ToriginalID,temp_ToriginalID);

			
			// Update dataset: the most common label in that position through time
			temp_ThistoryROI = newArray();									// These are the values for this time point only
			for(ID=1; ID<=lengthOf(available_labels); ID++){

				selectlabel(ID, img_before);			// Establish ROI at the most recent time point
				past_IDs = newArray();
				past_IDs_flattened = newArray();
				
				for(t_past=0; t_past<lengthOf(images_tracked); t_past++){
					// Visit the same ROI in the past
					selectWindow(images_tracked[t_past]);
					run("Restore Selection");
					mode = round(getValue("Mode"));
					past_IDs = Array.concat(past_IDs,mode);
				}
				past_IDs_flattened = array_flatten(past_IDs);
				temp_ThistoryROI = Array.concat(temp_ThistoryROI,past_IDs_flattened);
			}
			ThistoryROI = Array.concat(ThistoryROI, temp_ThistoryROI);


			// Determine which label should be assigned to each project in the current time
			temp_TtrackedID = newArray();								// These are the values for this time point only
			for(i=0; i<lengthOf(temp_ThistoryROI); i++){
				new_label_raw = assign_label(temp_ThistoryROI[i], maxID);
				temp_TtrackedID = Array.concat(temp_TtrackedID, new_label_raw);
				
				// Check whether a new label has been assigned
				new_label_num = parseInt(new_label_raw);
				if(new_label_num > maxID){
					maxID = new_label_num;
				}
			}




			// Solve conflicts
			// This is required whenever multiple labels are allowed. e.g.: '3_4'
			// Algorithm:
			//	  - Disregard labels that have already been assigned to other objects in this image
			//    - If there are no labels left, assign a new label
			//    - Take all labels which have not been assigned in this image and select the lowest one
			labels_noconflicts = filterArrayRegex(temp_TtrackedID, "^[0-9]+$");
			for(i=0; i<lengthOf(temp_TtrackedID); i++){
				if(matches(temp_TtrackedID[i], ".*_.*")){
					
					// Process a conflict
					this_conflict_allpossibilities = split(temp_TtrackedID[i],"_");
					Array.sort(this_conflict_allpossibilities);
					this_conflict_allowedpossibilities = this_conflict_allpossibilities;

					for(j=0; j<lengthOf(labels_noconflicts); j++){
						this_conflict_allowedpossibilities = Array.deleteValue(this_conflict_allowedpossibilities, labels_noconflicts[j]);
					}

					if(lengthOf(this_conflict_allowedpossibilities) > 0){
						// There is at least one allowed possibility
						// Assign the lowest of the allowed possibilities
						temp_TtrackedID[i] = this_conflict_allowedpossibilities[0];
					} else{
						// None of the possibilities is allowed. Assign a new label
						maxID = maxID+1;
						temp_TtrackedID[i] = maxID;
					}
				}
			}



			
			TtrackedID = Array.concat(TtrackedID, temp_TtrackedID);
			
			


			// Create relabeled image
			img_tracked = basename(files[t]);
			img_tracked = addFileSuffix(img_tracked, "--tracked");
			images_tracked = Array.concat(images_tracked, img_tracked);
			newImage(img_tracked, "16-bit black", width, height, 1);
			setMinAndMax(0, 255);
			run("glasbey_inverted");
			for(i=0; i<lengthOf(temp_ToriginalID); i++){
				label_before = temp_ToriginalID[i];
				label_after = temp_TtrackedID[i];
				selectlabel(label_before, img_before);
				selectWindow(img_tracked);
				run("Restore Selection");
				run("Set...", "value=" + label_after);
				run("Select None");
			}
			close(img_before);
			
			// Save relabeled image image
			selectWindow(img_tracked);
			saveAs("Tiff", targetfolder + "/" + img_tracked);

			// Keep tracked image open
			// Make all background pixels NaN
			selectWindow(img_tracked);
			run("32-bit");
			changeValues(0, 0, NaN);
			run("glasbey_inverted");
			
		}
		
		
	// Close open images
	for(i=0; i<lengthOf(images_tracked); i++){
		close(images_tracked[i]);
	}
	
	


	// Clean up
	setBatchMode(previous_batch_mode);

	
	
	
	// Return
	newImage("matrix_image", "16-bit black", 3, lengthOf(Ttime), 1);
	for(ii=0; ii<lengthOf(Ttime); ii++){
		setPixel(0, ii, Ttime[ii]);
	}
	for(ii=0; ii<lengthOf(ToriginalID); ii++){
		setPixel(1, ii, ToriginalID[ii]);
	}
	for(ii=0; ii<lengthOf(TtrackedID); ii++){
		setPixel(2, ii, TtrackedID[ii]);
	}
	
}





// Measure the modal value of a ROI in a set of images
// If there are more than one mode, select the lower value
// Requires the paths to image files
// Returns an array whose length is the number of images being analyzed
function ROImode_paths(filepaths){

	result = newArray();
	
	// Check if there is a ROI
	if(Roi.size == 0){
		print("ROI not detected");
		for(i=0; i<lengthOf(filepaths); i++){
			result = Array.concat(result,NaN);
		}
		return result;
	}

	// Scan images
	for(i=0; i<lengthOf(filepaths); i++){
		open(filepaths[i]);
		imgname = getTitle();
		run("Restore Selection");
		result = Array.concat(result, getValue("Mode"));	// If there are multiple modes ImageJ selects the lowest value
		close(imgname);
	}

	return result;
}





// Measure the modal value of a ROI in a set of images
// If there are more than one mode, select the lower value
// Processes open images
// Returns an array whose length is the number of images being analyzed
function ROImode_openimages(imgnames){

	main_img = getTitle();
	result = newArray();
	
	// Check if there is a ROI
	if(Roi.size == 0){
		print("ROI not detected");
		for(i=0; i<lengthOf(imgnames); i++){
			result = Array.concat(result,NaN);
		}
		return result;
	}

	// Scan images
	for(i=0; i<lengthOf(imgnames); i++){
		selectWindow(imgnames[i]);
		run("Restore Selection");
		result = Array.concat(result, getValue("Mode"));	// If there are multiple modes ImageJ selects the lowest value
		run("Select None");
	}
	selectWindow(main_img);
	
	return result;
}





// Select all pixels with a given label in  a given image
function selectlabel(label, imagename){
	selectWindow(imagename);
	setThreshold(label, label);
	run("Create Selection");
	run("glasbey_inverted");
}





// Converts the array '1, 2, 3, 4' into string '1_2_3_4'
function array_flatten(array){

	if(lengthOf(array) == 1){
		return array;
	}
	
	result = "";
	for(i=0; i<lengthOf(array); i++){
		if(i<(lengthOf(array)-1)){
			result = result + array[i] + "_";
		} else{
			result = result + array[i];
		}
	}
	return result;
}





// Finds how many distinct labels there are in the open image
function count_labels(){

	// Check if there is an open image
	if (nImages == 0) {
		return(0);
	}

	// Initialize
	batch_mode = is("Batch Mode");
	setBatchMode(true);
	img_raw = getTitle();
	img_points_binary = "points--" + img_raw;
	img_points_labels = "labels--" + img_raw;
	count = 0;

	// Shrink eack object to a single pixel
	run("Duplicate...", "title=" + img_points_binary);
	setThreshold(1, 65535);
	run("Convert to Mask");
	run("Ultimate Points");
	setThreshold(1, 3255);
	run("Convert to Mask");
	run("Divide...", "value=255");
	imageCalculator("Multiply create", img_raw, img_points_binary);
	rename(img_points_labels);
	close(img_points_binary);
	selectWindow(img_points_labels);

	// Count 
	max_label = getValue("Max");
	for(label=1; label <= max_label; label++){
		setThreshold(label, label);
		run("Create Selection");
		mode = getValue("Mode");
		if(mode > 0){
			count++;
		}
	}
	close(img_points_labels);
	selectWindow(img_raw);
	setBatchMode(batch_mode);

	return count;
}





// Finds how many distinct labels there are in the open image
function unique_labels(){

	result = newArray();

	// Check if there is an open image
	if (nImages == 0) {
		return result;
	}

	// Initialize
	batch_mode = is("Batch Mode");
	setBatchMode(true);
	img_raw = getTitle();
	img_points_binary = "points--" + img_raw;
	img_points_labels = "labels--" + img_raw;
	result = newArray();

	// Shrink eack object to a single pixel
	run("Duplicate...", "title=" + img_points_binary);
	setThreshold(1, 65535);
	run("Convert to Mask");
	run("Ultimate Points");
	setThreshold(1, 3255);
	run("Convert to Mask");
	run("Divide...", "value=255");
	imageCalculator("Multiply create", img_raw, img_points_binary);
	rename(img_points_labels);
	close(img_points_binary);
	selectWindow(img_points_labels);

	// Count 
	max_label = getValue("Max");
	for(label=1; label <= max_label; label++){
		setThreshold(label, label);
		run("Create Selection");
		mode = getValue("Mode");
		if(mode > 0){
			result = Array.concat(result,label);
		}
	}
	close(img_points_labels);
	selectWindow(img_raw);
	setBatchMode(batch_mode);

	return result;
}





// Extracts the filename from a file path.
// Converts 'C:/mydir/images/file.tif' into 'file.tif'
function basename(path){
	path = replace(path, "\\", "/");
	
	regex = "^(?<path>.*)/(?<filename>.*?)$";
	result = replace(path, regex, "${filename}");
	
	return result;
}





// Converts 'filename.xxx' into 'filenamesuffix.xxx'
function addFileSuffix(filename, suffix){
	regex = "^(?<pathBase>.*)\\.(?<extension>.*)$";
	result = replace(filename, regex, "${pathBase}" + suffix + ".${extension}");
	
	return result;
}





// Interprets a sequence of labels and returns the label which should be assigned in the current time point
// The labels are the modes in that ROI in all previous time points
// 'max_label' is the highest label previously assigned
function assign_label(char, max_label){
	history = split(char, "_");

	// No previous labels (i.e. all previous labels are NaN)
	// NaN_NaN_NaN_NaN
	// Assign a new label
	if(array_count(history, NaN) == lengthOf(history)){
		return max_label+1;
	}


	// Same label throughout
	// 4_4_4_4_4
	// Assign same label
	temp = unique(history);
	if(lengthOf(temp) == 1){
		return temp[0];
	}


	// Appears somewhere in the middle of the time lapse
	// NaN_NaN_NaN_7
	// NaN_7_7
	// Assign the same label
	regexNaN = "^(NaN_)+(\\d).*$";			// Match the initial NaNs
	regexNum = "^.*_(?<number>[0-9]+)$";		// Match any numbers. Important: will match 'NaN_7_7' but also 'NaN_7_8'!
	IDs = unique(history);
	if(matches(char, regexNaN) && matches(char, regexNum) && lengthOf(IDs) == 2){
		number = replace(char, regexNum, "${number}");
		number = parseInt(number);
		return number;
	}
		

	// Re-appearance of a previous object
	// NaN_NaN_7_NaN
	// Assign the last known label
	regexNaN = ".*NaN.*";					// Matches NaN
	regexNum = "(?<number>[0-9]++)";		// Matches '_(7)_'
	IDs = unique(history);
	if(matches(char, regexNaN) && lengthOf(IDs) == 2){
		if(IDs[0] == "NaN"){
			result = IDs[1];
		}else{
			result = IDs[1];
		}
		return parseInt(result);
	}
	

	// Variable label
	// NaN_NaN_7_NaN_4_NaN
	// Return a string with possible labels
	past_labels = newArray();
	for(i=0; i<lengthOf(history); i++){
		if(history[i] != "NaN"){
			past_labels = Array.concat(past_labels, history[i]);
		}
	}
	past_labels = unique(past_labels);
	Array.sort(past_labels);

	if(lengthOf(past_labels) > 1){
		result = array_flatten(past_labels);
		return result;
	}
	

	// Otherwise, assign a new label
	return max_label+1;
}





// Counts how many times 'item' shows up in 'array'
function array_count(array, item){
	result = 0;
	item = toString(item);
	
	for(i=0; i<lengthOf(array); i++){
		this_item = array[i];
		this_item = toString(this_item);
		if(item == this_item){
			result++;
		}
	}

	return result;
}





// Eliminate duplicates from an array
function unique(array){

	output = newArray();
	
	for(i=0; i<array.length; i++){

		// Check if 'output' already contains this element
		inoutput = false;
		for(j=0; j<output.length; j++){
			if(array[i] == output[j]){
				inoutput = true;
			}
		}

		if(inoutput == false){
			output = Array.concat(output,array[i]);
		}
		
	}

	return output;
}





// Determines whether a string can be converted to an integer
// returns true/false
function isInteger(char){
	int = parseInt(char);
	float = parseFloat(char);
	
	if(isNaN(int) || isNaN(float)){
		return false;
	}
	
	decimal = float - int;
	if(decimal == 0){
		return true;
	}
	
	return false;
}





// Subsets an array according to a regular expression
function filterArrayRegex(array, regex){
	filteredarray = newArray(0);
	for(i=0; i<array.length; i++){
		if(matches(array[i], regex)){
			filteredarray = Array.concat(filteredarray,array[i]);
		}
	}
	return filteredarray;
}