    MAP
        DateFixed2(long _Month,long _Day,long _Year),LONG    
    END

!---------------------------------------------------------------------------------------------
DateFixed2 PROCEDURE(long _Month,long _Day,long _Year)!,long
RetDate     long,auto
YrsAdj      long,auto
  CODE
    ! Passing Date(m,d,y) Function a Negative or Zero, Month or Day Does not work, it returns
    ! a bad value. There was a bug with 14/29/1999 not seeing it as 2/2000 and as a Leap Year
    ! So try to get the date parts into correct range of values before using Clarion Date()

    !If all zeros then do not try to adjust and get confused
    IF ~_Month AND ~_Day AND ~_Year THEN RETURN 0.       

    ! Date cannot deal with Negative or zero Month
    ! so how many years are we off + 1
    if _Month < 1
       ! advance Month forward
       YrsAdj = 1 + ABS(_Month) / 12        
       _Month += YrsAdj * 12
       ! adjust years back
       _Year  -= YrsAdj                     
    end
    ! If year passed as YY for 2000 (i.e. 00) and
    ! adjusted with -1 this fixes -1 to be 1999
    if _Year < 0 then _Year += 2000.        

    ! In Leap Years but with Months > 12
    ! as noted by Clarion Mag
    if _Month > 12                          
        YrsAdj = (_Month - 1) / 12
       _Month -= 12* YrsAdj
       _Year  += YrsAdj
    end

    ! In case 99 gets passed and +1 to
    ! 100 else (14,29,99) fails
    if _Year > 99 and _Year <= 999 then
       _Year += 1900                        
    end

    ! Date() cannot deal with Negative Day
    if _Day < 1                                         
       RetDate = date(_Month, 1, _Year) - 1 + _Day      
    else
       RetDate = date(_Month, _Day, _Year)
    end

    return RetDate
