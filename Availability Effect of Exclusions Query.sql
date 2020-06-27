/****** Script for SelectTopNRows command from SSMS  ******/
USE ShayganDB
GO

Declare @Start_Date datetime = '2019-12-22 00:00:00'
Declare @End_Date   datetime = '2020-03-19 23:00:00'

SELECT 
	alll.Province 
	, Tech 
	, ROUND(SUM(Duration)/3600,1) as DT 
	, CASE WHEN Tech= '2G' THEN MIN(hist2G.DD) ELSE NULL END as DD_2G
	, ROUND(CAST(ROUND(SUM(Duration)/3600,1) as float) / CAST(CASE WHEN Tech= '2G' THEN MIN(hist2G.DD) ELSE NULL END as float) * 100 , 5) as '2G Avail effect'
	, CASE WHEN Tech= '3G' THEN MIN(hist3G.DD) ELSE NULL END as DD_3G
	, ROUND(CAST(ROUND(SUM(Duration)/3600,1) as float) / CAST(CASE WHEN Tech= '3G' THEN MIN(hist3G.DD) ELSE NULL END as float) * 100 , 5) as '3G Avail effect'
	, CASE WHEN Tech= '4G' THEN MIN(hist4G.DD) ELSE NULL END as DD_4G
	, ROUND(CAST(ROUND(SUM(Duration)/3600,1) as float) / CAST(CASE WHEN Tech= '4G' THEN MIN(hist4G.DD) ELSE NULL END as float) * 100 , 5) as '4G Avail effect'

FROM
(
	SELECT * 
	FROM
	(
		SELECT 
			a.* 
			, CASE WHEN b.[Cell Name] is NOT NULL THEN '2G' ELSE NULL END as Tech
		FROM [ShayganDB].[dbo].[Ticketed Outages_Winter]  a 

		LEFT JOIN -- To choose only 2G Cell Outages 
			(
			SELECT Distinct([Cell Name]) 
			FROM [dbo].[Finalized HistoricalAvail2G] 
			WHERE [Report_Start_Date] = @Start_Date AND [Report_Finish_Date] = @End_Date
			)b
		ON a.CellName = b.[Cell Name]
	) aa
	WHERE Tech is NOT NULL AND Exclude_Cause is NOT NULL AND Exclude_Cause NOT in ('USO')

	UNION ALL

	SELECT * 
	FROM
	(
		SELECT 
			a.* 
			, CASE WHEN b.[Cell Name] is NOT NULL THEN '3G' ELSE NULL END as Tech
		FROM [ShayganDB].[dbo].[Ticketed Outages_Winter]  a 

		LEFT JOIN -- To choose only 3G Cell Outages 
			(
			SELECT Distinct([Cell Name]) 
			FROM [dbo].[Finalized HistoricalAvail3G] 
			WHERE [Report_Start_Date] = @Start_Date AND [Report_Finish_Date] = @End_Date
			)b
		ON a.CellName = b.[Cell Name]
	) aa
	WHERE Tech is NOT NULL AND Exclude_Cause is NOT NULL AND Exclude_Cause NOT in ('USO')

	UNION ALL

	SELECT * 
	FROM
	(
		SELECT 
			a.* 
			, CASE WHEN b.[Cell Name] is NOT NULL THEN '4G' ELSE NULL END as Tech
		FROM [ShayganDB].[dbo].[Ticketed Outages_Winter]  a 

		LEFT JOIN -- To choose only 4G Cell Outages 
		(
			SELECT Distinct([Cell Name]) 
			FROM [dbo].[Finalized HistoricalAvail4G] 
			WHERE [Report_Start_Date] = @Start_Date AND [Report_Finish_Date] = @End_Date
		)b
		ON a.CellName = b.[Cell Name]
	) aa
	WHERE Tech is NOT NULL AND Exclude_Cause is NOT NULL AND Exclude_Cause NOT in ('USO') 
) alll

LEFT JOIN 
(
	SELECT 
		REF.Indexes as Province
		, SUM([Data Duration(HOUR)])  as DD
	FROM [dbo].[Finalized HistoricalAvail2G] 
	LEFT JOIN 
	(
		SELECT * 
		FROM Provinces 
		WHERE Indexes <> 'XH'
	) REF
	ON REF.استان = [Finalized HistoricalAvail2G].استان 

	WHERE [Report_Start_Date] = @Start_Date AND [Report_Finish_Date] = @End_Date -- Select 2G Quarter Historical from [Finalized HistoricalAvail2G] Table
	GROUP BY REF.Indexes

) hist2G
ON hist2G.Province = alll.Province

LEFT JOIN 
(
	SELECT 
		REF.Indexes as Province
		, SUM([Data Duration(HOUR)]) as DD 
	FROM [dbo].[Finalized HistoricalAvail3G] 
	LEFT JOIN 
	(
		SELECT * 
		FROM Provinces 
		WHERE Indexes <> 'XH'
	) REF
	ON REF.استان = [Finalized HistoricalAvail3G].استان 

	WHERE [Report_Start_Date] = @Start_Date AND [Report_Finish_Date] = @End_Date -- Select 3G Quarter Historical from [Finalized HistoricalAvail3G] Table
	GROUP BY REF.Indexes

) hist3G
ON hist3G.Province = alll.Province

LEFT JOIN 
(
	SELECT 
		REF.Indexes as Province
		, SUM([Data Duration(HOUR)]) as DD 
	FROM [dbo].[Finalized HistoricalAvail4G] 
	LEFT JOIN 
	(
		SELECT * 
		FROM Provinces 
		WHERE Indexes <> 'XH'
	) REF
	ON REF.استان = [Finalized HistoricalAvail4G].استان
	
	WHERE [Report_Start_Date] = @Start_Date AND [Report_Finish_Date] = @End_Date -- Select 4G Quarter Historical from [Finalized HistoricalAvail4G] Table
	GROUP BY REF.Indexes

) hist4G
ON hist4G.Province = alll.Province


GROUP BY alll.Province , Tech ORDER BY alll.Province,alll.Tech


