! Often I need to advance a date by one month, but the date in the next month must be based on
! the anniversary of an original date. In my case, this is the date an account was opened. The
! standard DATE() function works fine if the account opened date lies between the 1st and
! 28th day of the first month. But what if an account opened on January 30 2005? Adding one
! month each time to the previous in the series would give a dates of sequence of Jan 30,
! March 2 April 2 May 2. Where did the February date go?
!
! So I built a very simple small function I call nmDate to give me the date for the next month.
! I require a date for each month. I pass two values and the function returns the next month’s
! date as a LONG.
!---------------------------------------------------------------------------------------------    

    MAP
        NextMonthDate(LONG piFromDate,LONG piAnnivOf),LONG      !John called it nmDate()  
    END

!---------------------------------------------------------------------------------------------    
NextMonthDate PROCEDURE(LONG piFromDate,LONG piAnnivOf)!,LONG
 ! piFromDate is the date in the month which we want to
 ! advance and get the Next Month's date. 
 ! The piAnnivOf is the DAY of Month value we wish to use as the anniversary
 ! 
NRD     LONG,AUTO
  CODE
  CASE piAnnivOf
  OF 1 to 28
            NRD = date(MONTH(piFromDate)+1, piAnnivOf ,year(piFromDate))
  OF 29 to 31
            NRD = date(MONTH(piFromDate)+1, piAnnivOf ,year(piFromDate))
            IF DAY(NRD) < 5
              LOOP 4 TIMES
                NRD -= 1
                IF DAY(NRD) > 27
                  BREAK
                END
              END
            END
  ELSE
            NRD = 0   
  END ! CASE
  RETURN NRD    


!--------------------------------------------------------------------------------------------------
!######################## Carl Would Suggest Revise As Below ################################
!--------------------------------------------------------------------------------------------------
! 1. Change piAnnivOf from LONG to BYTE because it is suppose to be 1-31 ... a LONG may imply a DATE
! 2. Rename piAnnivOf to pbAnnivDayOf so "Day" reminds us this is a DAY 1 to 31 and "pi" to "pb"
! 3. Check "IF piFromDate=0" that means there is No Date passed so Return Zero as it mkes no sense to return DATE(1,0,0)
! 4. Add new parameter "USHORT NoOfMonths=1" to allow more than 1 as I can see a 6 month Anniversary or any months

    MAP
        NextMonthDate_Carl(LONG piFromDate, BYTE pbAnnivDayOf, USHORT NoOfMonths=1),LONG    
    END
!---------------------------------------------------------------------------------------------    
NextMonthDate_Carl PROCEDURE(LONG piFromDate,BYTE pbAnnivDayOf, USHORT NoOfMonths=1)!,LONG
 ! piFromDate is the date in the month which we want to
 ! advance and get the Next Month's date. 
 ! The pbAnnivDayOf is the DAY of Month value we wish to use as the anniversary
 ! Pass "USHORT NoOfMonths=1" so can do more than 1 Month
 
NRD     LONG,AUTO
  CODE
  IF piFromDate = 0 THEN RETURN 0.      !Carl if passed no Base Date makes No Sense to Add
  NRD = date(MONTH(piFromDate)+NoOfMonths, pbAnnivDayOf ,year(piFromDate))    !Carl was +1 Months change to +NoOfMonths  
  CASE pbAnnivDayOf
  OF 1 to 28
            !This will always be correct            
  OF 29 to 31
            !This will could change and advance to the next Month e.g. May 31at + 1 months = 31st of June = July 1
            IF DAY(NRD) < 5
              LOOP 4 TIMES          !Carl asks ... Can't we just subtract DAY(NRD) insead of Loop ???
                NRD -= 1
                IF DAY(NRD) > 27
                   BREAK
                END
              END
            END
  ELSE               !Not a normal Day of Month 1 to 31 so return 0 bad date
            NRD = 0   
  END ! CASE
  RETURN NRD  