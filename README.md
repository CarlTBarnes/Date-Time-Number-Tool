# Date Time Number Tool

Clarion Dates and Times are a bit tricky the way they are stored (Standard Dates and Times) and formatted with @Pictures. This tool lets you test out everything to understand it so the code you write works as expected. You can also try out @N Number, @E Exponent and @P Pattern Pictures.

_____
### Date Tab

Enter a Date and see the Clarion Standard Date (days since 12/27/1800). Displays all Clarion @D Pictures. The list has click sortable headings so you can sort by Date Format. Right-click on the list for options to copy the Format or Equate.

The Copy button above the List will place an Equate for the entered date no the clipboard to use in code instead of the DATE() function.
```
Date_7_4_2024  EQUATE(81638)  !20240704  07/04/2024  2024-07-04  04-JUL-2024  Thursday July  4, 2024
```

![date tab](images/readme1.png)
___
### Date Calculations

Test various calculations using the DATE() function and/or entered dates or date serial numbers. This allows you to verify that passing out of range (Month, Day, Year) values to  DATE() function work as expected.

![Calc tab](images/readme2.png)

The DATE(m,d,y) function fails if passed a Month value of Zero or Negative and returns -1. The workaround is to Add Months and Subtract Years. There is a "Fix -Mon" button that explains the calculations.

![Calc Tab Fix Mon](images/readme2n1.png)

The screen capture shows subtracting 9 months from 7 will pass -2 and fail. Instead add 3 months and subtract 1 year.

![Calc Tab Fix Mon](images/readme2n2.png)

The formula works for any number of Negative Months e.g. -30 Months can be done as (-30 % 12) = +6 Months Added and ()(-30+1)/-12 +1 ) = 3 Years Subtracted.
___
### Holiday Dates

The dates of some common Holidays. A better Holiday Calculator available on GitHub: https://GitHub.com/CarlTBarnes/Holiday-Calculator

![holiday tab](images/readme3.png)
___
### Time tab

Enter a Time and see the Clarion Start Times (1/100 seconds since midnight + 1). Displays all Clarion @T Pictures. Right-click on the list for options to copy the Format or Equate.

Clarion has no TIME(h,m,s) function so typical code to get a Standard Time is `DEFORMAT('12:30:00',@t4)`. The Copy button above the List will place an Equate for the entered Time on the clipboard like below:

```
Time_12:30:00     EQUATE(4500001)     ! 12:30:00  12:30:00PM  123000
```

![time tab](images/readme4.png)

At the bottom are Equates for the parts of Time you can copy into your code. 
___
### Number Pictures ... or Any Others @E @P @D @T @S

Try out any @Picture and Value to see how it formats.

You can test how DeFromat() works with and without the @Picture for any Value.

![number tab](images/readme5.png)

The @P @E and @N Number formats syntax is show. These all have tool tips explaining the syntax options.
___
