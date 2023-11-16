--Data Cleaning in SQL to ensure Data Quality

--Data Checked: Duplicates, Missing Values, Formatting, Data Type errors, Consistent Values, Organization
--Skills used: Partition By, CTE, Self-Join, Substring, Case Statement, Replace, Parsename
 
 -------------------------------------------------------------------------------------------------------------------
 --Checking out the raw data, looking for errors

Select *
From PortfolioProject.dbo.NashvilleHousing

--Returns 56477 Rows
--Checking for Duplicate Values 

Select DISTINCT(UniqueID)
From PortfolioProject.dbo.NashvilleHousing
Order by UniqueID

--Returns 56477 Rows so there are no Duplicate UniqueID numbers
--Checking for Duplicate Values in ParcelID 

Select DISTINCT(ParcelID)
From PortfolioProject.dbo.NashvilleHousing
Order by ParcelID

--Only 48559 Rows, a difference of 7918 rows
--Duplicate ParcelIDs may mean there are duplicate rows with only different UniqueIDs, or that the same property was sold more than 1 time.
--Partition by columns with values that should not be duplicated, such as the same address, sold on the same date, for the same price

WITH CTE_RowNum AS
(
Select *,
	ROW_NUMBER() Over (
	Partition BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	Order by UniqueID
	) row_num
From PortfolioProject.dbo.NashvilleHousing
)
Select *
From CTE_RowNum
Where ROW_NUM > 1 
Order by UniqueID

--There are 103 rows with duplicated values, but unique UniqueIDs, these should be deleted

WITH CTE_RowNum AS
(
Select *,
	ROW_NUMBER() Over (
	Partition BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	Order by UniqueID
	) row_num
From PortfolioProject.dbo.NashvilleHousing
)
DELETE 
From CTE_RowNum
Where ROW_NUM > 1 


--Checking for Null Values 

Select *
From PortfolioProject.dbo.NashvilleHousing
Where LandUse IS NULL

--no results, there are no NULLS

Select *
From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress IS NULL

--The PropertyAddress contains 29 Nulls, however we may be able to populate this using the duplicate ParcelIDs
--Checking the missing PropertyAddress values for duplicate ParcelIDs

Select A.UniqueID, A.ParcelID, B.ParcelID, A.PropertyAddress, B.PropertyAddress
From PortfolioProject.dbo.NashvilleHousing AS A
	Join PortfolioProject.dbo.NashvilleHousing AS B
on A.ParcelID = B.ParcelID
AND A.[UniqueID ]<>B.[UniqueID ]
Where A.PropertyAddress IS NULL
Order by A.UniqueID

--Property Addresses are available by referencing duplicate ParcelIDs, updating data

Update A
Set PropertyAddress = ISNULL(a.propertyaddress,b.propertyaddress)
From PortfolioProject.dbo.NashvilleHousing AS A
	Join PortfolioProject.dbo.NashvilleHousing AS B
on A.ParcelID = B.ParcelID
AND A.[UniqueID ]<>B.[UniqueID ]
Where A.PropertyAddress IS NULL

--Checking to see if missing values were added

Select *
From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress IS NULL

--No results show that there are no longer NULLS 

--Organize PropertyAddress into 2 columns, the address and the city. This makes the data more usable.
--The information is seperated by a comma

Select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress) -1 ) As Property_Address,
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) As Property_City
From PortfolioProject.dbo.NashvilleHousing

Alter Table PortfolioProject.dbo.NashvilleHousing
Add Property_Address Nvarchar(100)

Update PortfolioProject.dbo.NashvilleHousing
SET Property_Address = SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress) -1 )

Alter Table PortfolioProject.dbo.NashvilleHousing
Add Property_City Nvarchar(100)

Update PortfolioProject.dbo.NashvilleHousing
SET Property_City = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

--Check results

Select *
From PortfolioProject.dbo.NashvilleHousing

--2 new columns created: Property_Address and Property_City 

--Standardize SaleDate from DATETIME to DATE data type

Alter Table PortfolioProject.dbo.NashvilleHousing
Alter Column SaleDate date

--Checking results

Select *
From PortfolioProject.dbo.NashvilleHousing

--SaleDate data type updated successfully
--Continuing to Check for NULL values

Select *
From PortfolioProject.dbo.NashvilleHousing
Where SaleDate IS NULL

Select *
From PortfolioProject.dbo.NashvilleHousing
Where SalePrice IS NULL

Select *
From PortfolioProject.dbo.NashvilleHousing
Where LegalReference IS NULL

--Null values in LegalReference
--No duplicate ParcelID - so values cannot be populated

Select *
From PortfolioProject.dbo.NashvilleHousing
Where SoldAsVacant IS NULL

Select *
From PortfolioProject.dbo.NashvilleHousing
Where OwnerName IS NULL

--There are 31,158 rows with missing values for OwnerName.
--It looks like for the rows with missing values for OwnerName also have missing Values for:
--OwnerAddress, Acreage, TaxDistrict,LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, and HalfBath
--Important to note

Select *
From PortfolioProject.dbo.NashvilleHousing
Where OwnerName IS NOT NULL and Bedrooms IS NULL

--There are 1408 rows that also have Nulls in Bedrooms (in addition to the 31,158 rows of data with Nulls in OwnerName)
--To be addressed and kept in mind for later.

--Checking Values - SoldAsVacant Column, there are 4 possible values: (No, Yes, N, Y), there should only be 2 values

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group By SoldAsVacant

Select SoldAsVacant, 
	CASE When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	END
From PortfolioProject.dbo.NashvilleHousing

Update PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	END


--OwnerAddress also needs to be organized into 2 columns, the address and the city. This makes the data more usable.
--The information is seperated by a comma. I will use REPLACE to change the comma to a period then I can use PARSENAME 

Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing
Where OwnerAddress IS NOT NULL

Select 
	PARSENAME(REPLACE(OwnerAddress,',', '.'),3) AS Owner_Address,
	PARSENAME(REPLACE(OwnerAddress,',', '.'),2) AS Owner_City,
	PARSENAME(REPLACE(OwnerAddress,',', '.'),1) AS Owner_State
From PortfolioProject.dbo.NashvilleHousing
Where OwnerAddress IS NOT NULL

--This looks good, now to alter the table

Alter Table PortfolioProject.dbo.NashvilleHousing
Add Owner_Address Nvarchar(100)

Update PortfolioProject.dbo.NashvilleHousing
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress,',', '.'),3)

Alter Table PortfolioProject.dbo.NashvilleHousing
Add Owner_City Nvarchar(100)

Update PortfolioProject.dbo.NashvilleHousing
SET Owner_City = PARSENAME(REPLACE(OwnerAddress,',', '.'),2)

Alter Table PortfolioProject.dbo.NashvilleHousing
Add Owner_State Nvarchar(100)

Update PortfolioProject.dbo.NashvilleHousing
SET Owner_State = PARSENAME(REPLACE(OwnerAddress,',', '.'),1)

--Checking results

Select *
From PortfolioProject.dbo.NashvilleHousing

--Table updated correctly
--Now that the data has been cleaned, formatted and organized 2 columns can be deleted, PropertyAddress and OwnerAddress
--These columns were split into more usable seperate columns for address, city and state

Alter Table PortfolioProject.dbo.NashvilleHousing
Drop Column PropertyAddress, OwnerAddress

--Checking results

Select *
From PortfolioProject.dbo.NashvilleHousing

--Data Cleaning Complete
--Important Notes: Nulls in LegalReference, OwnerName, OwnerAddress, Acreage, TaxDistrict,LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, and HalfBath
--Missing values could not be populated from existing data
--Request for more data to join to existing table to fill in missing values
