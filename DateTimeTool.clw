!A Tool that helps work with Clarion Dates, Times, Numbers and Pictures by Carl Barnes.
!See Clarion Standard Dates and All @D Pictures, the same for Standard Time and @T Pictures.
!Test Date Calculations with DATE() function to see if they workas expected. 

    PROGRAM
    INCLUDE 'keycodes.clw'

!_WndPrvInclude_     EQUATE(1)                   !Uncomment these 2 lines to add Wnd Preview Class
!    Include('CbWndPreview.inc'),ONCE            ! https://github.com/CarlTBarnes/WindowPreview
    COMPILE('!* WndPrvCls *',_WndPrvInclude_) 
WndPrvCls   CBWndPreviewClass,THREAD            
             !* WndPrvCls *

    MAP
MainTool   Procedure(STRING _WndAtX,STRING _WndAtY)
DateFixed       PROCEDURE(long _Month,long _Day,long _Year),long        !Fixed to handle C5 - C6 problems with Month/Day out of Range
DateFixV2       PROCEDURE(LONG _Month,LONG _Day,LONG _Year),LONG        !Version 2 for C8 - C11 that fails if Month Zero or Negative 
UnitTest_DateFixed PROCEDURE()
DateAdjust      PROCEDURE(LONG InDate, LONG YearAdj=0, LONG MonthAdj=0, LONG DayAdj=0, <SHORT ForceDay>),LONG  !Uses  DateFixed() to handle problem values
DateSplit       PROCEDURE(LONG Date2Split, <*? OutMonth>, <*? OutDay>, <*? OutYear>)
DB              PROCEDURE(STRING DebugMessage)  !OutputDebugString
DOWName         PROCEDURE(LONG Date2Dow),STRING
DOWNumAndName   PROCEDURE(LONG Date2Dow),STRING    !Return "# Xxx" e.g. "3 Wed" to put on Calc Tab
DOWOrdinal      PROCEDURE(LONG Date2Dow, BOOL OrdinalWord=0),STRING     !Return Original 1st 2nd 3rd or First Second
EasterDate      PROCEDURE(USHORT Yr),LONG
HolidayCheck    PROCEDURE(LONG pDate2Check,<*string HolidayName>,<*string DOWName>),BYTE     !0=No 1=Yes Weekday 2=Yes Weekend
LettersOnly     PROCEDURE(STRING inText),STRING 
PopupUnder      PROCEDURE(LONG CtrlFEQ, STRING PopMenu),LONG            
ReplaceChar     PROCEDURE(*STRING InOutString, STRING FindChars, STRING PutChars, BOOL NoCase=False),LONG,PROC   !Returns Position. Finds ONCE and Replaces.
TimeSplit       PROCEDURE(LONG Time2Split, <*? OutHour>, <*? OutMinute>, <*? OutSecond>, <*? OutHundred>)
TimeHMS         PROCEDURE(LONG Hours=0, LONG Mins=0, LONG Secs=0, LONG Hundredths=0),LONG !Time Join H:M:S.D calc allows invalid parts like 90 minutes

      MODULE('WinAPI')
         OutputDebugString(*cstring DebugMsg),PASCAL,RAW,DLL(1),NAME('OutputDebugStringA')
      END
    END !MAP

    CODE
    SYSTEM{PROP:MsgModeDefault}=MSGMODE:CANCOPY  ;  SYSTEM{7A58h}=1 !is PROP:PropVScroll added C11 
    SYSTEM{PROP:FontName}='Segoe UI' ; SYSTEM{PROP:FontSize}=11  
        IF 0=1 THEN UnitTest_DateFixed().  !If you change Date Fixed V1 or V2 Code then run this to Unit Test by making IF 1=1
    MainTool('','')
    return

MainTool  Procedure(STRING _WndAtX,STRING _WndAtY)   
!Region Data Varibles -------------------------
TheDate     DATE,AUTO
QNdx        LONG            
Ndx         LONG            
DOW         STRING(16)

PicNdx      LONG,AUTO           !a looper
DatesQ      QUEUE,pre(DateQ)
Pic             CString(7)  !@d1-        DateQ:Pic
Format          STRING(20)  !mm/dd/yy    DateQ:Format
Value           STRING(20)  !9/22/03     DateQ:Value
SortPic         SHORT       !1           DateQ:SortPic  Just Ndx Number
SortFmt         STRING(30)  !MM/DD/YY    DateQ:SortFmt  All Lower with "Letters Only" first e.g. mmddyy MM/DD/YY
            END
DateLeading     STRING(' ')
DateSeparator   STRING(' ')


TimeQ   queue,pre(TimeQ)
Pic         cstring(7)  !@d000-
Format      STRING(20)  !mm/dd/yy
Value       STRING(20)  !9/22/03
        end
TheTime     TIME
            GROUP,OVER(TheTime),PRE(TheTm)
Cent          BYTE  ! TheTm:Cent    1/100's
Secs          BYTE  ! TheTm:Secs
Mins          BYTE  ! TheTm:Mins
Hrs           BYTE  ! TheTm:Hrs
            END
TimeLeading     STRING(' ')
TimeSeparator   STRING(' ')
!Time Equates from Mark Goldberg https://github.com/MarkGoldberg/CwUnit/blob/master/Libsrc/Time.equ
TimeEquates     STRING(      'TIME:Tick   EQUATE(  1)                !1/100th Second' &|
                      '<13,10>TIME:Second EQUATE(100 * TIME:Tick)    !100' &|
                      '<13,10>TIME:Minute EQUATE( 60 * TIME:Second)  !6,000            60*100' &|
                      '<13,10>TIME:Hour   EQUATE( 60 * TIME:Minute)  !360,000       60*60*100' &|
                      '<13,10>TIME:Day    EQUATE( 24 * TIME:Hour  )  !8,640,000  24*60*60*100' &|
                      '<13,10>' &|
                      '<13,10>!FYI: Clarion Standard Time is always +1 ' &|
                      '<13,10>!E.g. 2:30 AM = 1 + (2 * TIME:Hour) + (30 * TIME:Minute) ' )  ! Length = 400

PickQ   queue,pre(pick)
Name        string(30)      ! PickQ:Name
Char        string(1)       ! PickQ:Char
        end
Picker  Class
PickLead    procedure(long BtnFEQ, string TypeDTN, *string InOutLeadChar),bool                       !returns 1 if was picked
PickSep     procedure(long BtnFEQ, string TypeDTN, *string InOutSepChar, String DefaultName),bool    !returns 1 if was picked
PopupPicks  procedure(long BtnFEQ, *string InOutTheChar, String Title),bool
        END

NumberQ QUEUE,pre(NumQ)
Pic         STRING(32)      !@n000-    !NumQ:Pic
RawValue    STRING(32)      !12345.67  !NumQ:RawValue
Formatted   STRING(32)      !9/22/03   !NumQ:Formatted      = Format(Value,@Picture) in LIST or ENTRY may not be the same
        END 
NumberInpGrp GROUP(NumberQ),pre(NumInput)
! Pic         STRING(32)      !@n000-    !NumInput:Pic
! RawValue    STRING(32)      !12345.67  !NumInput:RawValue
! Formatted   STRING(32)      !9/22/03   !NumInput:Formatted
        END 
DeFmt:RawValue  STRING(32)
DeFmt:Format1   STRING(32)
DeFmt:Picture   STRING(32)
DeFmt:Format2   STRING(32)
                    
                    !See my Tool Do2Class to convert routines to a DOO Class:  https://github.com/CarlTBarnes/Do2Class
DOO         CLASS   !A Class for Routines so can be called a Procedures and return values. I prefer to MAP so Scope is more obvious.
NumbQAdd        PROCEDURE(string ThePicture, string TheValue, bool bAddFirst=0, <*NumberInpGrp OutNumberInput>)      !Add to the Number Q
DateOrDateFixed PROCEDURE(long _Month,long _Day,long _Year),long   !Calls DATE() or DateFixed() based on DateCalc_UseDateFixed
MonthNegativeFixBtnPressed  PROCEDURE()
MonthNegFyiDate PROCEDURE(STRING DateFctName, LONG FyiMonth, LONG FyiDay, LONG FyiYear, STRING FyiSuffixNote),STRING   !Fmt Date() for Msg FYI lines
            END

!Calendar fields
Weeks       string(21),dim(6)
Days        string(3),dim(42),over(Weeks)
CalFirstday LONG
CalMonth    LONG
CalYear     LONG
CalTitle    STRING(20)

DateCalc_BaseMonth  LONG
DateCalc_BaseDay    LONG
DateCalc_BaseYear   LONG
DateCalc_BaseDate   LONG
DateCalc_PlusMonth  LONG
DateCalc_PlusDay    LONG
DateCalc_PlusYear   LONG
DateCalc_NetMonth   LONG
DateCalc_NetDay     LONG
DateCalc_NetYear    LONG
DateCalc_NetDate    LONG
DateCalc_Base_DOW   STRING(5)   !E.g. 3 Wed
DateCalc_NetD_DOW   STRING(5)

DateTwo_BaseMonth   LONG
DateTwo_BaseDay     LONG
DateTwo_BaseYear    LONG
DateTwo_BaseDate    LONG
DateTwo_PlusDayz    LONG
DateTwo_NetDate     LONG
DateTwo_Base_DOW    STRING(5)   !E.g. 3 Wed
DateTwo_NetD_DOW    STRING(5)

DateCalc_UseDateFixed  BYTE     !DateFixed() Version 1 handles C5 C5.5 C6 problems with Leap Years and out of range (M,D,Y)
DateCalc_UseDateFixV2  BYTE     !DateFixV2() Version 2 handles C8 - C11 Month <= 0 Problem

DateCalc_DBtwD1       LONG        !Days between dates
DateCalc_DBtwD2       LONG
DateCalc_DBtwDdays    LONG
DateCalc_DBtwDAge     STRING(16) 
DateCalc_DBtwD1_DOW   STRING(5)
DateCalc_DBtwD2_DOW   STRING(5)
DateCalc_AdjDtD1      LONG        !Add days to date
DateCalc_AdjDtDays    LONG
DateCalc_AdjDtD2      LONG        !Add days to date 
DateCalc_AdjDtD1_DOW  STRING(5)
DateCalc_AdjDtD2_DOW  STRING(5)
EvalCalc_Input  STRING(255)
EvalCalc_Result STRING(255)

HolidayYear            USHORT
HolidayQ               QUEUE,PRE(HolidayQ)
HDate                       LONG                !HolidayQ:HDate
HDow                        STRING(3)           !HolidayQ:HDow
HName                       STRING(60)          !HolidayQ:HName
                       END
!EndRegion Data Varibles -------------------------

Window WINDOW('Date Time Number Picture Tool'),AT(,,310,193),GRAY,AUTO,SYSTEM,ICON(ICON:Thumbnail), |
            STATUS(-1,135,0),FONT('Segoe UI',10,,FONT:regular),DOUBLE
        SHEET,AT(2,2,306,189),USE(?Sheet1)
            TAB(' &Date '),USE(?Tab:Date)
                BUTTON,AT(180,2,14,11),USE(?CopyDateBtn),SKIP,ICON(ICON:Copy),TIP('Copy Current Date' & |
                        ' as a "Date_M_D_Y EQUATE()" to Clipboard')
                PROMPT('&Date:'),AT(9,18),USE(?Prompt:DateDate)
                SPIN(@d02b),AT(30,18,62,10),USE(TheDate),HVSCROLL
                PROMPT('S/&N:'),AT(9,31),USE(?Prompt:DateSN)
                SPIN(@n9),AT(30,31,62,10),USE(TheDate,, ?TheDateSN),HVSCROLL,LEFT
                LIST,AT(104,30,198,156),USE(?List:DatesQ),FONT('Consolas'),TIP('Click Headings to So' & |
                        'rt<13><10>Right Click Rows for Options'),FROM(DatesQ),FORMAT('29L(2)|FM~@d~' & |
                        'C(0)@s7@86L(2)|M~Date Format~C(0)@s20@62L(2)|M~Format(,@D)~C(0)@s20@')
                BUTTON('&Refresh'),AT(103,16,29,11),USE(?RefreshDatesBtn),SKIP,FONT(,8)
                BUTTON('&Leading'),AT(151,16,30,11),USE(?DateLeadBtn),SKIP,FONT(,8),TIP('Select the ' & |
                        'Leading Character<13,10>Many do not work, they are provided to try them')
                BUTTON('&Separator'),AT(186,16,35,11),USE(?DateSepBtn),SKIP,FONT(,8),TIP('Select the' & |
                        ' Separator Character<13,10>Many do not work, they are provided to try them')
                ENTRY(@s16),AT(9,46,84,10),USE(DOW),SKIP,CENTER,COLOR(COLOR:BTNFACE),READONLY
                ENTRY(@d4),AT(9,59,84,10),USE(TheDate,, ?TheDateLong),SKIP,CENTER,COLOR(COLOR:BTNFACE), |
                        READONLY
                BUTTON,AT(8,79,14,10),USE(?MinusYear),SKIP,FONT(,8),ICON(ICON:VCRrewind),TIP('Back 1 Year')
                BUTTON,AT(24,79,13,10),USE(?MinusMonth),SKIP,FONT(,8),ICON(ICON:VCRback),TIP('Back 1' & |
                        ' Month')
                BUTTON('&Today'),AT(40,79,22,10),USE(?TodayBtn),SKIP,FONT(,7)
                BUTTON,AT(64,79,13,10),USE(?PlusMonth),SKIP,FONT(,8),ICON(ICON:VCRplay),TIP('Forward' & |
                        ' 1 Month')
                BUTTON,AT(80,79,14,10),USE(?PlusYear),SKIP,FONT(,8),ICON(ICON:VCRfastforward), |
                        TIP('Forward 1 Year')
                GROUP,AT(6,91,90,76),USE(?CalMonthGroup),FONT('Consolas',9,,FONT:bold)
                    PANEL,AT(8,93,86,70),USE(?CalMonthPanel),FILL(COLOR:WINDOW),BEVEL(-2)
                    STRING(@s20),AT(11,97,81,9),USE(CalTitle),CENTER,COLOR(COLOR:BTNFACE)
                    STRING('Su Mo Tu We Th Fr Sa '),AT(11,106,81,8),USE(?CalWeekDays),COLOR(COLOR:BTNFACE)
                    STRING(@s20),AT(11,115,81,9),USE(Weeks[1]),TRN
                    STRING(@s20),AT(11,123,81,9),USE(Weeks[2]),TRN
                    STRING(@s20),AT(11,131,81,9),USE(Weeks[3]),TRN
                    STRING(@s20),AT(11,139,81,9),USE(Weeks[4]),TRN
                    STRING(@s20),AT(11,147,81,9),USE(Weeks[5]),TRN
                    STRING(@s20),AT(11,155,81,9),USE(Weeks[6]),TRN
                END
                STRING('@D [L] # [S] [B]'),AT(248,17),USE(?Syntax_Date)
            END
            TAB(' &Calc '),USE(?Tab:Calc)
                GROUP,AT(5,15,299,45),USE(?Date_Calc:Grp)
                    PROMPT('&Input Date('),AT(20,25),USE(?DateCalculate:Prompt)
                    PROMPT('&Month'),AT(59,15,,8),USE(?DateCalc_BaseMonth:Prompt)
                    ENTRY(@N-7),AT(60,25,28,10),USE(DateCalc_BaseMonth),RIGHT,TIP('A Negative Month ' & |
                            'will cause DATE() to Fail and Return -1')
                    STRING('/'),AT(90,15),FONT(,,,FONT:bold)
                    PROMPT('&Day'),AT(101,15,,8),USE(?DateCalc_BaseDay:Prompt)
                    ENTRY(@n-7),AT(95,25,28,10),USE(DateCalc_BaseDay),RIGHT
                    STRING('/'),AT(125,14),FONT(,,,FONT:bold)
                    PROMPT('&Year'),AT(134,15,,8),USE(?DateCalc_BaseYear:Prompt)
                    SPIN(@n4),AT(129,25,28,10),USE(DateCalc_BaseYear),RIGHT,RANGE(1801,9999)
                    STRING(') = '),AT(165,26)
                    ENTRY(@n-9),AT(180,25,37,10),USE(DateCalc_BaseDate),SKIP,RIGHT
                    ENTRY(@d02b),AT(222,25,44,10),USE(DateCalc_BaseDate,, ?DateCalc_BaseDate:d2),SKIP
                    STRING(@s5),AT(271,25,26,10),USE(DateCalc_Base_DOW)
                    BUTTON('Fi&x<0dh,0ah>-Mon'),AT(5,46,21,15),USE(?MonthNegativeFixBtn),SKIP,FONT(,8), |
                            TIP('Explain how to calculate Negative Months<13,10>that may cause DATE(' & |
                            ') to return -1<13,10>by using Postive Months and Negative Years  <13,10>')
                    PROMPT('+/- M,D,Y'),AT(24,37),USE(?DateCalc_Plus:Prompt)
                    ENTRY(@N-7),AT(60,37,28,10),USE(DateCalc_PlusMonth),RIGHT
                    ENTRY(@n-7),AT(95,37,28,10),USE(DateCalc_PlusDay),RIGHT
                    ENTRY(@n-5),AT(129,37,28,10),USE(DateCalc_PlusYear),RIGHT
                    PROMPT('= Date('),AT(31,49),USE(?DateCalc_Net:Prompt)
                    ENTRY(@n-7),AT(60,49,28,10),USE(DateCalc_NetMonth),SKIP,RIGHT,COLOR(COLOR:BTNFACE), |
                            READONLY
                    ENTRY(@n-7),AT(95,49,28,10),USE(DateCalc_NetDay),SKIP,RIGHT,COLOR(COLOR:BTNFACE), |
                            READONLY
                    ENTRY(@n-6),AT(129,49,28,10),USE(DateCalc_NetYear),SKIP,RIGHT,COLOR(COLOR:BTNFACE), |
                            READONLY
                    STRING(') = '),AT(165,49)
                    ENTRY(@n-9),AT(180,49,37,10),USE(DateCalc_NetDate),SKIP,RIGHT,COLOR(COLOR:BTNFACE), |
                            READONLY
                    ENTRY(@d02b),AT(222,49,44,10),USE(DateCalc_NetDate,, ?DateCalc_NetDate:d2),SKIP, |
                            COLOR(COLOR:BTNFACE),READONLY
                    STRING(@s5),AT(271,49,26,10),USE(DateCalc_NetD_DOW)
                END
                PANEL,AT(6,63,295,2),USE(?Panel_Calc2),BEVEL(0,0,0600H)
                GROUP,AT(5,67,266,38),USE(?DateTwo_Grp)
                    PROMPT('&Another Date('),AT(6,68),USE(?DateCalcAnother:Prompt)
                    ENTRY(@N-7),AT(60,68,28,10),USE(DateTwo_BaseMonth),RIGHT
                    ENTRY(@n-7),AT(95,68,28,10),USE(DateTwo_BaseDay),RIGHT
                    SPIN(@n4),AT(129,68,28,10),USE(DateTwo_BaseYear),RIGHT,RANGE(1801,9999)
                    STRING(') = '),AT(165,69)
                    ENTRY(@n-9),AT(180,68,37,10),USE(DateTwo_BaseDate),SKIP,RIGHT
                    ENTRY(@d02b),AT(222,68,44,10),USE(DateTwo_BaseDate,, ?DateTwo_BaseDate:d2),SKIP
                    STRING(@s5),AT(271,68,26,10),USE(DateTwo_Base_DOW)
                    PROMPT('Change +/-'),AT(137,80),USE(?DateTwo_Plus:Prompt)
                    ENTRY(@n-7),AT(180,80,37,10),USE(DateTwo_PlusDayz),RIGHT
                    ENTRY(@n-9),AT(180,92,37,10),USE(DateTwo_NetDate),SKIP,RIGHT,COLOR(COLOR:BTNFACE), |
                            READONLY
                    ENTRY(@d02b),AT(222,92,44,10),USE(DateTwo_NetDate,, ?DateTwo_NetDate:d2),SKIP, |
                            COLOR(COLOR:BTNFACE),READONLY
                    STRING(@s5),AT(271,92,26,10),USE(DateTwo_NetD_DOW)
                    PROMPT('DATE() when Month is Zero or Negative returns -1. Day of Zero or Negativ' & |
                            'e works. See DateFixed() on upper right.'),AT(6,84,123,19),USE(?DateCalc_DatePromblems:FYI) |
                            ,FONT(,8)
                END
                CHECK('Use DateFixed()'),AT(180,15),USE(DateCalc_UseDateFixed),SKIP,FONT(,9)
                CHECK('Use Version 2'),AT(243,15),USE(DateCalc_UseDateFixV2),SKIP,FONT(,9)
                PANEL,AT(6,107,295,2),USE(?Panel_Calc3),BEVEL(0,0,0600H)
                GROUP,AT(5,110,286,23),USE(?CalcGroup_Adjust)
                    PROMPT('Date to &Adjust:'),AT(6,113),USE(?DateToAdjust:Prompt)
                    ENTRY(@d02b),AT(59,112,46,10),USE(DateCalc_AdjDtD1)
                    STRING('plus/minus'),AT(108,113)
                    ENTRY(@n-8),AT(149,112,33,10),USE(DateCalc_AdjDtDays)
                    STRING('days ='),AT(186,113)
                    ENTRY(@d02b),AT(213,112,44,10),USE(DateCalc_AdjDtD2),COLOR(COLOR:BTNFACE),READONLY
                    STRING(@n9b),AT(44,122,38,9),USE(DateCalc_AdjDtD1,, ?DateCalc_AdjDtD1:2),TRN,RIGHT
                    STRING(@n9b),AT(202,122,34,9),USE(DateCalc_AdjDtD2,, ?DateCalc_AdjDtD2:2),TRN,RIGHT
                    STRING(@s5),AT(88,122,26,10),USE(DateCalc_AdjDtD1_DOW)
                    STRING(@s5),AT(242,122,26,10),USE(DateCalc_AdjDtD2_DOW)
                END
                PANEL,AT(6,132,295,2),USE(?Panel_Calc4),BEVEL(0,0,0600H)
                GROUP,AT(5,134,286,24),USE(?CalcGroup_DaysBtw)
                    PROMPT('Days Bet&ween:'),AT(7,137,49),USE(?DaysBtw:Prompt)
                    ENTRY(@d02b),AT(60,137,45,10),USE(DateCalc_DBtwD1)
                    STRING('minus'),AT(110,137)
                    ENTRY(@d02b),AT(134,137,46,10),USE(DateCalc_DBtwD2)
                    STRING('='),AT(185,137)
                    ENTRY(@n-10),AT(197,137,40,10),USE(DateCalc_DBtwDdays),COLOR(COLOR:BTNFACE),READONLY
                    ENTRY(@s16),AT(197,147,80,10),USE(DateCalc_DBtwDAge),TRN,COLOR(COLOR:BTNFACE), |
                            TIP('AGE() Function'),READONLY
                    STRING(@n9b),AT(44,147,38),USE(DateCalc_DBtwD1,, ?DateCalc_DBtwD1:2),RIGHT
                    STRING(@n9b),AT(118,147,38),USE(DateCalc_DBtwD2,, ?DateCalc_DBtwD2:2),RIGHT
                    STRING(@s5),AT(88,147,26,10),USE(DateCalc_DBtwD1_DOW)
                    STRING(@s5),AT(162,147,26,10),USE(DateCalc_DBtwD2_DOW)
                END
                PANEL,AT(6,159,295,2),USE(?Panel_Calc5),BEVEL(0,0,0600H)
                PROMPT('E&valuate:'),AT(7,163),USE(?EvalCalc_Input:Prompt)
                ENTRY(@s255),AT(41,163,260,10),USE(EvalCalc_Input),FONT('Consolas')
                PROMPT('Result:'),AT(7,176),USE(?EvalCalc_Input:Prompt:2)
                ENTRY(@s255),AT(41,176,260,10),USE(EvalCalc_Result),FONT('Consolas'),COLOR(COLOR:BTNFACE), |
                        READONLY
            END
            TAB(' &Holiday '),USE(?Tab:Holiday)
                BUTTON,AT(180,2,14,11),USE(?CopyHolidayBtn),SKIP,ICON(ICON:Copy),TIP('Copy Selected ' & |
                        'Holiday as a "Date EQUATE()" to Clipboard')
                PROMPT('&Year:'),AT(7,19),USE(?Prompt14)
                PROMPT('A better Holiday Calculator available on GitHub<0Dh,0Ah>GitHub.com/CarlTBarn' & |
                        'es/Holiday-Calculator'),AT(135,16,151,13),USE(?GitHubHolidayRepo),FONT(,8),CENTER
                SPIN(@n_4),AT(25,18,38,10),USE(HolidayYear),HVSCROLL
                STRING('Leap Year!'),AT(69,19),USE(?LeapYearTxt),FONT(,,,FONT:bold)
                LIST,AT(8,31,292,154),USE(?List:HolidayQ),VSCROLL,FONT(,10),FROM(HolidayQ), |
                        FORMAT('44R(4)|M~Date~C(0)@d2-@24L(4)|FM~Day~C(0)@s3@40L(2)|FM~Holiday Name~@s60@')
            END
            TAB(' Tim&e '),USE(?Tab:Time)
                BUTTON,AT(180,2,14,11),USE(?CopyTimeBtn),SKIP,ICON(ICON:Copy),TIP('Copy Current Time' & |
                        ' as a "Time_HH:MM:SS EQUATE()" to Clipboard')
                PROMPT('&Time 24:'),AT(8,20),USE(?Prompt:TheTime)
                SPIN(@t04b),AT(39,19,61,10),USE(TheTime),HVSCROLL,STEP(6000)
                PROMPT('T&ime 12:'),AT(8,34),USE(?Prompt:TheTimeT6)
                SPIN(@t06b),AT(39,33,61,10),USE(TheTime,, ?TheTimeT6),HVSCROLL,STEP(6000)
                PROMPT('S/&N:'),AT(8,48),USE(?Prompt:TheTimeSN)
                SPIN(@n10),AT(39,47,61,10),USE(TheTime,, ?TheTimeSN),HVSCROLL,LEFT,STEP(100)
                BUTTON('Time No&w'),AT(8,63,86,11),USE(?TimeNowBtn),FONT(,8)
                BUTTON('Connect to www.time.gov'),AT(8,79,86,11),USE(?ConnectTimegov),FONT(,8)
                LIST,AT(109,30,193,75),USE(?List:TimeQ),FONT('Consolas'),FROM(TimeQ),FORMAT('28L(2)|' & |
                        'FM~@T~C(0)@s7@78L(2)|M~Time Format~C(0)@s20@62L(2)|M~Format(,@T)~C(0)@s20@')
                BUTTON('&Refresh'),AT(108,16,30,11),USE(?RefreshTimeBtn),SKIP,FONT(,9)
                BUTTON('&Leading'),AT(156,16,30,11),USE(?TimeLeadBtn),SKIP,FONT(,8),TIP('Select the ' & |
                        'Leading Character')
                BUTTON('&Separator'),AT(189,16,35,11),USE(?TimeSepBtn),SKIP,FONT(,8),TIP('Select the' & |
                        ' Separator Character')
                STRING('@T [L] # [S] [B]'),AT(249,17),USE(?Syntax_Time)
                TEXT,AT(8,121,294,64),USE(TimeEquates),HVSCROLL,FONT('Consolas',9,COLOR:Black), |
                        COLOR(0E1FFFFH),READONLY
            END
            TAB(' N&umber '),USE(?Tab:NumTest)
                BUTTON,AT(180,2,14,11),USE(?CopyNumBtn),SKIP,ICON(ICON:Copy),TIP('Copy Selected Numb' & |
                        'er Format as an Equate to Clipboard')
                PROMPT('&Picture:'),AT(6,19),USE(?NumInput:Pic:Prompt)
                ENTRY(@s32),AT(35,19,79,10),USE(NumInput:Pic)
                PROMPT('&Value:'),AT(6,31),USE(?NumInput:RawValue:Prompt)
                ENTRY(@s32),AT(35,31,79,10),USE(NumInput:RawValue)
                PROMPT('Format('),AT(6,43),USE(?NumInput:Formatted:Prompt)
                ENTRY(@s32),AT(35,43,79,10),USE(NumInput:Formatted),COLOR(COLOR:BTNFACE),TIP('FORMAT' & |
                        '( Value, @Picture)<13,10>See the @Picture processed by the RTL Format() fun' & |
                        'ction '),READONLY
                PROMPT('Entry(@'),AT(6,55),USE(?NumInput:RawValue_Picture:Prompt)
                ENTRY(@s32),AT(35,55,79,10),USE(NumInput:RawValue,, ?NumInput:RawValue_Picture),LEFT, |
                        COLOR(COLOR:BTNFACE),TIP('ENTRY(@Picture),USE(Value) <13,10>See the @Picture' & |
                        ' processed by the Screen Library '),READONLY
                BUTTON('&Add ->'),AT(81,67,34,11),USE(?AddNumPicBtn),FONT(,9),TIP('Add Picture to List')
                BUTTON('Clear'),AT(50,67,28,11),USE(?ClearNumPicBtn),SKIP,FONT(,9),TIP('Clear Number' & |
                        's List')
                PROMPT('Double click to use Picture above ->'),AT(6,80,109),USE(?NumQListM2FYI),FONT(,8), |
                        CENTER
                LIST,AT(120,19,184,154),USE(?List:NumberQ),VSCROLL,FONT('Consolas',9),FROM(NumberQ), |
                        FORMAT('52L(2)|FM~Picture~C(0)@s32@48R(2)|M~Value~C(0)@s32@62R(2)|M~Format(V' & |
                        ',@)~C(0)@s32@')
                GROUP('Deformat (v)  vs  (v,@picture)'),AT(5,93,110,59),USE(?DeFmt:Group),FONT(,9),BOXED
                    PROMPT('Va&lue:'),AT(10,102),USE(?DeFmt:RawValue:Prompt)
                    ENTRY(@s32),AT(41,102,70,10),USE(DeFmt:RawValue)
                    PROMPT('P&icture:'),AT(10,114),USE(?DeFmt:Picture:Prompt)
                    ENTRY(@s32),AT(41,114,70,10),USE(DeFmt:Picture),TIP('Test DeFormat() with this @' & |
                            'Picture<13,10>Some pictures have odd results, so use this test to be sure')
                    PROMPT('DeFmt()'),AT(10,126),USE(?DeFmt:Format1:Prompt)
                    ENTRY(@s32),AT(41,126,70,10),USE(DeFmt:Format1),COLOR(COLOR:BTNFACE),TIP('DeFrom' & |
                            'at(Value)<13,10>DeFormat() without using Picture'),READONLY
                    PROMPT('DeFmt@'),AT(11,139),USE(?DeFmt:Format2:Prompt)
                    ENTRY(@s32),AT(41,138,70,10),USE(DeFmt:Format2),COLOR(COLOR:BTNFACE),TIP('DeFrom' & |
                            'at(Value, @Picture)<13,10>DeFormat() Using Picture'),READONLY
                END
                PROMPT('Syntax has<0Dh,0Ah>Tool Tips'),AT(82,154,34,13),USE(?NumPicFYI_ToolTips),FONT(,8)
                STRING('@Emsn  @e#[. .. ` _.]#'),AT(5,168,,7),USE(?Syntax_AtE),FONT('Consolas',9)
                STRING('@P[<<][#][x]Pp[B]'),AT(5,160,,7),USE(?Syntax_AtPp),FONT('Consolas',9)
                GROUP,AT(2,175,276,16),USE(?Num_Syntax_Grp),FONT('Consolas',9)
                    STRING('@n[currency][sign][fill] size [grouping][places][sign][currency][B]'), |
                            AT(5,176,,7),USE(?Num_Syntax_AllParts)
                    STRING('$ ~xx~'),AT(19,182,,7),USE(?NSyntax_Curr1)
                    STRING('-('),AT(59,182,14,7),USE(?NSyntax_Sign1)
                    STRING('_*0'),AT(82,182,,7),USE(?NSyntax_Fill)
                    STRING('##'),AT(108,182,,7),USE(?NSyntax_Size)
                    STRING('._'),AT(131,182,26,7),USE(?NSyntax_Group),CENTER
                    STRING('.## `##'),AT(166,182,,7),USE(?NSyntax_Places)
                    STRING(')-'),AT(204,182,13,7),USE(?NSyntax_Sign2)
                    STRING('$ ~xx~'),AT(228,182,,7),USE(?NSyntax_Curr2)
                    STRING('B'),AT(265,182,,7),USE(?NSyntax_Blank)
                END
            END
        END
        BUTTON('ReRun'),AT(251,2,30,10),USE(?ReRunBtn),SKIP,FONT(,8),TIP('Run another instance thread')
        BUTTON('Halt'),AT(288,2,19,10),USE(?HaltBtn),SKIP,FONT(,8),HIDE,TIP('Halt all instance threads')
    END

    CODE
    TheDate = TODAY() ; TheTime = INT((CLOCK()-1)/100) * 100 + 1    !No 1/100's
    DO BuildNumberQRtn    
    DO LoadTimeQRtn
    
    OPEN(Window)  
    COMPILE('!* WndPrvCls *',_WndPrvInclude_)   
        WndPrvCls.Init(2)               !Design Window at Runtime using CBWndPreviewClass with invisible button at top   
             !* WndPrvCls * COMPILE
    IF _WndAtX THEN SETPOSITION(0,_WndAtX,_WndAtY).
    ?ReRunBtn{PROP:Tip}=?ReRunBtn{PROP:Tip} &'<13,10>'& Command('0')  !show EXE Name in ReRUn Tip
    IF THREAD()>1 THEN UNHIDE(?HaltBtn).
    0{PROP:StatusText,1}=TheDate &'  '& DOWname(TheDate) &' '& CLIP(FORMAT(TheDate,@d4))
    0{PROP:StatusText,2}='EXE RTL ' & SYSTEM{PROP:ExeVersion,2} &'.'& SYSTEM{PROP:ExeVersion,3} & |
                       ', DLL RTL ' & SYSTEM{PROP:LibVersion,2} &'.'& SYSTEM{PROP:LibVersion,3}
    ?List:TimeQ{PROP:LineHeight} = ?List:TimeQ{PROP:LineHeight} + 1 
    !like it tighter ?List:NumberQ{PROP:LineHeight} = ?List:NumberQ{PROP:LineHeight} + 1
    ?List:DatesQ{PROP:LineHeight}= ?List:DatesQ{PROP:LineHeight} + 1 
    ?List:DatesQ{PROPLIST:HasSortColumn}=1 

    DateCalc_BaseDate  = TheDate
    DateSplit(DateCalc_BaseDate, DateCalc_BaseMonth, DateCalc_BaseDay, DateCalc_BaseYear) ; DateCalc_PlusDay=-31 ; DO DateCalc_NetDate_Rtn
    DateTwo_BaseDate  = TheDate
    DateSplit(DateTwo_BaseDate, DateTwo_BaseMonth, DateTwo_BaseDay, DateTwo_BaseYear) ; DateTwo_PlusDayz = -31 ; DO DateTwo_NetDate_Rtn    
    DateCalc_DBtwD1  = TheDate ; DateCalc_DBtwD2 = Date(1,1,year(TheDate)) ; POST(EVENT:Accepted,?DateCalc_DBtwD1) 
    DateCalc_AdjDtD1 = TheDate ; DateCalc_AdjDtDays = 30 ; POST(EVENT:Accepted,?DateCalc_AdjDtD1) 
    EvalCalc_Input = 'Format(Date(1+Month(Today()), 1,Year(Today()))-1,@d8)' ; POST(EVENT:Accepted,?EvalCalc_Input) 
    DeFmt:RawValue='(1,234.56)' ; DeFmt:Picture='@n(15.2)' ; POST(EVENT:Accepted,?DeFmt:RawValue)  !IMO @n pictures do not work so well with Deformat()
    POST(EVENT:Accepted, ?NumInput:Pic)

    DO ToolTipsRtn
    DO HolidayCalcRtn
    POST(EVENT:Accepted,?TheDate)
    ACCEPT
        CASE ACCEPTED()
        OF ?PlusMonth  ;   TheDate = DATE( MONTH(TheDate)+1, DAY(TheDate), YEAR(TheDate) )
        OF ?MinusMonth                
                        IF MONTH(TheDate) = 1 THEN      !Bug in C5 DATE() function that MONTH(0,d,y) = 1/d/y ... that's bad
                           TheDate = DATE( 12,DAY(TheDate),YEAR(TheDate)-1 )
                        ELSE
                           TheDate = DATE( MONTH(TheDate)-1,DAY(TheDate),  YEAR(TheDate) )
                        END
        OF ?PlusYear   ;   TheDate = DATE( MONTH(TheDate),DAY(TheDate),  YEAR(TheDate)+1 )
        OF ?MinusYear  ;   TheDate = DATE( MONTH(TheDate),DAY(TheDate),  YEAR(TheDate)-1 )
        OF ?TodayBtn   ;   TheDate = Today()
        OF ?RefreshDatesBtn
            DO LoadDatesQRtn
            DISPLAY

        OF ?List:DatesQ
            GET(DatesQ,CHOICE(?List:DatesQ))
            CASE KEYCODE()
            OF MouseLeft2
               SETCLIPBOARD(DateQ:Pic)
            OF MouseRight
               EXECUTE Popup('Picture ' & DateQ:Pic & '|FORMAT( ,' & DateQ:Pic & ')' & '|EQUATE(' & TheDate & ')|Date_'& Format(TheDate,@d10-) &'  EQUATE('& TheDate &')' )
                 SETCLIPBOARD(DateQ:Pic &' as '& DateQ:Format)
                 SETCLIPBOARD('FORMAT( ,' & DateQ:Pic & ')   !' & DateQ:Format )
                 SETCLIPBOARD('EQUATE(' & TheDate & ')   !'& clip(DateQ:Pic)&' => '& clip(FORMAT(TheDate,DateQ:Pic)) &' as '& DateQ:Format )
                 POST(EVENT:Accepted,?CopyDateBtn)
               END
            END
        OF ?DateLeadBtn
           IF Picker.PickLead(?,'D',DateLeading) THEN POST(EVENT:Accepted,?RefreshDatesBtn).
        OF ?DateSepBtn
           IF Picker.PickSep(?,'D',DateSeparator,'Slash /') THEN POST(EVENT:Accepted,?RefreshDatesBtn).

        OF ?CopyDateBtn
!was            SetClipboard('Date_' & FORMAT(MONTH(TheDate),@n02) &'_'& FORMAT(DAY(TheDate),@n02) &'_'& YEAR(TheDate)  & |
            SetClipboard('Date_' & MONTH(TheDate) &'_'& DAY(TheDate) &'_'& YEAR(TheDate)  & |
                          ' {5}EQUATE('& TheDate &')'& |
                          ' {5}!'& format(TheDate,@d12) &'  '& format(TheDate,@d02) &'  '& format(TheDate,@d10-)  &'  '& format(TheDate,@d08-) & |
                          '  '& DOWname(TheDate) &' '& clip(format(TheDate,@d4)) )
            !e.g. Date_06_27_2024     EQUATE(81631)     !20240627  06/27/2024  2024-06-27  27-JUN-2024  Thursday June 27, 2024                          

        OF ?CopyHolidayBtn
            GET(HolidayQ,CHOICE(?List:HolidayQ))
            SetClipboard('Holiday_' & MONTH(HolidayQ:HDate) &'_'& DAY(HolidayQ:HDate) &'_'& YEAR(HolidayQ:HDate)  & |
                          ' {5}EQUATE('& HolidayQ:HDate &')'& |
                          ' {5}!'& DOWname(HolidayQ:HDate) &' '& format(HolidayQ:HDate,@d3) &'  '& HolidayQ:HName )
                          
        OF ?CopyTimeBtn
            SetClipboard('Time_' & format(TheTime,@t04)  & |
                          ' {5}EQUATE(' & TheTime & ') {5}! ' & format(TheTime,@t4) &'  '& format(TheTime,@t6) &'  '& format(TheTime,@t05) )

!-- Time Tab ---------------------------------- 
        OF ?TimeNowBtn
            TheTime = INT((CLOCK()-1)/100) * 100 + 1   !No 1/100's
            DO LoadTimeQRtn
            DISPLAY
        OF ?RefreshTimeBtn
            DO LoadTimeQRtn
        OF ?TimeLeadBtn
            IF Picker.PickLead(?,'T',TimeLeading) THEN POST(EVENT:Accepted,?RefreshTimeBtn).
        OF ?TimeSepBtn
            IF Picker.PickSep(?,'T',TimeSeparator,'Colon :') THEN POST(EVENT:Accepted,?RefreshTimeBtn).

        OF ?List:TimeQ
            GET(TimeQ,CHOICE(?List:TimeQ))
            CASE KEYCODE()
            OF MouseLeft2
               SETCLIPBOARD(TimeQ:Pic)
            OF MouseRight
               CASE POPUP('Picture ' & TimeQ:Pic & '|FORMAT( ,' & TimeQ:Pic &')'& '|EQUATE('& TheTime &')|Time_'& Format(TheTime,@t04) &'  EQUATE('& TheTime &')' & |
                         '|-|Time Calculation Code H*360000+M*6000...|Time Calculation using TIME: Equates' )
               OF 1 ; SETCLIPBOARD(TimeQ:Pic)
               OF 2 ; SETCLIPBOARD('FORMAT( ,' & TimeQ:Pic & ') !' & TimeQ:Format )
               OF 3 ; SETCLIPBOARD('EQUATE(' & TheTime & ')   !' & FORMAT(TheTime,TimeQ:Pic) )
               OF 4 ; POST(EVENT:Accepted,?CopyTimeBtn)
      OF 5
            SETCLIPBOARD('!Time  '& FORMAT(TheTime,@t04)                 &' {13}= ' & TheTime &' = 1 + '& TheTime-1  &' /100th''s <13,10>' & | 
                         ' Time=('& FORMAT(TheTm:Hrs ,@n2) &' * 60*60*100) + |  !3600 Seconds in 1 Hour   *100=360,000  <13,10>' &|
                         '      ('& FORMAT(TheTm:Mins,@n2) &' *    60*100) + |  !  60 Seconds in 1 Minute *100=  6,000  <13,10>' &|
                         '      ('& FORMAT(TheTm:Secs,@n2) &' *       100) + |  !   1 Second  in 1 Second *100=    100  <13,10>' &|
                         '      ('& FORMAT(TheTm:Cent,@n2) &' *         1) + |  !Centiseconds i.e. 1/100th  *1=      1  <13,10>' &|
                         '      ('&                   '  ' &'   + 1      )      !Clarion Time always +1. Zero = No Time <13,10>'   )                          
      OF 6            
            SETCLIPBOARD('!Time  '& FORMAT(TheTime,@t04)                 &' {13}= ' & TheTime &' = 1 + '& TheTime-1  &' /100th''s <13,10>' & | 
                         ' Time=('& FORMAT(TheTm:Hrs ,@n2) &' * TIME:Hour  ) + | <13,10>' &|
                         '      ('& FORMAT(TheTm:Mins,@n2) &' * TIME:Minute) + | <13,10>' &|
                         '      ('& FORMAT(TheTm:Secs,@n2) &' * TIME:Second) + | <13,10>' &|
                         '      ('& FORMAT(TheTm:Cent,@n2) &' * TIME:Tick  ) + | <13,10>' &|
                         '      ('&                   '  ' &'   + 1      )      !Clarion Time always +1. Zero = No Time <13,10>'   ) 
               END
            END
        
!-- Calculate Dates Tab -------------------
        OF ?DateCalc_UseDateFixed ; DateCalc_UseDateFixV2=0
            POST(EVENT:Accepted, ?DateCalc_BaseMonth) ; POST(EVENT:Accepted, ?DateTwo_BaseMonth)
        OF ?DateCalc_UseDateFixV2 ; DateCalc_UseDateFixed=0
            POST(EVENT:Accepted, ?DateCalc_BaseMonth) ; POST(EVENT:Accepted, ?DateTwo_BaseMonth)        
        OF ?DateCalc_BaseMonth OROF ?DateCalc_BaseDay OROF ?DateCalc_BaseYear        
            DateCalc_BaseDate = DOO.DateOrDateFixed(DateCalc_BaseMonth,DateCalc_BaseDay,DateCalc_BaseYear)
            DO DateCalc_NetDate_Rtn
        OF ?DateCalc_BaseDate OROF ?DateCalc_BaseDate:D2
            DateSplit(DateCalc_BaseDate, DateCalc_BaseMonth, DateCalc_BaseDay, DateCalc_BaseYear)
            DO DateCalc_NetDate_Rtn
        OF ?DateCalc_PlusMonth OROF ?DateCalc_PlusDay OROF ?DateCalc_PlusYear
            DO DateCalc_NetDate_Rtn
        OF ?MonthNegativeFixBtn       ;  DOO.MonthNegativeFixBtnPressed()

        OF ?DateTwo_BaseMonth OROF ?DateTwo_BaseDay OROF ?DateTwo_BaseYear
            DateTwo_BaseDate = DOO.DateOrDateFixed(DateTwo_BaseMonth,DateTwo_BaseDay,DateTwo_BaseYear)
            DO DateTwo_NetDate_Rtn
        OF ?DateTwo_BaseDate OROF ?DateTwo_BaseDate:D2
            DateSplit(DateTwo_BaseDate, DateTwo_BaseMonth, DateTwo_BaseDay, DateTwo_BaseYear)
            DO DateTwo_NetDate_Rtn
        OF ?DateTwo_PlusDayz
            DO DateTwo_NetDate_Rtn

        OF ?DateCalc_DBtwD1 OROF ?DateCalc_DBtwD2
            DateCalc_DBtwDdays = DateCalc_DBtwD1 - DateCalc_DBtwD2    !Days Between
            DateCalc_DBtwDAge  = CHOOSE(DateCalc_DBtwDdays<0,'-'& AGE(DateCalc_DBtwD1,DateCalc_DBtwD2) ,AGE(DateCalc_DBtwD2,DateCalc_DBtwD1))
            DateCalc_DBtwD1_DOW = DOWNumAndName(DateCalc_DBtwD1)
            DateCalc_DBtwD2_DOW = DOWNumAndName(DateCalc_DBtwD2)

        OF ?DateCalc_AdjDtD1 TO ?DateCalc_AdjDtDays
            DateCalc_AdjDtD2 = DateCalc_AdjDtD1 + DateCalc_AdjDtDays  !Days Adjust
            DateCalc_AdjDtD1_DOW = DOWNumAndName(DateCalc_AdjDtD1)
            DateCalc_AdjDtD2_DOW = DOWNumAndName(DateCalc_AdjDtD2)

        OF ?EvalCalc_Input ; EvalCalc_Result=EVALUATE(EvalCalc_Input) 
                             IF ERRORCODE() THEN EvalCalc_Result='Error '& ErrorCode() &' '& Error() . 
                             IF ?EvalCalc_Input{PROP:Visible} THEN SELECT(?EvalCalc_Input,1).

!-- Number Tab -------------------                        
        OF ?ClearNumPicBtn  ; FREE(NumberQ) ; DISPLAY 
        OF ?NumInput:Pic
                IF LEN(CLIP(NumInput:Pic)) >2 AND NumInput:Pic[1]<>'@' THEN NumInput:Pic='@' & NumInput:Pic.
                IF ~NumInput:Pic THEN NumInput:Pic=NumQ:Pic.    !'@n-15.2'.
                DOO.NumbQAdd(NumInput:Pic,NumInput:RawValue,,NumberInpGrp) ; display
                IF ~INLIST(lower(NumInput:Pic[1:2]),'@n','@e','@p','@d','@t','@s','@k') THEN 
                    Message('Expected Clarion Pictures |are @N @E @P @D @T @S','Numbers')
                    SELECT(?NumInput:Pic)
                END
                ?NumInput:RawValue_Picture{PROP:Text}=CLIP(NumInput:Pic)
                DISPLAY
        OF ?NumInput:RawValue
                IF ~NumInput:RawValue THEN NumInput:RawValue='0'.
                IF ~NUMERIC(NumInput:RawValue) THEN 
                    Message('The Value must be Numeric','Numbers')
                    NumInput:RawValue=DEFORMAT(NumInput:RawValue)
                END                
                DOO.NumbQAdd(NumInput:Pic,NumInput:RawValue,,NumberInpGrp) ; display
        OF ?AddNumPicBtn
            NumberQ = NumberInpGrp
            GET(NumberQ,NumQ:Pic,NumQ:RawValue)
            IF ~ERRORCODE() THEN
                SELECT(?List:NumberQ,POINTER(NumberQ))
            ELSE 
                ADD(NumberQ,1) ; SELECT(?List:NumberQ,1)
            END
        OF ?CopyNumBtn     
            IF ~CHOICE(?List:NumberQ) THEN SELECT(?List:NumberQ,1).
            GET(NumberQ,CHOICE(?List:NumberQ)) 
            IF NumInput:Pic <> NumQ:Pic THEN 
               CASE PopupUnder(?,'Equate for Input Picture '& CLIP(NumInput:Pic) &'<9>'&  CLIP(NumInput:Formatted) & |
                                 '|-|Equate for Selected List '& CLIP(NumQ:Pic)  &'<9>'&  CLIP(NumQ:Formatted) )
               OF 1 ; NumberQ = NumberInpGrp 
               OF 2 
               ELSE ; CYCLE
               END 
            END 
            SetClipboard('ePicture_@     EQUATE('''& clip(NumQ:Pic) &''')     !FORMAT('& clip(NumQ:RawValue) &','& clip(NumQ:Pic) &') => ' & NumInput:Formatted )            

        OF ?List:NumberQ
            GET(NumberQ,CHOICE(?List:NumberQ))
            CASE KEYCODE()
            OF MouseLeft2
               NumInput:Pic       = NumQ:Pic
               NumInput:RawValue  = NumQ:RawValue
               NumInput:Formatted = NumQ:Formatted
               POST(EVENT:Accepted, ?NumInput:Pic)
            OF MouseRight
               CASE POPUP('Copy Picture ' & NumberQ:Pic & '|Copy FORMAT( , ' & CLIP(NumberQ:Pic) &' )|-|Set Input to ' & NumberQ:Pic &'|Set DeFormat() to ' & NumberQ:Pic )
               OF 1 ;  SETCLIPBOARD(NumberQ:Pic)
               OF 2 ;  SETCLIPBOARD('FORMAT( ,' & NumberQ:Pic & ') !' & NumQ:Formatted )
               OF 3 ;  NumberInpGrp = NumberQ ; POST(EVENT:Accepted, ?NumInput:Pic) ; Display
               OF 4 ;  DeFmt:Picture=NumQ:Pic ; DeFmt:RawValue=NumQ:RawValue ; display ; POST(EVENT:Accepted,?DeFmt:RawValue)
               END
            END

        OF ?DeFmt:RawValue OROF ?DeFmt:Picture
           IF ~DeFmt:RawValue AND ~DeFmt:Picture THEN 
              DeFmt:Format1='' ; DeFmt:Format2=''
           ELSE 
              DeFmt:Format1=DEFORMAT(DeFmt:RawValue)
              DeFmt:Format2=DEFORMAT(DeFmt:RawValue,CLIP(DeFmt:Picture) )
              ?DeFmt:Format1{PROP:Tip}='DEFORMAT( ''' & CLIP(DeFmt:RawValue) &''' )  No @Picture'
              ?DeFmt:Format2{PROP:Tip}='DEFORMAT( ''' & CLIP(DeFmt:RawValue) &''' , '& CLIP(DeFmt:Picture) &' )'
              display
           END 

        OF ?ReRunBtn ; START(MainTool,,0{PROP:Xpos}+20,0{PROP:Ypos}+20) ; UNHIDE(?HaltBtn)
        OF ?HaltBtn  ; IF 1=Message('Terminate this Tool?',0{PROP:Text},ICON:Hand,'Keep Open|Halt Tool') THEN CYCLE.
                       LOOP Ndx=1 TO 64 ; POST(EVENT:CloseWindow,,Ndx,1) ; END
        END
        CASE FIELD()
        OF ?List:DatesQ
           CASE EVENT()
           OF EVENT:HeaderPressed
              CASE ?List:DatesQ{PROPList:MouseDownField}
              OF 1 ; SORT(DatesQ,DateQ:SortPic)
              OF 2 ; SORT(DatesQ,DateQ:SortFmt)
              OF 3 ; SORT(DatesQ,DateQ:Value)
              END
           END 
        END
        CASE EVENT()
!TODO is this code working like I want ????
        OF EVENT:NewSelection OROF EVENT:Accepted
           CASE ?Sheet1{PROP:ChoiceFEQ}
           OF ?Tab:Date
               DOW = DOWOrdinal(TheDate) &' '& DOWname(TheDate) & ' (' & TheDate % 7 & ')'
               DO BuildCalendarAndDatesQRtn

           OF ?Tab:Time !Tab for Time
              IF FIELD()=?Sheet1        !We just changed tabs
                 IF ~TheTime
                     TheTime = INT((CLOCK()-1)/100) * 100 + 1    !No 1/100's
                     DO LoadTimeQRtn
                 END
              END
           END
           CASE FIELD()
           OF ?HolidayYear
              DO HolidayCalcRtn ; DISPLAY
           END
!TODO for all Type=SPIN on NewSelection Post Accepted
        OF EVENT:OpenWindow
            ?List:DatesQ{PROP:Selected} = 1
            SELECT(?TheDate)
        OF EVENT:Rejected ; DISPLAY(?) ; SELECT(?) ! ; ?{PROP:Color}=COLOR:Yellow                   
        END
    end
    close(Window)
!-----------------------------------------
DateCalc_NetDate_Rtn ROUTINE
    DATA
Clr_Back LONG(0DDDDFFh)    !Background  Light Red  RGB (255,221,221) 
Clr_Text LONG(COLOR:Black) !Font Text
    CODE
    DateCalc_NetMonth = DateCalc_BaseMonth + DateCalc_PlusMonth
    DateCalc_NetDay   = DateCalc_BaseDay   + DateCalc_PlusDay  
    DateCalc_NetYear  = DateCalc_BaseYear  + DateCalc_PlusYear 
    DateCalc_NetDate  = DOO.DateOrDateFixed(DateCalc_NetMonth,DateCalc_NetDay,DateCalc_NetYear)
    IF DateCalc_PlusMonth >=0 AND DateCalc_NetMonth >=0     THEN Clr_Back = -1 ; Clr_Text = -1.
    IF DateCalc_UseDateFixed OR DateCalc_UseDateFixV2       THEN Clr_Back = -1 ; Clr_Text = -1.
    IF BAND(KEYSTATE(),4000h)=4000h                         THEN Clr_Back = -1 ; Clr_Text = -1.     !Scroll Lock ON does not Warn to allow Screen Captures
    ?DateCalc_PlusMonth{PROP:Color}  = Clr_Back ; ?DateCalc_PlusMonth{PROP:FontColor}  = Clr_Text
    ?MonthNegativeFixBtn{PROP:Color} = Clr_Back ; ?MonthNegativeFixBtn{PROP:FontColor} = Clr_Text 
    DateCalc_Base_DOW = DOWNumAndName(DateCalc_BaseDate)
    DateCalc_NetD_DOW = DOWNumAndName(DateCalc_NetDate)
    EXIT

DateTwo_NetDate_Rtn ROUTINE 
    DateTwo_NetDate  = DOO.DateOrDateFixed(DateTwo_BaseMonth,DateTwo_BaseDay,DateTwo_BaseYear) + DateTwo_PlusDayz
    DateTwo_Base_DOW = DOWNumAndName(DateTwo_BaseDate)
    DateTwo_NetD_DOW = DOWNumAndName(DateTwo_NetDate)    
    EXIT

!-----------------------------------------
BuildNumberQRtn        ROUTINE
    !@N [currency] [sign] [fill] size [grouping][places][sign] [currency] [B]
    !   $ or ~XX~   - (    0*_   ##    . - _     .`v ##  - )    $ or ~XX~
    !                        _ for spaces
    DOO.NumbQAdd('@n$-_15.2',-1234567.89)   ; NumberInpGrp = NumberQ            !Default for Number Input ENTRYs
    DOO.NumbQAdd('@n15.2'   ,-1234567.89)
    DOO.NumbQAdd('@n$15.2'  ,-1234567.89)
    DOO.NumbQAdd('@n-15.2'  ,-1234567.89)
    DOO.NumbQAdd('@n_15.2'  ,-1234567.89)
    DOO.NumbQAdd('@n-_15.2' ,-1234567.89)
    DOO.NumbQAdd('@n-015.2' ,-1234567.89)
    DOO.NumbQAdd('@n*15.2-' ,-1234567.89)
    DOO.NumbQAdd('@n$-15.2' ,-1234567.89)
    DOO.NumbQAdd('@n$(15.2)',-1234567.89)
    DOO.NumbQAdd('@n$-_15.2',-1234567.89)
    DOO.NumbQAdd('@n$(_15.2)',-1234567.89)   !
    DOO.NumbQAdd('@n15`2~kr~'  ,-1234567.89)
    DOO.NumbQAdd('@n~kr~-15`2' ,-1234567.89)
  !  DOO.NumbQAdd('@n-15-2',1234567.89)  no dash grouping does not work
    DOO.NumbQAdd('@n-8.2~%~',-100.89)
    DOO.NumbQAdd('@n7.5b'   ,0.12345)
    DOO.NumbQAdd('@n~X~1b',1)
    DOO.NumbQAdd('@n~Yes~3b',1)

    DOO.NumbQAdd('@e15.1',-1234567.89)
    DOO.NumbQAdd('@e15.2',-1234567.89)

    DOO.NumbQAdd('@p###-##-####p','078051120')     !SSN not valid issued by Woolworth with wallet
    DOO.NumbQAdd('@p***-**-####p',     1120)     !SSN Masked
    DOO.NumbQAdd('@p##-#######p' ,801234567)     !FEIN
    DOO.NumbQAdd('@p#####-####p' ,'021124321')     !Zip+4 Boston
    !DOO.NumbQAdd('@P<#/##/#### Magna CartaP' ,'06151215')     !Date with no Limit of 1800
    DOO.NumbQAdd('@P<#/##/#### IndependenceP' ,'07041776')     !Date with no Limit of 1800 or Date in MMDDYYYY form
    DOO.NumbQAdd('@PFY ####-####' ,YEAR(TheDate)*10000+YEAR(TheDate)+1)     !Fiscal Year e.g. 2024-2025
    DOO.NumbQAdd('@pPage <<<<#p' ,42)                        !              !Example of "P" as [x]
    DOO.NumbQAdd('@P(###)###-####P',3057854555)  !From the Help
    DOO.NumbQAdd('@P###/###-####P' ,7854555    ) !000/785-4555
    DOO.NumbQAdd('@P<#/##/##P   '  ,103159     ) !10/31/59
    DOO.NumbQAdd('@p<#:##PMp    '  ,530        ) !5:30PM
    DOO.NumbQAdd('@P<#'' <#"P   '  ,506        ) !5'  6"
    DOO.NumbQAdd('@P<#lb. <#oz.P'  ,902        ) !9lb. 2oz.
    DOO.NumbQAdd('@P4##A-#P     '  ,112        ) !411A-2
    DOO.NumbQAdd('@PA##.C#P     '  ,312.45     ) !A31.C2

    DOO.NumbQAdd('@d02-',452598)            !dates work = 02/29/3040 
    DOO.NumbQAdd('@t8'  ,6120001)           !times work = 5 o'clock somewhere
    EXIT

BuildCalendarAndDatesQRtn    ROUTINE
     DATA
LOC:Date    LONG,AUTO
LOC:Month   LONG,AUTO
LOC:Year    LONG,AUTO
LOC:Day     LONG,AUTO
LOC:DayNdx  LONG,AUTO
!    CalFirstday LONG
!    CalMonth    LONG
!    CalYear     LONG
!    CalTitle    STRING(20)
     CODE
     DateSplit(TheDate,LOC:Month, ,LOC:Year)
     IF CalMonth=LOC:Month AND CalYear=LOC:Year THEN EXIT.  !same Month and Year so no need to change calendar
        CalMonth=LOC:Month  ;  CalYear=LOC:Year

     CalTitle    = LOWER(FORMAT(TheDate,@D4))       !June 28, 2024  i.e. Mmmmm dd, yyyy
     CalTitle[1] = UPPER(CalTitle[1])               
     LOC:Day     = INSTRING(' ',CalTitle)           !    ^ Space 1
     CalTitle=SUB(CalTitle,1,LOC:Day) & LOC:Year    !June 2024 = Mmmmm yyyy

     LOC:Date = Date(LOC:Month,1,LOC:Year)
     LOC:DayNdx = 1 + LOC:Date % 7
     LOC:Day    = 1
     CLEAR(Days[])
     LOOP
       Days[ LOC:DayNdx ] = FORMAT(LOC:Day,@n2)
       LOC:Day    += 1
       LOC:DayNdx += 1
       LOC:Date   += 1
       IF MONTH(LOC:Date) <> LOC:Month THEN BREAK.
    END
    DO LoadDatesQRtn           !If month changes then refresh list
    DISPLAY

LoadDatesQRtn    Routine
    DATA
Date_03_22_1999  EQUATE(72402) ! 03/22/1999  1999-03-22  22-MAR-1999  Monday March 22, 1999    
    CODE
    FREE(DatesQ)
    LOOP PicNdx = 1 TO 18
         DateQ:Pic   ='@d0' & PicNdx & CLIP(DateSeparator)            !Need @d0 Leading 0 for 03 
         DateQ:Format = format( Date_03_22_1999 ,DateQ:Pic)
         ReplaceChar(DateQ:Format,'03'   ,'mm')
         ReplaceChar(DateQ:Format,'MARCH','Nnnnn',True)     !More International to Loop each Char looking for
         ReplaceChar(DateQ:Format,'MAR'  ,'NNN'  ,True)     !  If IsAlpha() and then If IsUpper() 'M' else 'm'
         ReplaceChar(DateQ:Format,'22'   ,'dd')
         ReplaceChar(DateQ:Format,'1999' ,'yyyy')
         ReplaceChar(DateQ:Format,'99'   ,'yy')
         DateQ:SortPic = PicNdx
         DateQ:SortFmt = lower(LettersOnly(DateQ:Format)) &' /'& lower(DateQ:Format)
         CASE PicNdx
         OF 17 ; DateQ:Format='Short: '& DateQ:Format
         OF 18 ; DateQ:Format='Long: ' & DateQ:Format
         END       
         DateQ:Pic   ='@d' & CLIP(DateLeading) & PicNdx & CLIP(DateSeparator)
         DateQ:Value = left(format(TheDate,DateQ:Pic))
         ADD(DatesQ)
    END
    EXIT

RefreshDatesQRtn    Routine    !not used currently
    IF ~RECORDS(DatesQ) THEN
        DO LoadDatesQRtn
        EXIT
    END
    LOOP PicNdx = 1 TO 18
         GET(DatesQ,PicNdx)
         DateQ:Value = left(format(TheDate,DateQ:Pic))
         PUT(DatesQ)
    END
    DISPLAY
    EXIT

LoadTimeQRtn    Routine 
    DATA
Time_11:22:33  EQUATE(4095301)     ! 11:22:33.44  11:22:33AM
TimeFmt  LIKE(TimeQ:Format)   
    CODE
    FREE(TimeQ)
    LOOP PicNdx = 1 TO 8 
         TimeQ:Pic   ='@t' & CLIP(TimeLeading) & PicNdx & CLIP(TimeSeparator)
         TimeFmt = FORMAT(Time_11:22:33, TimeQ:Pic )
         ReplaceChar(TimeFmt,'11','hh')
         ReplaceChar(TimeFmt,'22','mm')
         ReplaceChar(TimeFmt,'33','ss')
         ReplaceChar(TimeFmt,'AM','XM',True)
         CASE PicNdx
         OF 7 ; TimeFmt='Short: ' & TimeFmt
         OF 8 ; TimeFmt='Long: '  & TimeFmt
         END 
         TimeQ:Format=TimeFmt
         TimeQ:Value = left(format(TheTime,TimeQ:Pic))
         ADD(TimeQ)
    end
    EXIT

!    @Tn[s][B]
!
!    @T    All time pictures begin with @T.
!
!    n    Determines the time picture format. Time picture formats range from 1 through 8. A leading zero (0) indicates zero-filled hours.
!    s    A separation character. By default, colon ( : ) characters appear between the hour, minute, and second components of certain time picture formats. The following s indicators provide an alternate separation character for these formats.
!             . (period) Produces periods  ' (grave accent) Produces commas  - (hyphen) Produces hyphens  _ (underscore) Produces spaces
!    B    Specifies that the format displays as blank when the value is zero.
!
!    Times may be stored in a numeric variable (usually a LONG), a TIME field (for Btrieve compatibility), or in a STRING declared with a time picture. A time stored in a numeric variable is called a "Standard Time."  The stored value is the number of hundredths of a second since midnight. The picture token converts the value to one of the eight time formats.
!    For those time pictures which contain string data, the actual strings are customizable in an Environment file (.ENV). See the Internationalization section for more information.
!
!    Example:
!
!    Picture    Format    Result
!
!    @T1    hh:mm    17:30
!    @T2    hhmm    1730
!    @T3    hh:mmXM    5:30PM
!    @T03    hh:mmXM    05:30PM
!    @T4    hh:mm:ss    17:30:00
!    @T5    hhmmss    173000
!    @T6    hh:mm:ssXM    5:30:00PM
!    @T7        Windows Control Panel setting for Short Time
!    @T8        Windows Control Panel setting for Long Time
!
!         Alternate separators                    
!    @T1.    hh.mm    Period separator
!    @T1-    hh-mm    Dash separator
!    @T3_    hh mmXM     Underscore produces space separator
!    @T4'    hh,mm,ss    Grave accent produces comma separator

HolidayCalcRtn  ROUTINE
    DATA
HoliDate    LONG,AUTO 
WasChoice   LONG
WasName     LIKE(HolidayQ:HName)
    CODE
    WasChoice=CHOICE(?List:HolidayQ)
    GET(HolidayQ,WasChoice) ; WasName = HolidayQ:HName
    
    IF HolidayYear < 1801 THEN HolidayYear = YEAR(TODAY()).
    FREE(HolidayQ)
    LOOP HoliDate = DATE(1,1,HolidayYear) TO DATE(12,31,HolidayYear) + 1    !show new years day the next year
         IF HolidayCheck(HoliDate,HolidayQ:HName, HolidayQ:HDow) THEN !  PROCEDURE(LONG pDate,<*string HolidayName>,<*string DOWName>)
            HolidayQ:HDate = HoliDate
            ADD(HolidayQ)
         END
    END
    HolidayQ:HDate = EasterDate(HolidayYear)
    HolidayQ:HName = 'Easter  (1st Sunday after full Moon on or after spring equinox)'
    HolidayQ:HDow  = 'Sunday'
    ADD(HolidayQ,HolidayQ:HDate)
    HolidayQ:HDate -= 2
    HolidayQ:HName = 'Good Friday'
    HolidayQ:HDow  = 'Friday'
    ADD(HolidayQ,HolidayQ:HDate)
!    LOOP QNdx=1 TO RECORDS(HolidayQ)    !Format a column as MM-DD  MMM DDD
!        GET(HolidayQ,QNdx)
!        HolidayQ.HMonDay=SUB(FORMAT(HolidayQ:HDate,@d02-),1,5) &'  '& SUB(FORMAT(HolidayQ:HDate,@d3),1,6)     !MMM DD, YYYY
!        PUT(HolidayQ)
!    END     
    ?LeapYearTxt{PROP:Hide}=CHOOSE(DAY(Date(3,1,HolidayYear)-1)=29,'','1')
    
    IF ~WasChoice OR WasChoice > RECORDS(HolidayQ) THEN WasChoice=1.    
    HolidayQ:HName = WasName
    GET(HolidayQ,HolidayQ:HName) ; IF ~ERRORCODE() THEN WasChoice=POINTER(HolidayQ).
    ?List:HolidayQ{PROP:Selected}=WasChoice     
    EXIT
!---------------------------
ToolTipsRtn ROUTINE
    ?DateCalc_UseDateFixed{PROP:TIP}='Check box to use DateFixed() instead of runtime DATE() function.' & |
           '<13,10>' & |
           '<13,10>From ClarionMag "A Better DATE Function" written by Carl Barnes' & |
           '<13,10>provides the DateFixed() function as a replacement for DATE() that' & |
           '<13,10>adjusts out of range values before calling DATE().' & |
           '<13,10>' & |
           '<13,10>C5 had problems with some out of range values and Leap Years' & |
           '<13,10>e.g. DATE(14,29,1999). Also it counted Month of Zero as Month 1.' & |
           '<13,10>' & |
           '<13,10>C5.5 and C6 fixed the Leap Year problems.' & |
           '<13,10>If Month is Zero or Negative it incorrectly returns -1.' & |
           '<13,10>If Day or Negative is Zero that works correctly.' & |
           '<13,10>' & |
           '<13,10>Test out of range values to see if there is still a use for DateFixed() ?' & |
           '<13,10>'

    ?DateCalc_UseDateFixV2{PROP:TIP}='Check box to use DateFixV2() instead of runtime DATE() function.' & |
            '<13,10>' & |    
            '<13,10>Simpler code for C8 - C11 only needs to handle Month <<= Zero.' & |
            '<13,10>Changes Negative Months to Add (Month % 12) then Subtracts Years.'

    ?Num_Syntax_AllParts{PROP:Tip}='Hover below this Syntax line to see tips on the values below ' & |
                            '<13,10>the parts: [currency][sign][fill] size [grouping][places][sign][currency][B]'
                            
    ?NSyntax_Curr1 {PROP:Tip}= |      !'$ ~xx~' 
           '[currency]' & |
           '<13,10>Either a Dollar Sign ($) or any string constant enclosed in Tildes (~).' & |
           '<13,10>' & |
           '<13,10>When it precedes the sign indicator and there is no [fill] indicator, the currency symbol "floats" to' & |
           '<13,10>the left of the high order digit. If there is a [fill] indicator, the currency symbol remains fixed in the' & |
           '<13,10>left-most position. If the currency indicator follows the [size] and [grouping], it appears at the end' & |
           '<13,10>of the number displayed.' & |
           '<13,10>'
    ?NSyntax_Sign1 {PROP:Tip}= |      !'-('         SIGN
           '[sign]' & |
           '<13,10>Specifies the display format for negative numbers.' & |
           '<13,10>If a Hyphen "-" precedes the [fill] and [size] indicators,' & |
           ' negative numbers display with a Leading Minus Sign.' & |
           '<13,10>If a Hyphen "-" follows the [size], [places], and [currency] indicators,' & |
           ' negative numbers display with a Trailing Minus Sign.' & |
           '<13,10>If Parentheses "()" are placed in both positions,' & |
           ' negative numbers will be displayed enclosed in parentheses.' & |
           '<13,10>' & |
           '<13,10>To prevent ambiguity, a trailing minus sign should always have [grouping] specified.' & |
           '<13,10>'    
    ?NSyntax_Fill  {PROP:Tip}= |      !'_*0'        FILL
           '[fill]' & |
           '<13,10>Specifies leading Zeros (0), Spaces (_), or Asterisks (*)' & |
           '<13,10>in any leading zero positions,' & |
           '<13,10>and suppresses default [grouping].' & |
           '<13,10>If the [fill] is omitted, leading zeros are suppressed.' & |
           '<13,10>' & |
           '<13,10,9>0 (zero) produces leading Zeroes' & |
           '<13,10,9>_ (underscore) produces leading Spaces' & |
           '<13,10,9>* (asterisk) produces leading Asterisks' & |
           '<13,10>'    
    ?NSyntax_Size  {PROP:Tip}= |      !'##'         SIZE
           '[size]' & |
           '<13,10>The [size] is required to specify the total number of significant digits to' & |
           '<13,10>display, including the number of digits in the [places] indicator and any' & |
           '<13,10>formatting characters for [currency], [sign], [grouping], [places] etc.' & |
           '<13,10>'    
    ?NSyntax_Group {PROP:Tip}= |      !'._'         GROUPING
           '[grouping]' & |
           '<13,10>A [grouping] symbol, other than a comma (the default), can appear' & |
           '<13,10>right of the [size] indicator to specify a three digit group separator.' & |
           '<13,10>' & |
           '<13,10><9>. (period) produces periods' & |
           '<13,10><9>_ (underscore) produces spaces for grouping' & |
           '<13,10>'
    
    ?NSyntax_Places{PROP:Tip}= |      !'.`v ##'
           '[Places]' & |
           '<13,10>Specifies the decimal separator symbol and the number of decimal digits. The number of decimal digits' & |
           '<13,10>must be less than the [size]. For example "6.2" formats as "123.45".' & |
           '<13,10>' & |
           '<13,10>The decimal separator may be a period (.), a grave accent (`) (produces periods [grouping] unless' & |
           '<13,10>overridden), or the letter "v" (used only for STRING field storage declarations, not for display).' & |
           '<13,10>' & |
           '<13,10><09H>. (period) produces a period decimal separator' & |
           '<13,10><09H>` (grave accent) produces a comma decimal separator' & |
           '<13,10><09H>v (letter "v") produces no decimal separator' & |
           '<13,10>'
    ?NSyntax_Sign2 {PROP:Tip}=?NSyntax_Sign1 {PROP:Tip}     !'-)'
    ?NSyntax_Curr2 {PROP:Tip}=?NSyntax_Curr1{PROP:Tip}      !'$ ~xx~'
    ?NSyntax_Blank {PROP:Tip}='"B" Specifies blank display whenever its value is zero'

    ?Syntax_AtPp{PROP:TIP}='Pattern pictures begin with the @P delimiter and end with the P delimiter.  ' & |
           '<13,10>The case of the delimiters must be the same. This allows [X] to use a "P" or "p".  ' & |
           '<13,10>' & |
           '<13,10>[<<]  Specifies an integer number position that is blank for leading zeroes' & |
           '<13,10>[#]  Specifies an integer number position' & |
           '<13,10>[X]  Optional display characters that appear in the final result string' & |
           '<13,10>' & |
           '<13,10>Pp  Pattern pictures must end with an upper case "P" or a lower case "p"' & |
           '<13,10>' & |
           '<13,10>[B]   Blank when the value is zero' & |
           '<13,10>' & |
           '<13,10> that matches the case of the beginning "P" or "p"' & |
           '<13,10>'
     ?Syntax_AtE{PROP:TIP}='@E Scientific Notation Pictures' & |
           '<13,10>' & |
           '<13,10>[m] <9>Total number of characters in the format picture  ' & |
           '<13,10>[s] <9>Decimal separation and grouping character' & |
           '<13,10>[n] <9>Number of digits that appear left of the decimal point  ' & |
           '<13,10>[B] <9>Displays as blank when the value is zero' & |
           '<13,10>' & |
           '<13,10>Separation and grouping characters for [s] when [n] is greater than 3:  ' & |
           '<13,10>     .  (period)  Period and Comma' & |
           '<13,10>     .. (period period)   Period and Period' & |
           '<13,10>     `  (grave accent) Comma and Period' & |
           '<13,10>     _. (underscore period)  Period and Space' & |
           '<13,10>'    !@e # [. .. ` _.] #

    EXIT


! ####### Main Procedure Local Procedures in CLASS #################################################################
DOO.NumbQAdd PROCEDURE(string ThePicture, string TheValue, bool bAddFirst=0, <*NumberInpGrp OutNumberInput>)
Num2DoGrp   GROUP(NumberQ),PRE(Num2Do)
            END 
    CODE
    Num2Do:Pic        = left(ThePicture)     
    Num2Do:RawValue   = left(TheValue)
    Num2Do:Formatted  = left(format(Num2Do:RawValue,Num2Do:Pic))
    IF ~OMITTED(OutNumberInput) THEN 
        OutNumberInput = Num2DoGrp
    ELSE
        NumberQ = Num2DoGrp 
        IF bAddFirst THEN ADD(NumberQ,1) ELSE ADD(NumberQ).
    END 
    return
!------------
DOO.DateOrDateFixed PROCEDURE(long _Month,long _Day,long _Year)!,long   !Calls DATE() or DateFixed() based on DateCalc_UseDateFixed
StdDate LONG,AUTO
    CODE
    IF DateCalc_UseDateFixV2 THEN 
         StdDate = DATEfixV2(_Month,_Day,_Year)
 ELSIF DateCalc_UseDateFixed THEN 
         StdDate = DATEfixed(_Month,_Day,_Year)
    ELSE       
         StdDate =      DATE(_Month,_Day,_Year)
    END    
    RETURN StdDate
!---------------
DOO.MonthNegativeFixBtnPressed  PROCEDURE()
MinusMos  LONG 
FixMosPos LONG   !Calc of Date(Months,,)      as Postive  i.e. to Add
FixYrsNeg LONG   !Calc of DATE(      ,,Years) as Negative i.e. to Subtract
MakNegMos LONG
MosDiv12  DECIMAL(9,3)   !So Message Year Calc only shows 3 decimals
FYI_Month LONG
FYI_Day   LONG
FYI_Year  LONG
    CODE
    SELECT(?DateCalc_PlusMonth)
    MinusMos = DateCalc_PlusMonth    !A Shorter Variable
    IF MinusMos >= 0 THEN   !There is no problem ... offer to mess it up
       MakNegMos = CHOOSE(DateCalc_BaseMonth<0, DateCalc_BaseMonth, (DateCalc_BaseMonth * -1) - 1 )
       CASE Message('The Change Month "' & MinusMos &'" is not negative so there is nothing to Fix.' & |
                    '||Click "Make Negative" and I''ll change Month to "' & MakNegMos &'" to create a problem.' , | 
                    'Negative Month',,'Close|Make Negative')
       OF 1 ; RETURN
       OF 2 ; MinusMos = MakNegMos ; DateCalc_PlusMonth = MakNegMos
              IF DateCalc_BaseMonth<0 THEN DateCalc_BaseMonth=1.
              DO DateCalc_NetDate_Rtn ; DISPLAY
       END 
    END
    FixMosPos = MinusMos % 12               !e.g. (-1 % 12) = +11 ; (-9 % 12) = +3  remainder of year
!was FixYrsV1 = INT((MinusMos+1) /-12) +1   !version 1 of Calc works but result was Positive. Also "+1)/-12" looks odd. Below is shorter
    FixYrsNeg = INT((MinusMos+1) /12) -1    !This does not need an INT() if assigning to a LONG. an INT() is needed if it were in a Message() or with REAL or DECIMAL
    MosDiv12  =     (MinusMos+1) /12        !Division with 3 decimals for Message
    FYI_Month = DateCalc_BaseMonth + FixMosPos
    FYI_Day   = DateCalc_BaseDay   + DateCalc_PlusDay  
    FYI_Year  = DateCalc_BaseYear  + DateCalc_PlusYear + FixYrsNeg

    CASE Message('The C11 DATE() function passed a Negative or Zero Month will FAIL and Return -1.' & |
                '||Instead of Negative Months "'& MinusMos &'"' & |
                '|   Change to Positve Months  "+'& FixMosPos &'"' & |
                '|   Change to Negative Years   "'& FixYrsNeg &'"' & |
                        CHOOSE(DateCalc_PlusYear=0,'',' ... ( + '& DateCalc_PlusYear &' = '& DateCalc_PlusYear + FixYrsNeg &' Years)') & |
                '||Calculation:' & |
                '|    M = '& MinusMos & '  Months to Subtract' & |
                '|    Months+ = (M % 12)  =  ('& MinusMos &' % 12 ) = ' &  FixMosPos & |
                '|    Years- = Int((M+1)/12)-1 = Int(('& MinusMos &'+1)/12)-1 = Int('& MosDiv12 &')-1 = '& Int(MosDiv12) &'-1 = '& FixYrsNeg & |
                '||FYI - Return Date of Various (Month,Day,Year) Values and Functions: ' & |
                '|'& DOO.MonthNegFyiDate('RTL  DATE' , DateCalc_NetMonth, DateCalc_NetDay, DateCalc_NetYear, '-Months') & |
                '|'& DOO.MonthNegFyiDate('RTL  DATE' , FYI_Month,         FYI_Day,         FYI_Year,         '+Mos -Yrs') & | 
                '|'& DOO.MonthNegFyiDate('DateFixed', DateCalc_NetMonth, DateCalc_NetDay, DateCalc_NetYear, '-Months') & |
                '|'& DOO.MonthNegFyiDate('DateFixed', FYI_Month,         FYI_Day,         FYI_Year,         '+Mos -Yrs') & |
                '|'& DOO.MonthNegFyiDate('DateFixV2', DateCalc_NetMonth, DateCalc_NetDay, DateCalc_NetYear, '-Months') & |
                '|'& DOO.MonthNegFyiDate('DateFixV2', FYI_Month,         FYI_Day,         FYI_Year,         '+Mos -Yrs') & |
                '','DATE() with Month Adjust Negative',Icon:Clarion, '&Fix -Months|&No Fix')
    OF 1 ; DateCalc_PlusMonth = FixMosPos
           DateCalc_PlusYear += FixYrsNeg 
           DO DateCalc_NetDate_Rtn ; DISPLAY
    END 
    RETURN   
   
DOO.MonthNegFyiDate PROCEDURE(STRING DateFctName, LONG FyiMonth, LONG FyiDay, LONG FyiYear, STRING FyiSuffixNote)!,STRING
FctValue LONG,AUTO
ValueStr PSTRING(12),AUTO
FmtValue PSTRING(16),AUTO
    CODE
    CASE UPPER(DateFctName)  !Yes Mark should be EQUATEs ... but only 3 and called just 10 lines above
    OF 'RTL  DATE'  ; FctValue =      Date(FyiMonth,FyiDay,FyiYear)
    OF 'DATEFIXED'  ; FctValue = DateFixed(FyiMonth,FyiDay,FyiYear)
    OF 'DATEFIXV2'  ; FctValue = DateFixV2(FyiMonth,FyiDay,FyiYear)
    ELSE            ; RETURN '???? Unknown DateFctName="'& DateFctName &'" in DOO.MonNegFyiDate() ????'
    END
    FmtValue = CHOOSE(FctValue=-1,'##/##/####',FORMAT(FctValue,@d02))
    ValueStr = CHOOSE(FctValue=-1,'???  -1','' & FctValue)
    RETURN ' {8}'& DateFctName &'( '& FyiMonth &' , '& FyiDay &' , '& FyiYear &' ) => '& ValueStr &' => '& FmtValue &'  ('& FyiSuffixNote &')'

!--Local Picker Class -----------------------

Picker.PickLead PROCEDURE(long BtnFEQ, string TypeDTN, *string LeadChar)!,bool        !returns was picked
    code
    !Lead Date: ' ' 0 * _           Lead Time: ' ' 0 * _ 
    free(pickQ)
    PickQ:Char=' ' ; PickQ:Name = 'Space<9>Default' ; ADD(PickQ)
    PickQ:Char='0' ; PickQ:Name = 'Zero<9>0'        ; ADD(PickQ)
    PickQ:Char='*' ; PickQ:Name = 'Asterisk<9>*'    ; ADD(PickQ)
    PickQ:Char='_' ; PickQ:Name = 'Underscore<9>_'  ; ADD(PickQ)   !Dates/Times work to Here

    PickQ:Char='|' ; PickQ:Name = '-'           ; ADD(PickQ)   !Popup Line ------------
    PickQ:Char='$' ; PickQ:Name = 'Dollar<9>$'  ; ADD(PickQ)
    PickQ:Char='!' ; PickQ:Name = 'Bang<9>!'    ; ADD(PickQ)
    PickQ:Char='#' ; PickQ:Name = 'Pound<9>#'   ; ADD(PickQ)
    PickQ:Char='^' ; PickQ:Name = 'Caret<9>^'   ; ADD(PickQ)
    PickQ:Char='&' ; PickQ:Name = 'Amperand<9>&'    ; ADD(PickQ)
    PickQ:Char='-' ; PickQ:Name = 'Hyphen<9>-'  ; ADD(PickQ)
    PickQ:Char='`' ; PickQ:Name = 'Grave Accent<9>`' ; ADD(PickQ)
    return SELF.PopupPicks(BtnFEQ,LeadChar,'Leading')

Picker.PickSep PROCEDURE(long BtnFEQ, string TypeDTN, *string SepChar, String DefaultName)!,bool        !returns was picked
    code
    !Separators Date: / and .`-_           Separators Time: : and .`-_

    free(pickQ)
    PickQ:Char=' ' ; PickQ:Name = DefaultName &'<9>Default'  ; ADD(PickQ)   !Passed 'Slash<9>/' or 'Colon<9>:' i.e. RIGHT(,1)=/ or :
    PickQ:Char='.' ; PickQ:Name = 'Period<9>.'               ; ADD(PickQ)
    PickQ:Char='`' ; PickQ:Name = 'Comma (Grave Accent)<9>`' ; ADD(PickQ)
    PickQ:Char='-' ; PickQ:Name = 'Hyphen (Dash)<9>-'        ; ADD(PickQ)
    PickQ:Char='_' ; PickQ:Name = 'Spaces (Underscore)<9>_'  ; ADD(PickQ)

    PickQ:Char='|' ; PickQ:Name = '-'               ; ADD(PickQ)   !Popup Line ------------
    PickQ:Char='*' ; PickQ:Name = 'Asterisk<9>*'    ; ADD(PickQ)
    PickQ:Char='$' ; PickQ:Name = 'Dollar<9>$'      ; ADD(PickQ)
    PickQ:Char='!' ; PickQ:Name = 'Bang<9>!'        ; ADD(PickQ)
    PickQ:Char='#' ; PickQ:Name = 'Pound<9>#'       ; ADD(PickQ)
    PickQ:Char='^' ; PickQ:Name = 'Caret<9>^'       ; ADD(PickQ)
    PickQ:Char='&' ; PickQ:Name = 'Ampersand<9>&'   ; ADD(PickQ)
    PickQ:Char='/' ; PickQ:Name = 'Slash<9>/'       ; ADD(PickQ)    !Dates get this by Default
    PickQ:Char=':' ; PickQ:Name = 'Colon<9>:'       ; ADD(PickQ)    !Times get this by Default
    return SELF.PopupPicks(BtnFEQ, SepChar,'Separator')

Picker.PopupPicks      procedure(long BtnFEQ, *string TheChar, String Title)!,bool
PkNdx    LONG,AUTO
PkPopup  STRING(512)
PkNum    LONG,AUTO
    CODE
    PkPopup='~'& clip(Title) & '|-'
    LOOP PkNdx = 1 TO RECORDS(PickQ)
         GET(PickQ,PkNdx)
         IF ERRORCODE() THEN BREAK.
         PkPopup=clip(PkPopup) & '|' & |
                    CHOOSE(PickQ:Char=TheChar,'+','') & |
                    PickQ:Name
         IF PickQ:Char = '|' THEN
            DELETE(PickQ)
            PkNdx -= 1
         END
    END
    PkNum = PopupUnder(BtnFEQ, PkPopup )

    IF PkNum < 2 THEN
       RETURN(0)
    END
    PkNum -= 1
    GET(PickQ,PkNum)
    TheChar=PickQ:Char
    RETURN(PkNum)

! ####### MAP Global Procedures #######################################################################
!----------------------------------
DateFixV2  PROCEDURE(LONG _Month,LONG _Day,LONG _Year)!,LONG        !Version 2 for C8 - C11 that fails if Month Zero or Negative 
! AFAIK in C8 - C11 the Leap Year problems corrected by V1 of DateFixed() below are fixed. 
! The problem is MONTH cannot be Zero or Negative.
! This Version 2 DateFixV2() was created as much simpler that V1 DateFixed to just fix Months.
FixMosPositive LONG,AUTO
FixYrsNegative LONG,AUTO 
    CODE
    IF _Month <= 0 AND _Year > 1801 THEN    !Month <=0 with Valid Year (can't = 1801 since -1=1800 is invalid and Date(,,1800) returns -1)
       IF _Month < 0 THEN                   !Negative  Month < 0 
          FixMosPositive = _Month % 12             !e.g. (-1 % 12) = +11 ; (-9 % 12) = +3  remaining Months of 12
          FixYrsNegative = INT((_Month+1) /12) -1  !This does not need an INT() if assigning to a LONG. an INT() is needed if it were in a Message() or with REAL or DECIMAL
          _Month = FixMosPositive           !Month as + Remaining Months of 12 i.e. Remainder 
          _Year += FixYrsNegative           !Make Years Negative  .. possible to be < 1801 but not expecting to work with that old of dates
       END  !FYI "IF _Month=0" may be true if above (Month %12) sets Month=0, so do NOT make below an ELSIF _Month=0
       IF _Month = 0 THEN                   !Date is (0, Days, Valid Year) - Year cannot be 1801 because we will be subtracting
          _Month = 12                       !Month Zero is December 
          _Year -= 1                        !   of the Prior Year
       END     
    END     
    RETURN DATE(_Month, _Day, _Year)
!----------------------------------
DateFixed            FUNCTION(long _Month,long _Day,long _Year)!,LONG   !Deal with C5 C5.5 C6 DATE() function issues
RetDate     long,auto
YrsAdj      long,auto
  CODE
    ! From ClarionMag on 2006-01-09 "A Better DATE Function" by Carl Barnes. Included in Repo.
    ! http://www.clarionmag.com/cmag/v8/v8n01betterdate.html    
    ! Carl Barnes improves on the standard Clarion DATE function with a version that corrects a bug and works with negative month and day values.
    !-----------------------------------------------------------------------------------------------
    !Passing Date Function a Negative or Zero, Month or Day Does not work, it returns a bad value
    !C5 had a bug with 14/29/1999 not seeing it as 2/2000 and as a Leap Year so returned 3/1/2000 instead of 2/29/2000. 
    !It also failed on negative days like DATE(1,-15,2000) returning -1 instead of 12/16/1999.
    !So try to get the date parts into correct range values before using Clarion Date()
    !A bug discovered 11/2007 if Month is zero in 5.0 it calcs wrong, date(0,1,2007) should be 12/31/06 but returns 1/1/07
    !In 5.5 and C6 DATE(m,d,y) with Month <= 0 Returns -1
    !-----------------------------------------------------------------------------------------------

    IF ~_Month AND ~_Day AND ~_Year THEN RETURN 0.       !If all zeros then do not adjust

    if _Month < 1                           !Date cannot deal with Negative Month 
       YrsAdj = 1 + ABS(_Month) / 12        !so how many years are we off + 1
       _Month += YrsAdj * 12                !advance Month forward
       _Year  -= YrsAdj                     !adjust years back
    end
    if _Year < 0 then _Year += 2000.         !If year passed as YY for 2000 (i.e. 00) and adjusted with -1 this fixes -1 to be 1999

    if _Month > 12                          !In Leap Years but with Months > 12 as noted by Clarion Mag
        YrsAdj = (_Month - 1) / 12
       _Month -= 12* YrsAdj
       _Year  += YrsAdj
    end

    if _Year > 99 and _Year <= 999 then
       _Year += 1900                        !In case 99 gets passed and +1 to 100 else (14,29,99) fails
    end

    if _Day < 1                                         !Date() cannot deal with Negative Day 
       RetDate = date(_Month, 1, _Year) - 1 + _Day      !so this should be the right number, should work in all cases so if is unneeded, but what the heck
    else
       RetDate = date(_Month, _Day, _Year)
    end
    return RetDate

!------------------------------------
DateAdjust FUNCTION(LONG InDate, LONG YearAdj=0, LONG MonthAdj=0, LONG DayAdj=0, <SHORT ForceDay>)!,LONG
BTDate      DATE,AUTO           !The Btreive date, any assignment auto converts to/from clarion standard date
BT          GROUP,OVER(BTDate)  !Note Little Endian reversal
Day             BYTE
Month           BYTE
Year            USHORT
            END
OutDay      LONG,AUTO      !Need to allow wider range then BYTE above allows
OutMonth    LONG,AUTO      ! e.g. Month could be -2 for an adjustment prior 2 months
OutYear     LONG,AUTO

!Please don't call as M,D,Y it's Y,M,D
  CODE                                            ! Begin processed code
    IF ~INRANGE(InDate + DayAdj,4,2994626) THEN RETURN InDate.           !Invalid date cannot deal with outside 1801 - 9999
    BTDate = InDate + DayAdj ! Convert LONG (Clarion Standard Date) to a Btrieve date DDMMYYYY with Cla$storebtdate
    OutYear = BT.Year  + YearAdj
    OutMonth= BT.Month + MonthAdj
    !OutDay was adjusted for DayAdj on assignment to the DATE
    OutDay  = CHOOSE(~OMITTED(5),ForceDay,BT.Day)   !A way to force the day of month, useful for 1st of month or 0=last day of prior month
    RETURN DateFixed(OutMonth,OutDay,OutYear)
!--------------------------
DateSplit   PROCEDURE(LONG Date2Split, <*? OutMonth>, <*? OutDay>, <*? OutYear>)
!Use DateSplit(Today,M,D,Y) instead of M=MONTH(Today) ; D=DAY(Today) ; Y=YEAR(Today)
D1 DATE,AUTO
DG GROUP, OVER(D1)
D   BYTE
M   BYTE
Y   USHORT
  END
    CODE
    D1=Date2Split
    IF ~OMITTED(OutMonth) THEN OutMonth=DG.M.
    IF ~OMITTED(OutDay)   THEN OutDay=DG.D.
    IF ~OMITTED(OutYear)  THEN OutYear=DG.Y.
    RETURN
!--------------------------------------------------------------------
TimeSplit PROCEDURE(LONG Time2Split, <*? OutHour>, <*? OutMinute>, <*? OutSecond>, <*? OutHundred>)
!Use TimeSplit(Now,H,M,S,C) instead of Format(,@t05) and Sub() the HHMMSS string
T1 TIME,AUTO
TG GROUP,OVER(T1)
C BYTE  !1/100 or Centisecond or Jiffy
S BYTE
M BYTE
H BYTE
  END
    CODE
    T1=Time2Split
    IF ~OMITTED(OutHour)    THEN OutHour   =TG.H.
    IF ~OMITTED(OutMinute)  THEN OutMinute =TG.M.
    IF ~OMITTED(OutSecond)  THEN OutSecond =TG.S.
    IF ~OMITTED(OutHundred) THEN OutHundred=TG.C.
    RETURN
!--------------------------
TimeHMS  PROCEDURE(LONG H=0, LONG M=0, LONG S=0, LONG Hundredths=0)!,LONG 
!This allows out of range HMS values, e.g. you can pass 90 minutes 
    CODE
    RETURN (H * 60*60*100) + |  !3600 Seconds in 1 Hour   *100=360,000
           (M *    60*100) + |  !  60 Seconds in 1 Minute *100=  6,000
           (S *       100) + |
           Hundredths + 1       !Clarion Time is always +1 as Zero is No Time
!--------------------------
DB   PROCEDURE(STRING xMsg)
Prfx EQUATE('DateTool: ')
sz   CSTRING(SIZE(Prfx)+SIZE(xMsg)+3),AUTO
  CODE 
  sz=Prfx & CLIP(xMsg) & '<13,10>'
  OutputDebugString(sz)
!--------------------------
DOWName     PROCEDURE(LONG Date2Dow)!,STRING
    CODE
    IF Date2Dow < 4 THEN RETURN ''.
    RETURN CHOOSE(Date2Dow % 7 + 1,'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')

DOWNumAndName  PROCEDURE(LONG Date2Dow)!,STRING    !Return "# Xxx" e.g. "3 Wed" to put on Calc Tab
DowNum LONG,AUTO
    CODE
    IF Date2Dow < 4 THEN RETURN ''.
    DowNum = Date2Dow % 7
    RETURN DowNum &' '& CHOOSE(DowNum + 1,'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')
    
DOWOrdinal  PROCEDURE(LONG Date2Dow, BOOL OrdinalWord=0)!,STRING     !Return Original 1st 2nd 3rd or First Second
DowNum LONG,AUTO
    CODE
    DowNum = (DAY(Date2Dow)-1) / 7 + 1
    IF ~OrdinalWord THEN  RETURN  CHOOSE(DowNum,'1st','2nd','3rd' ,DowNum &'th').
    RETURN CHOOSE(DowNum,'First','Second','Third','Fourth','Fifth',DowNum &'th')
!-----------------------------------
LettersOnly PROCEDURE(STRING inText)!,STRING
j LONG,AUTO 
k LONG,AUTO
    CODE
    k=0
    LOOP j=1 TO LEN(CLIP(inText))
        CASE inText[j]
        OF   'A' to 'Z'
        OROF 'a' to 'z'
            k += 1
            inText[k] = intext[j]
        END                         
    END
    RETURN SUB(inText,1,k) 
!-----------------------------------
PopupUnder PROCEDURE(LONG CtrlFEQ, STRING PopMenu)!,LONG
X LONG,AUTO
Y LONG,AUTO
H LONG,AUTO
    CODE
    GETPOSITION(CtrlFEQ,X,Y,,H)
    IF CtrlFEQ{PROP:InToolBar} THEN Y -= (0{PROP:ToolBar}){PROP:Height}.
    RETURN POPUP(PopMenu,X,Y+H+1,1) 
!-----------------------------------
ReplaceChar procedure(*STRING S, STRING FindChar, STRING PutChar, BOOL NoCase=False) !,LONG,PROC  Returns Position. Finds ONCE and Replaces. 
Pos LONG,AUTO
    code
    IF ~NoCase THEN Pos=INSTRING(FindChar,S,1) 
               ELSE Pos=INSTRING(UPPER(FindChar),UPPER(S),1) .
    IF Pos
       IF SIZE(FindChar)=SIZE(PutChar) THEN
          S[Pos : Pos+SIZE(FindChar)-1] = PutChar
       ELSE 
          S=SUB(S,1,Pos-1) & PutChar & SUB(S,Pos+Len(FindChar),SIZE(S))
       END
    END
    return Pos
!-----------------------------------
HolidayCheck   PROCEDURE(LONG pDate,<*string HolidayName>,<*string DOWName>)!,BYTE     !0=No 1=Yes Weekday 2=Yes Weekend
!FYI see my Holiday specific utility https://github.com/CarlTBarnes/Holiday-Calculator
BTDate      DATE,AUTO           !The Btreive date, any assignment auto converts to/from clarion standard date
BT          GROUP,OVER(BTDate),PRE(BT)  !Note Little Endian reversal
Day             BYTE
Month           BYTE
Year            USHORT
            END

Dow     LONG,AUTO
DowNum  LONG,AUTO
Holiday    BYTE(0)      !Return value
H_Name     STRING(50)

Dows    ITEMIZE(0)
Sunday          EQUATE
Monday          EQUATE
Tuesday         EQUATE
Wednesday       EQUATE
Thursday        EQUATE
Friday          EQUATE
Saturday        EQUATE
        END

  CODE
  BTDate = pDate
  Dow    = pDate % 7
  DowNum = (BT:Day-1) / 7 + 1   !1st,2nd,3rd DOW etc

  CASE BT:Month !MONTH(pDate)    !Trying for federal holidays here
  OF 1
        IF BT:Day=01 ;                  Holiday=True ; H_Name='New Years Day'.              !1/1 New years Day

        IF Dow=Monday AND DowNum=3 ;    Holiday=True ; H_Name='Martin Luther King Day (3rd Monday)'.     !Martin Luther King Day - Third Monday in January

        !Inauguration Day the year after leap years, on Jan 20 unless that's a Sunday
        IF (BT:Day=20 AND Dow<>Sunday) OR (BT:Day=21 AND Dow=Monday)                        !20 jan - inauguration day (21st if Sunday)
           IF (BT:Year - 1) % 4 = 0                                                         !     year after leaps e.g.  January 20, 2009
                                        Holiday=True ; H_Name='Inauguration Day'            ! may not be a holiday
           END
        END
        !Swearing-in of President of the United States and other elected federal officials.
        ! Observed only by federal government employees in Washington, D.C., and certain counties and cities of Maryland and Virginia,
        ! in order to relieve congestion that occurs with this major event.
        ! Note: Takes place on January 21 if the 20th is a Sunday (although the President is still privately inaugurated on the 20th).
  OF 2
        IF BT:Day=29 ;                  Holiday=True ; H_Name='Leap Day'.
        IF Dow=Monday AND DowNum=3 ;    Holiday=True ; H_Name='President''s Day (3rd Monday)'.           !President's Day - 3rd Monday in February, Officially "Washington's Birthday"
  OF 6
        IF BT:Day=14 ;                  Holiday=True ; H_Name='Flag Day'.                   !Not Fed !14 june - flag day - not really a federal holiday gotten off
        IF BT:Day=19 ;                  Holiday=True ; H_Name='Juneteenth'.

        IF Dow=Monday AND BT:Day+7>31
           Holiday=True ; H_Name='Memorial Day ' & CHOOSE(BT:Day=30,'','(Observed)')        !Memorial Day (Observed) - Last Monday in May, else 5/30
        END
  OF 7
        IF BT:Day=4 ;                   Holiday=True ; H_Name='Independence Day'.           !7/4 July 4th
  OF 9
        IF Dow=Monday AND DowNum=1 ;    Holiday=True ; H_Name='Labor Day (1st Monday)'.     !Labor Day - First Monday in September
  OF 10
        IF Dow=Monday AND DowNum=2 ;    Holiday=True ; H_Name='Columbus Day (2n Monday)'.   !Columbus Day - Second Monday in October (traditional 10/12)
  OF 11
        IF BT:Day=11 ;                  Holiday=True ; H_Name='Veterans Day'.               !Veterans Day - November 11th !? (Observed) some states 4th Monday in October ?
        IF Dow=Thursday AND DowNum=4 ;  Holiday=True ; H_Name='Thanksgiving (4th Thursday)'. !Thanksgiving - Fourth Thursday in November
  OF 12
        IF BT:Day=25 ;                  Holiday=True ; H_Name='Christmas'.                  !Christmas - December 25th
  END
  
  IF Holiday
     IF ~INRANGE(BT:Day,Monday,Friday) THEN Holiday=2.   !Return 2 if on a Weekend
     IF ~OMITTED(2) THEN HolidayName = H_Name.
     IF ~OMITTED(3) THEN DOWName = CHOOSE(Dow + 1,'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday').
  END
  RETURN( Holiday )
    !http://en.wikipedia.org/wiki/Federal_holiday
!Other Possible:
!   May 5   Cinco de Mayo
!   February, 1st Sunday, Super Bowl Sunday 
!   February 2 Groundhog Day
!   February 12 Illinois: Abraham Lincoln's Birthday
!   February 14 Valentine's Day     Sweetest Day=3rd Saturday in October
!   March 17 St. Patrick's Day
!   Feb-March, forty-six days before Easter, Ash Wednesday also Mardi Gras begins
!   May, 2nd Sunday, Mother's Day
!   May, 3rd Saturday Armed Forces Day
!   June, 3rd Sunday, Father's Day
!   October 31 Halloween 
!   November Election Day = 1st Tuesday after 1st Monday i.e. Tuesday with DAY >=2 <=8 ... all years ??
!   I have a Holiday example on GitHub that would be better spot
!
EasterDate      PROCEDURE(USHORT Yr)!,LONG    ! Mardi Gras or Ash Wednesday is EasterDate()-46
D       LONG,AUTO
Estr    LONG,AUTO
    CODE
    d = (((255 - 11 * (Yr % 19)) - 21) % 30) + 21
    Estr = Date(3,1,Yr) + d + CHOOSE(d > 48) + 6 - ((Yr + INT(Yr / 4) + d + CHOOSE(d > 48) + 1) % 7)
    return Estr
    !Public Function EasterDate(Yr As Integer) As Date
    !   d = (((255 - 11 * (Yr Mod 19)) - 21) Mod 30) + 21
    !   EasterDate = DateSerial(Yr, 3, 1) + d + (d > 48) + 6 - ((Yr + Yr \ 4 + _
    !   d + (d > 48) + 1) Mod 7)

!--------------------------
UnitTest_DateFixed PROCEDURE()
Y LONG
M LONG
D LONG
Fix1 LONG,AUTO
Fix2 LONG,AUTO
RtlD LONG,AUTO 
CntTests LONG 
CntFail  LONG 
V2FixMos LONG
V2FixDay LONG
V2FixYrs LONG 
YrBeg EQUATE(1820)
YrEnd EQUATE(2400)
TimeBegin  LONG 
Window WINDOW('UnitTest DateFixed - Date Time Tool'),AT(1,1,287,75),GRAY,FONT('Segoe UI',10)
        STRING('Status'),AT(17,19,253),USE(?StatusTxt),CENTER
        STRING(@n-7~ y~),AT(4,57),USE(Y)
        STRING(@n-7~ m~),AT(39,57),USE(M)
        STRING(@n-7~ d~),AT(77,57),USE(D)                
        STRING(@n10),AT(227,57),USE(CntTests),RIGHT
        STRING(@n16~ Errors~b),AT(202,46),USE(CntFail),RIGHT,FONT(,,COLOR:Maroon)
    END
    CODE 
    IF 2=Message('Test DateFixed() DateFixV2() '& YrBeg &'-'& YrEnd &' with '& (YrEnd-YrBeg+1)*200*200 &' Dates ?' & |
                 '||This can take a minute. Debug is output.', |
                 'UnitTest DateFixed ?',,'Test|Cancel') THEN RETURN.
    OPEN(Window)                 
    TimeBegin=CLOCK()
    ?StatusTxt{PROP:Text}='Started '& Format(TimeBegin,@t4) &' for Years '& YrBeg &' to '& YrEnd 
    DISPLAY                     ; DB('Unit Test DateFixed - '& ?StatusTxt{PROP:Text} )
LpT:    LOOP Y = YrBeg to YrEnd 
           DISPLAY              ; DB('Unit Test - Loop Year='& Y &' Tests='& CntTests &' Failed='& CntFail )
LpM:       LOOP M = -99 TO 99       ! -12 TO 24 ! -99 TO 99   Note Negative Months seem to Drive SLOWWWW the RTL Date() function a LOT
LpD:          LOOP D = -99 TO 99    ! -35 TO 60 ! -99 TO 99
                   CntTests += 1
RepeatTestLabel:                   
                   Fix1 = DateFixed(M,D,Y)
                   Fix2 = DateFixV2(M,D,Y)
                   IF M <= 0 THEN 
                      RtlD = -1         !Calling Date(M,D,Y) with M<=Zero is VERY VERY VERY SLOW so don't do it, assume -1
                   ELSE
                      RtlD = Date(M,D,Y)
                   END
                   ! DB('Tested ('& M &','& D &','& Y &')  Fix1=' & Fix1 &' Fix2=' & Fix2 &' RtlD=' & RtlD &'  '& Format(Fix2,@D02-) )  !See All Tests ... too much debug
                   
                   IF Fix1 = Fix2 THEN 
                      IF M > 0 AND RtlD = Fix1  AND RtlD = Fix2 THEN 
                         CYCLE
                      ELSIF M <= 0 AND RtlD = -1 THEN   !Expect -1 so no report 
                         CYCLE
                      ELSIF M <= 0 AND RtlD <> -1 AND RtlD = Fix1  AND RtlD = Fix2 THEN    !Expect -1 so no report 
                         CYCLE  !Date(-M,,) used to Return -1... now its <> -1 and =Fix1 so SV fixed? Else fall thru and show failed ... will NEVER happen due to above if M<=0 sets RtlD=-1
                      END 
                   END
                   
                   CntFail += 1                   
                   DISPLAY ; DB('Unit Test - FAIL ('& M &','& D &','& Y &')  Fix1=' & Fix1 &' Fix2=' & Fix2 &' RtlD=' & RtlD &'  Tests='& CntTests &' Failed='& CntFail )
                   CASE Message('Unit Test DateFixed() and DateFixv2 ' & |
                                '||Test Date( '& M &' months, '& D &' days, '& Y &' years) ' & |
                                '||DateFixed()='& Fix1 &' = '& Format(Fix1,@D02)  & |
                                '|DateFixV2()=' & Fix2 &' = '& Format(Fix2,@D02) &'  V2( '& V2FixMos &' months, '& V2FixDay &' days, '& V2FixYrs &' years) '& |
                                '|RTL Date()='  & RtlD &' = '& Format(RtlD,@D02)  & |
                                '|' & |
                                '','UnitTest DateFixed', ICON:Exclamation,'Continue |Next Month|Next Year|Abort Tests|Repeat Test')
                   OF 1                             !Continue                                
                   OF 2 ; Cycle LpM:                !Next Month
                   OF 3 ; M=99999 ; BREAK           !Next Year
                   OF 4 ; M=99999 ; Y=9999 ; BREAK  !Abort
                   OF 5                             !Repeat Test
                          GOTO RepeatTestLabel:     !Could set Debugger to Break Point on this Line to step thru code again  
                   END                   
              END !D loop
           END    !M loop 
        END       !Y loop
        DISPLAY
        MESSAGE('Tested: ' & CntTests &'  --  Failed: ' & CntFail &|
                '||'& (CLOCK()-TimeBegin)/100 &' seconds to run','UnitTest DateFixed Done')
        RETURN 
