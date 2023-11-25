-- Standardise Date format for column 'saledate'
	-- Current datatype is timestamp

SELECT saledate::date
FROM nashvillehousing

ALTER TABLE nashvillehousing
ALTER COLUMN saledate TYPE date

-- Populate property address data and ensure NULL values in 'propertyaddress' is filled with correct address matching the 'parcelid' column
	-- Update the table with the correct information

SELECT * 
FROM nashvillehousing
WHERE propertyaddress IS NOT NULL
ORDER BY parcelid

SELECT a.parcelid,a.propertyaddress,b.parcelid,b.propertyaddress,
COALESCE(a.propertyaddress,b.propertyaddress)
FROM nashvillehousing a
JOIN nashvillehousing b
ON a.parcelid = b.parcelid
AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NOT NULL

UPDATE nashvillehousing a
SET propertyaddress = COALESCE(a.propertyaddress,b.propertyaddress)
FROM nashvillehousing b
WHERE a.uniqueid <> b.uniqueid
AND a.parcelid = b.parcelid
AND a.propertyaddress IS NULL

-- Break out the delimiter in 'propertyaddress' and save them into separate columns (address,city)

SELECT propertyaddress 
FROM nashvillehousing
WHERE propertyaddress IS NOT NULL

SELECT propertyaddress, 
SPLIT_PART(propertyaddress,',',1),
SPLIT_PART(propertyaddress,',',2)
FROM nashvillehousing

ALTER TABLE nashvillehousing
ADD address VARCHAR(250),
ADD city VARCHAR(250)

UPDATE nashvillehousing
SET address = SPLIT_PART(propertyaddress,',',1),
city = SPLIT_PART(propertyaddress,',',2)

-- Break out the delimiter in 'owneraddress' and save them into separate columns (address,city,state)

SELECT owneraddress,SPLIT_PART(owneraddress,',',1),
SPLIT_PART(owneraddress,',',2),
SPLIT_PART(owneraddress,',',3)
FROM nashvillehousing

ALTER TABLE nashvillehousing
ADD owneraddresssplit VARCHAR(250),
ADD ownercity VARCHAR(250),
ADD ownerstate VARCHAR(50)

UPDATE nashvillehousing
SET owneraddresssplit = SPLIT_PART(owneraddress,',',1),
ownercity = SPLIT_PART(owneraddress,',',2),
ownerstate = SPLIT_PART(owneraddress,',',3)

-- Change 'Y' and 'N' to Yes and No in the 'soldasvacant' column

SELECT DISTINCT(soldasvacant),COUNT(soldasvacant)
FROM nashvillehousing
GROUP BY soldasvacant
ORDER BY 2

SELECT soldasvacant,
CASE WHEN soldasvacant = 'Y' THEN 'Yes'
WHEN soldasvacant = 'N' THEN 'No'
ELSE soldasvacant
END
FROM nashvillehousing

UPDATE nashvillehousing
SET soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes'
WHEN soldasvacant = 'N' THEN 'No'
ELSE soldasvacant
END

-- Find potential duplicates from the table

WITH row_numcte AS(
SELECT *, 
	ROW_NUMBER()OVER(
		PARTITION BY parcelid,
		propertyaddress,
		saleprice,
		saledate,
		legalreference
		ORDER BY
			uniqueid
			) AS row_num
FROM nashvillehousing
-- ORDER BY parcelid
)
SELECT * 
FROM row_numcte
WHERE row_num > 1
ORDER BY propertyaddress

-- Remove potential duplicates from the table

DELETE FROM nashvillehousing
WHERE uniqueid IN(
	SELECT uniqueid
	FROM (
	SELECT 
		uniqueid,
		ROW_NUMBER()OVER(
		PARTITION BY parcelid,
		propertyaddress,
		saleprice,
		saledate,
		legalreference
		ORDER BY
			uniqueid
			) AS row_num
		FROM nashvillehousing
	) s
	WHERE row_num > 1
)

-- Delete unused columns

ALTER TABLE nashvillehousing
DROP COLUMN owneraddress,
DROP COLUMN taxdistrict,
DROP COLUMN propertyaddress,
DROP COLUMN saledate