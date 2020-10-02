// Configure
show_swelling = true;
show_coalescing = true;
show_bursting = true;
show_shrinking = true;
show_partialtrack = true;
show_oscillating = true;
show_noise = true;


// Create image
newImage("stack_thresholded", "8-bit black", 256, 256, 4);

// Create organoids (thresholded)

	// 1. Normal swelling
	if(show_swelling){
		makeOval(22, 19, 50, 50);
		for(i=1; i<=4; i++){
			setSlice(i);
			run("Enlarge...", "enlarge=3");
			run("Set...", "value=255 slice");
			if(i==4){
				run("Select None");
			}
		}
	}
		
	// 2. Coalescing
	if(show_coalescing){
		makeOval(18, 175, 43, 43);
		for(i=1; i<=4; i++){
			setSlice(i);
			run("Enlarge...", "enlarge=3");
			run("Set...", "value=255 slice");
			if(i==4){
				run("Select None");
			}
		}
		makeOval(70, 196, 43, 43);
		for(i=1; i<=4; i++){
			setSlice(i);
			run("Enlarge...", "enlarge=3");
			run("Set...", "value=255 slice");
			if(i==4){
				run("Select None");
			}
		}
	}
	
	// 3. Bursting: merge/split
	if(show_bursting){
		makeOval(135, 117, 39, 39);
		for(i=1; i<=4; i++){
			setSlice(i);
			if(i<4){
				run("Enlarge...", "enlarge=5");
				run("Set...", "value=255 slice");
			} else {
				run("Enlarge...", "enlarge=-10");
				run("Set...", "value=255 slice");
				run("Select None");
			}
		}
		makeOval(179, 148, 39, 39);
		for(i=1; i<=4; i++){
			setSlice(i);
			if(i<4){
				run("Enlarge...", "enlarge=5");
				run("Set...", "value=255 slice");
			} else {
				run("Enlarge...", "enlarge=-10");
				run("Set...", "value=255 slice");
				run("Select None");
			}
		}
	}


	// 4. Shrinking
	if(show_shrinking){
		makeOval(52, 99, 43, 43);
		for(i=1; i<=4; i++){
			setSlice(i);
			run("Enlarge...", "enlarge=-3");
			run("Set...", "value=255 slice");
			if(i==4){
				run("Select None");
			}
		}
	}

	
	// 5. Partially tracked
	if(show_partialtrack){
		makeOval(137, 34, 4, 4);
		for(i=2; i<=4; i++){
			setSlice(i);
			run("Enlarge...", "enlarge=3");
			run("Set...", "value=255 slice");
			if(i==4){
				run("Select None");
			}
		}
	}


	// 6. Osclillating
	if(show_oscillating){
		makeOval(184, 214, 10, 10);
		for(i=2; i<=3; i++){
			setSlice(i);
			run("Enlarge...", "enlarge=3");
			run("Set...", "value=255 slice");
			if(i==3){
				run("Select None");
			}
		}
	}

	// 7. Noise
	if(show_noise){
		makeOval(214, 88, 10, 10);
		for(i=3; i<=3; i++){
			setSlice(i);
			run("Enlarge...", "enlarge=1");
			run("Set...", "value=255 slice");
			run("Select None");
		}
	}

	
setSlice(1);



// Label organoids
run("Duplicate...", "title=stack_labels duplicate");
run("16-bit");
run("glasbey_on_dark");

	// 1. Normal swelling [label 1]
	if(show_swelling){
		for(i=1; i<=4; i++){
			setSlice(i);
			doWand(46, 42);
			run("Set...", "value=1 slice");
		}
	}

	// 2. Coalescing [label 5+6]
	if(show_coalescing){
		for(i=1; i<=4; i++){
			setSlice(i);
			doWand(39, 196);
			run("Set...", "value=5 slice");
		}
		for(i=1; i<=2; i++){
			setSlice(i);
			doWand(94, 215);
			run("Set...", "value=6 slice");
		}
	}

	// 3. Bursting: merge/split [label 3+4]
	if(show_bursting){
		for(i=1; i<=4; i++){
			setSlice(i);
			doWand(154, 135);
			run("Set...", "value=3 slice");
		}
		for(i=1; i<=4; i=i+3){
			setSlice(i);
			doWand(200, 169);
			run("Set...", "value=4 slice");
		}
	}

	// 4. Shrinking [label 2]
	if(show_shrinking){
		for(i=1; i<=4; i++){
			setSlice(i);
			doWand(75, 120);
			run("Set...", "value=2 slice");
		}
	}
	
	// 5. Partially tracked [label 7]
	if(show_partialtrack){
		for(i=2; i<=4; i++){
			setSlice(i);
			doWand(138, 36);
			run("Set...", "value=7 slice");
		}
	}


	// 6. Osclillating [label 8]
	if(show_oscillating){
		for(i=2; i<=3; i++){
			setSlice(i);
			doWand(189, 220);
			run("Set...", "value=8 slice");
		}
	}

	// 7. Noise [label 9]
	if(show_noise){
		for(i=3; i<=3; i++){
			setSlice(i);
			doWand(218, 94);
			run("Set...", "value=9 slice");
		}
	}


setSlice(1);
run("Select None");
