Title:  Change the way Notes are assigned a primary identifier

Status: 0 - Idea

Body:

Right now every Note has to have a unique title, and the note's title is the basis for forming its filename. 

It would be advantageous to make Notenik more flexible in this regard. 

## Step 1 - Change how ID field is defined

+ Delete enum NoteIDRule
+ Remove idRule from NoteCollection class 
+ Replace with idFieldDef

## Step 1: Change how IDs and Filenames are generated. 



