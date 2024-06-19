
--Standardize Date Format

Select SaleDateConverted, Convert(Date,Saledate)
From Project.dbo.Nashville_Housing_Data_UTF9

Update Nashville_Housing_Data_UTF9 
Set SaleDate = Convert(Date,Saledate)

Alter Table Nashville_Housing_Data_UTF9 
Add SaleDateConverted Date;

Update Nashville_Housing_Data_UTF9 
Set SaleDateConverted = Convert(Date,Saledate)

-- Populate Property Address Data

Select *
From Project.dbo.Nashville_Housing_Data_UTF9
Where PropertyAddress is null

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL (a.PropertyAddress, b.PropertyAddress)
From Nashville_Housing_Data_UTF9 a 
Join Nashville_Housing_Data_UTF9 b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID] <> b.[UniqueID]

Update a
Set PropertyAddress = ISNULL (a.PropertyAddress, b.PropertyAddress)
From Nashville_Housing_Data_UTF9 a 
Join Nashville_Housing_Data_UTF9 b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

-- Seperating Address into Fields

Select PropertyAddress 
From Nashville_Housing_Data_UTF9

Select
Substring(PropertyAddress, 1, Charindex(',', PropertyAddress)-1) as Address
, Substring(PropertyAddress, Charindex(',', PropertyAddress) + 1, Len(PropertyAddress)) as Address
From Nashville_Housing_Data_UTF9
WHERE CHARINDEX(',', PropertyAddress) > 0;

Alter Table Nashville_Housing_Data_UTF9 
ADD PropertySplitAddress nvarchar(255);

Update Nashville_Housing_Data_UTF9 
Set PropertySplitAddress = Substring(PropertyAddress, 1, Charindex(',', PropertyAddress)-1)
WHERE CHARINDEX(',', PropertyAddress) > 0;

Alter Table Nashville_Housing_Data_UTF9 
ADD PropertySplitCity nvarchar(255);

Update Nashville_Housing_Data_UTF9 
Set PropertySplitCity = Substring(PropertyAddress, Charindex(',', PropertyAddress) + 1, Len(PropertyAddress))
WHERE CHARINDEX(',', PropertyAddress) > 0;

USE Project
Select *
From Nashville_Housing_Data_UTF9

--OR

Select OwnerAddress
From Nashville_Housing_Data_UTF9

Select 
Parsename(Replace(OwnerAddress, ',', '.') , 3)
,Parsename(Replace(OwnerAddress, ',', '.') , 2)
,Parsename(Replace(OwnerAddress, ',', '.') , 1)
From Nashville_Housing_Data_UTF9


Alter Table Nashville_Housing_Data_UTF9 
ADD OwnerSplitAddress nvarchar(255);

Update Nashville_Housing_Data_UTF9 
Set OwnerSplitAddress = Substring(PropertyAddress, 1, Charindex(',', PropertyAddress)-1)
WHERE CHARINDEX(',', PropertyAddress) > 0;

Alter Table Nashville_Housing_Data_UTF9 
ADD OwnerSplitCity nvarchar(255);

Update Nashville_Housing_Data_UTF9 
Set OwnerSplitCity = Substring(PropertyAddress, Charindex(',', PropertyAddress) + 1, Len(PropertyAddress))
WHERE CHARINDEX(',', PropertyAddress) > 0;

Alter Table Nashville_Housing_Data_UTF9 
ADD OwnerSplitState nvarchar(255);

Update Nashville_Housing_Data_UTF9 
Set OwnerSplitState = Substring(PropertyAddress, Charindex(',', PropertyAddress) + 1, Len(PropertyAddress))
WHERE CHARINDEX(',', PropertyAddress) > 0;

-- Change Y and N to Yes and No in 'Sold as Vacant' Field

Select Distinct(SoldAsVacant), Count (SoldAsVacant)
From Nashville_Housing_Data_UTF9
Group by SoldAsVacant
Order by 2

Select SoldAsVacant
, Case WHEN SoldAsVacant = 1 THEN 'Yes'
        WHEN SoldAsVacant = 0 THEN 'No'
        ELSE 'Unknown'
	   END
	From Nashville_Housing_Data_UTF9

ALTER TABLE Nashville_Housing_Data_UTF9
ALTER COLUMN SoldAsVacant varchar(3);

UPDATE Nashville_Housing_Data_UTF9
SET SoldAsVacant = CASE 
                       WHEN SoldAsVacant = '1' THEN 'Yes'
                       WHEN SoldAsVacant = '0' THEN 'No'
                       ELSE 'Unknown'
                   END;

--Remove Duplicates*

WITH RowNumCTE AS (
Select *,
	Row_Number() OVER (
	Partition By ParcelID,
			     PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order by UniqueID
				 ) row_num



From Nashville_Housing_Data_UTF9

)
Select *
From RowNumCTE
Where row_num > 1

--Delete Unused Columns

Select * 
From Nashville_Housing_Data_UTF9

Alter Table Nashville_Housing_Data_UTF9
Drop Column OwnerAddress, TaxDistrict, PropertyAddress

Alter Table Nashville_Housing_Data_UTF9
Drop Column SaleDate