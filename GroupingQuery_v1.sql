USE DashboardDB
GO

SELECT g.*
,map.[عرض جغرافیایی]   as Latitude
,map.[طول جغرافیایی]   as Longitude
	FROM
	(
	SELECT CellName 
	,CASE WHEN LEN(CellName)=7 THEN LEFT(CellName,6) ELSE LEFT(CellName,8) END as Site
	,[Province Index], NE, InnerLocation as Location, StartOfOutage, EndOfOutage, Duration, Technology  
	,DENSE_RANK() OVER (PARTITION BY OG,OutageGroup ORDER BY InnerLocation ASC) + DENSE_RANK() OVER (PARTITION BY OG,OutageGroup ORDER BY InnerLocation DESC) -1 as CountOfOutageInGroup
	,DENSE_RANK() OVER (ORDER BY OG,OutageGroup) as GroupNumber

		FROM
		(
		SELECT *
		,CASE   WHEN CTAG=0 and LAG(CTAG,1) OVER (PARTITION BY OG ORDER BY Duration,CellName)=1 THEN outage_tag_number-1
				WHEN CTAG=0 and LAG(CTAG,1) OVER (PARTITION BY OG ORDER BY Duration,CellName)=0 THEN outage_tag_number * -1
				WHEN CTAG=1 THEN  outage_number - outage_tag_number ELSE -0.5 END as OutageGroup
			FROM
			(
			SELECT *
			, ROW_NUMBER() OVER (PARTITION BY OG      ORDER BY Duration,CellName) as outage_number
			, ROW_NUMBER() OVER (PARTITION BY OG,CTAG ORDER BY Duration,CellName) as outage_tag_number
				FROM
				(
				SELECT *
				,CASE WHEN (LEAD(Duration , 1) OVER ( PARTITION BY OG ORDER BY Duration,CellName)-Duration)<Ddif THEN 1 ELSE 0 END as CTAG
					FROM
					(
					SELECT * 
					,CASE   WHEN Duration >= 3600 THEN 1200 
							WHEN Duration <= 600  THEN ROUND(CAST(Duration as float)*0.1 , 0)  
							ELSE ROUND( Duration * (CAST(Duration as float)/3600 * 0.28 + 0.05) , 0) END as Ddif        
					,DENSE_RANK() OVER ( ORDER BY StartOfOutage , NE) as OG
						FROM
						(
						SELECT *
							FROM(
								SELECT CellName, [Province Index], NE, Location as InnerLocation, StartOfOutage, EndOfOutage, [Down_Time(Seconds)] as Duration, Technology
									FROM Daily_AvailabilityDetailOutage2G
								UNION ALL
								SELECT CellName, [Province Index], NE, Location as InnerLocation, StartOfOutage, EndOfOutage, [Down_Time(Seconds)] as Duration, Technology
									FROM Daily_AvailabilityDetailOutage3G
								UNION ALL
								SELECT CellName, [Province Index], NE, Location as InnerLocation, StartOfOutage, EndOfOutage, [Down_Time(Seconds)] as Duration, Technology
									FROM Daily_AvailabilityDetailOutage4G
							)a
						)b
					)c
				)d
			)e
		)f
	)g

LEFT JOIN LocationArrasDataBase map
ON map.Location = g.Location

