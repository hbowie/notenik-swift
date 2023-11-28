Title:  Merge Template Back Links

Code:

<!-- Start by setting a global variable 
     to hold the title of the previous page. --> 
<?set prior-page = "" ?>
<!-- Follow this with your nextrec command. -->
<?nextrec?>
<!-- Then, wherever you want the prior-page link to appear, 
    you would want something like the following. -->
<?if "=$prior-page$=" ?>
<p>
Prior Page: 
<a href="=$prior-page&f$=.html">
=$prior-page$=
</a>
</p>
<?endif?>
<!-- And then at some point before the loop command... -->
<?set prior-page = "=$title$=" ?>

Body:

You can use the lines in the code field to generate links from each new page back to the prior page. 

This assumes you've sorted the input into the desired sort sequence.