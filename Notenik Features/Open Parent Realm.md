Title:  Open Parent Realm

Date:   17 May 2019

Status: 4 - In Work

Seq:    42

Body: 

Started the implementation of functionality to allow a user to Open a Parent Realm. 

This will replace the Master Collection functionality. 

When the user opens a Parent Realm, Notenik looks for all Notenik Collections within the specified folder, and then builds a dynamic, transient Collection allowing the user to launch the link to immediately open any collection within the list. 

Since the parent realm collection includes only collections within the folder that the user has already selected, this avoids any permission problems that would otherwise occur with sandboxing of the app. 
