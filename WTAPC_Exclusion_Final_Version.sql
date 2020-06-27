USE ShayganDB

Declare @Start_Date datetime = '2019-12-22 00:00:00'
Declare @End_Date   datetime = '2020-01-20 23:00:00'

SELECT 
[Cell Name]               as CellName
, MIN(hist2G.Location)    as Location
, MIN(ref.Indexes)        as Province
, MIN(Report_Start_Date)  as Report_Start_Date
, MAX(Report_Finish_Date) as Report_Finish_Date
, CAST(SUM([Data Duration(HOUR)]) as float)																	as Data_Duration
, CAST(ISNULL(MAX(outage.DownTime_Duration),0) as float)													as DownTime_Duration
, CAST(ISNULL(MAX(exclusion.Exclusion_DownTime),0) as float)                                                as Exclusion_DownTime
, CAST(ISNULL(MAX(outage.DownTime_Duration),0) as float) - CAST(MAX(exclusion.Exclusion_DownTime) as float) as Down_Time_Excluded
, CAST(ISNULL(MAX(outage.Down_Count),0) as float)															as Down_Count
, CAST(ISNULL(MAX(exclusion.Down_Count_Excluded),0) as float)	                                            as Down_Count_Excluded
, CAST(SUM(TCH_Availability_NUM) as float)																	as TCH_Num
, CAST(ISNULL(SUM(TCH_Availability_DENOM),1) as float)	+ 0.0001											as TCH_Dinom

, CASE WHEN MAX(exclusion.Exclusion_DownTime) is NOT NULL 
	THEN
	ROUND(
	(CAST(SUM(TCH_Availability_NUM) as float) / (CAST(ISNULL(SUM(TCH_Availability_DENOM),1) as float) + 0.0001) 
	+
	(CAST(MAX(exclusion.Exclusion_DownTime) as float) / (CAST(SUM([Data Duration(HOUR)]) + 0.0001 as float) * 3600 ))) * 100 , 2)

	ELSE 	
	ROUND(
	(CAST(SUM(TCH_Availability_NUM) as float) / (CAST(ISNULL(SUM(TCH_Availability_DENOM),1) as float) + 0.0001)) * 100 , 2) END as TCH_Availability


FROM [dbo].[Monthly_Historical_2G] hist2G

LEFT JOIN (SELECT * FROM [dbo].Provinces WHERE Indexes <> 'XH') ref
ON ref.استان = hist2G.استان

 
LEFT JOIN 
	(SELECT 
		CellName  
		, SUM( CASE WHEN StartOfOutage>= @Start_Date AND EndOfOutage<= @End_Date THEN Duration
					WHEN StartOfOutage>= @Start_Date AND EndOfOutage>  @End_Date THEN DATEDIFF(ss,StartOfOutage,@End_Date)
					WHEN StartOfOutage<  @Start_Date AND EndOfOutage<= @End_Date THEN DATEDIFF(ss,@Start_Date,EndOfOutage)
					WHEN StartOfOutage<  @Start_Date AND EndOfOutage>  @End_Date THEN DATEDIFF(ss,@Start_Date,@End_Date)
					ELSE Duration END) as Exclusion_DownTime 
		 , COUNT(CellName)     as Down_Count_Excluded 
	FROM [dbo].[Ticketed Outages_Winter] 
	WHERE 
		Exclude_Cause is NOT NULL
	AND	Exclude_Cause NOT IN ('USO','MTCT')
	AND EndOfOutage >= @Start_Date AND StartOfOutage <= @End_Date 
	GROUP BY CellName) exclusion
ON  exclusion.CellName = hist2G.[Cell Name]

LEFT JOIN 
	(SELECT 
		CellName  
		, SUM( CASE WHEN StartOfOutage>= @Start_Date AND EndOfOutage<= @End_Date THEN Duration
					WHEN StartOfOutage>= @Start_Date AND EndOfOutage>  @End_Date THEN DATEDIFF(ss,StartOfOutage,@End_Date)
					WHEN StartOfOutage<  @Start_Date AND EndOfOutage<= @End_Date THEN DATEDIFF(ss,@Start_Date,EndOfOutage)
					WHEN StartOfOutage<  @Start_Date AND EndOfOutage>  @End_Date THEN DATEDIFF(ss,@Start_Date,@End_Date)
					ELSE Duration END) as DownTime_Duration
		, COUNT(CellName) as Down_Count 
	FROM [dbo].[Ticketed Outages_Winter] 
	WHERE 
		EndOfOutage >= @Start_Date AND StartOfOutage <= @End_Date
	GROUP BY CellName) outage
ON  outage.CellName = hist2G.[Cell Name]


WHERE (Report_Start_Date =  @Start_Date AND Report_Finish_Date = @End_Date)
GROUP BY [Cell Name]


--SELECT [Cell Name],[Data Duration(HOUR)],Down_COUNT,[SUM of BCCH DownTime(Seconds)],TCH_Availability_NUM,TCH_Availability_DENOM,TCH_Availability
--FROM [dbo].[Monthly_Historical_2G]
--WHERE (Report_Start_Date =  @Start_Date AND Report_Finish_Date = @End_Date)


