USE adventureworks;
SHOW TABLES;
-- Q1. Which 10 products generated the most total sales revenue?
SELECT
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.OrderQty) AS UnitsSold
FROM sales_salesorderdetail AS sod
INNER JOIN production_product AS p
        ON p.ProductID = sod.ProductID
GROUP BY p.ProductID, p.Name
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Q2. How much revenue does each product category generate?
SELECT
    pc.Name AS CategoryName,
    SUM(sod.LineTotal) AS TotalRevenue
FROM sales_salesorderdetail AS sod
INNER JOIN production_product AS p ON p.ProductID = sod.ProductID
INNER JOIN production_productsubcategory AS psc ON psc.ProductSubcategoryID = p.ProductSubcategoryID
INNER JOIN production_productcategory AS pc  ON pc.ProductCategoryID = psc.ProductCategoryID
GROUP BY pc.Name
ORDER BY TotalRevenue DESC;
 
-- Q3. Who are the top 10 individual customers by total amount spent, and how many orders did each place?
SELECT
    c.CustomerID,
    CONCAT(per.FirstName, ' ', per.LastName) AS CustomerName,
    COUNT(soh.SalesOrderID) AS OrdersPlaced,
    SUM(soh.TotalDue) AS TotalSpent
FROM sales_customer AS c
INNER JOIN person_person AS per
        ON per.BusinessEntityID = c.PersonID
INNER JOIN sales_salesorderheader AS soh
        ON soh.CustomerID = c.CustomerID
GROUP BY c.CustomerID, per.FirstName, per.LastName
ORDER BY TotalSpent DESC
LIMIT 10;
 
 -- Q4. Which products have never been sold?
SELECT
    p.ProductID,
    p.Name,
    p.ListPrice
FROM production_product AS p
LEFT JOIN sales_salesorderdetail AS sod
       ON sod.ProductID = p.ProductID
WHERE sod.ProductID IS NULL
  AND p.FinishedGoodsFlag = 1   -- only items meant for sale
ORDER BY p.Name;
 
-- Q5. What is total sales by territory for each year?
SELECT
    st.Name AS Territory,
    YEAR(soh.OrderDate) AS OrderYear,
    SUM(soh.TotalDue) AS TotalSales
FROM sales_salesorderheader AS soh
INNER JOIN sales_salesterritory AS st
        ON st.TerritoryID = soh.TerritoryID
GROUP BY st.Name, YEAR(soh.OrderDate)
ORDER BY st.Name, OrderYear;
 
-- Q6. Which salespeople have a year-to-date sales figure above the company average for salespeople?
SELECT
    sp.BusinessEntityID,
    CONCAT(per.FirstName, ' ', per.LastName)  AS SalesPerson,
    sp.SalesYTD
FROM sales_salesperson AS sp
INNER JOIN person_person AS per
        ON per.BusinessEntityID = sp.BusinessEntityID
WHERE sp.SalesYTD > (SELECT AVG(SalesYTD) FROM sales_salesperson)
ORDER BY sp.SalesYTD DESC;
 
 -- Q7. Which orders were larger than the average order value, and who placed them (show the 20 largest)?
SELECT
    soh.SalesOrderID,
    soh.OrderDate,
    CONCAT(per.FirstName, ' ', per.LastName)  AS CustomerName,
    soh.TotalDue
FROM sales_salesorderheader AS soh
INNER JOIN sales_customer AS c   ON c.CustomerID = soh.CustomerID
INNER JOIN person_person  AS per ON per.BusinessEntityID = c.PersonID
WHERE soh.TotalDue > (SELECT AVG(TotalDue) FROM sales_salesorderheader)
ORDER BY soh.TotalDue DESC
LIMIT 20;
 
 -- Q8. Which products are priced above the average list price of their own subcategory?
SELECT
    p.ProductID,
    p.Name,
    p.ListPrice,
    p.ProductSubcategoryID
FROM production_product AS p
WHERE p.ListPrice > 0
  AND p.ListPrice > (
        SELECT AVG(p2.ListPrice)
        FROM production_product AS p2
        WHERE p2.ProductSubcategoryID = p.ProductSubcategoryID)
ORDER BY p.ProductSubcategoryID, p.ListPrice DESC;

 -- Q9. How many current employees does each department have?
   SELECT
    d.Name AS Department,
    COUNT(edh.BusinessEntityID) AS CurrentEmployees
FROM humanresources_employeedepartmenthistory AS edh
INNER JOIN humanresources_department AS d
        ON d.DepartmentID = edh.DepartmentID
WHERE edh.EndDate IS NULL
GROUP BY d.Name
ORDER BY CurrentEmployees DESC;
 
-- Q10. Which vendors supply the largest number of different products?
SELECT
    v.BusinessEntityID,
    v.Name AS VendorName,
    COUNT(DISTINCT pv.ProductID)    AS ProductsSupplied
FROM purchasing_vendor AS v
INNER JOIN purchasing_productvendor AS pv
        ON pv.BusinessEntityID = v.BusinessEntityID
GROUP BY v.BusinessEntityID, v.Name
ORDER BY ProductsSupplied DESC, v.Name
LIMIT 10;
 
-- Q11. Which customers have bought at least one product from the 'Bikes' category?
SELECT
    c.CustomerID,
    CONCAT(per.FirstName, ' ', per.LastName)  AS CustomerName
FROM sales_customer AS c
INNER JOIN person_person AS per
        ON per.BusinessEntityID = c.PersonID
WHERE c.CustomerID IN (
        SELECT soh.CustomerID
        FROM sales_salesorderheader AS soh
        WHERE soh.SalesOrderID IN (
                SELECT sod.SalesOrderID
                FROM sales_salesorderdetail AS sod
                WHERE sod.ProductID IN (
                        SELECT p.ProductID
                        FROM production_product AS p
                        INNER JOIN production_productsubcategory AS psc
                                ON psc.ProductSubcategoryID = p.ProductSubcategoryID
                        INNER JOIN production_productcategory AS pc
                                ON pc.ProductCategoryID = psc.ProductCategoryID
                        WHERE pc.Name = 'Bikes')))
ORDER BY CustomerName;

-- Q12. Which products have total stock below their reorder point?
SELECT
    p.ProductID,
    p.Name,
    p.ReorderPoint,
    SUM(pi.Quantity) AS TotalInStock
FROM production_product AS p
INNER JOIN production_productinventory AS pi
        ON pi.ProductID = p.ProductID
GROUP BY p.ProductID, p.Name, p.ReorderPoint
HAVING SUM(pi.Quantity) < p.ReorderPoint
ORDER BY p.Name;
 
-- Q13. What is the average number of days between order and shipment for each sales territory?
SELECT
    st.Name AS Territory,
    AVG(CAST(DATEDIFF(soh.ShipDate, soh.OrderDate) AS DECIMAL(10,2))) AS AvgDaysToShip
FROM sales_salesorderheader AS soh
INNER JOIN sales_salesterritory AS st
        ON st.TerritoryID = soh.TerritoryID
GROUP BY st.Name
ORDER BY AvgDaysToShip DESC;
 
-- Q14. Who has the most unused vacation hours in each department?
SELECT
    d.Name AS Department,
    CONCAT(per.FirstName, ' ', per.LastName)  AS EmployeeName,
    e.JobTitle,
    e.VacationHours
FROM humanresources_employee AS e
INNER JOIN humanresources_employeedepartmenthistory AS edh
        ON edh.BusinessEntityID = e.BusinessEntityID AND edh.EndDate IS NULL
INNER JOIN humanresources_department AS d
        ON d.DepartmentID = edh.DepartmentID
INNER JOIN person_person AS per
        ON per.BusinessEntityID = e.BusinessEntityID
WHERE e.VacationHours = (SELECT MAX(e2.VacationHours)
        FROM humanresources_employee AS e2
        INNER JOIN humanresources_employeedepartmenthistory AS edh2
                ON edh2.BusinessEntityID = e2.BusinessEntityID AND edh2.EndDate IS NULL
        WHERE edh2.DepartmentID = edh.DepartmentID)
ORDER BY d.Name;
 
-- Q15. Which retail stores have spent more than the average store?
SELECT
    s.BusinessEntityID,
    s.Name AS StoreName,
    SUM(soh.TotalDue) AS TotalPurchases
FROM sales_store AS s
INNER JOIN sales_customer AS c
        ON c.StoreID = s.BusinessEntityID
INNER JOIN sales_salesorderheader AS soh
        ON soh.CustomerID = c.CustomerID
GROUP BY s.BusinessEntityID, s.Name
HAVING SUM(soh.TotalDue) > (SELECT AVG(StoreTotal)
        FROM (SELECT SUM(soh2.TotalDue) AS StoreTotal
            FROM sales_customer AS c2
            INNER JOIN sales_salesorderheader AS soh2
                    ON soh2.CustomerID = c2.CustomerID
            WHERE c2.StoreID IS NOT NULL
            GROUP BY c2.StoreID) AS StoreTotals)
ORDER BY TotalPurchases DESC;
 