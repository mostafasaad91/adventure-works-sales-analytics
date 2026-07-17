# Power BI — دليل بناء الـ Dashboard خطوة بخطوة

## المرحلة 1 — الاتصال والاستيراد (10 دقائق)

1. افتح **Power BI Desktop**
2. **Get Data → SQL Server**
   - Server: `.\SQLEXPRESS`
   - Database: `AdventureWorks2022`
   - Data Connectivity mode: **Import**
   - لو ظهر تحذير encryption → اختار OK/تجاهل (سيرفر محلي)
3. في الـ Navigator، علّم على الـ 6 Views دول **بس** (كلهم تحت schema اسمه `pbi`):
   - `pbi.FactSales`
   - `pbi.DimDate`
   - `pbi.DimProduct`
   - `pbi.DimCustomer`
   - `pbi.DimTerritory`
   - `pbi.DimSalesPerson`
4. **Load**

## المرحلة 2 — الـ Model (العلاقات) (5 دقائق)

افتح **Model view** (أيقونة الجداول شمال). اسحب من الـ Fact للـ Dim:

| من (FactSales) | إلى | نوع |
|---|---|---|
| OrderDate | DimDate[Date] | Many-to-One |
| ProductID | DimProduct[ProductID] | Many-to-One |
| CustomerID | DimCustomer[CustomerID] | Many-to-One |
| TerritoryID | DimTerritory[TerritoryID] | Many-to-One |
| SalesPersonID | DimSalesPerson[SalesPersonID] | Many-to-One |

بعدين:
- علّم `DimDate` كـ **Date table**: كليك يمين على DimDate → Mark as date table → عمود `Date`
- خبّي عمود OrderDate وكل الـ IDs في FactSales (كليك يمين → Hide) — القراءة من الـ Dimensions بس

## المرحلة 3 — الـ DAX Measures (10 دقائق)

اعمل جدول Measures فاضي: **Home → Enter Data** → سمّيه `_Measures` → OK.
بعدين لكل سطر تحت: كليك يمين على `_Measures` → **New measure** → الصق:

```dax
Total Revenue = SUM(FactSales[Revenue])
```
```dax
Total Profit = SUM(FactSales[Profit])
```
```dax
Profit Margin % = DIVIDE([Total Profit], [Total Revenue])
```
```dax
Total Orders = DISTINCTCOUNT(FactSales[SalesOrderID])
```
```dax
AOV = DIVIDE([Total Revenue], [Total Orders])
```
```dax
Customer Count = DISTINCTCOUNT(FactSales[CustomerID])
```
```dax
Revenue LY = CALCULATE([Total Revenue], SAMEPERIODLASTYEAR(DimDate[Date]))
```
```dax
Revenue YoY % = DIVIDE([Total Revenue] - [Revenue LY], [Revenue LY])
```
```dax
Revenue YTD = TOTALYTD([Total Revenue], DimDate[Date])
```
```dax
Running Revenue =
CALCULATE(
    [Total Revenue],
    FILTER(ALL(DimDate[Date]), DimDate[Date] <= MAX(DimDate[Date]))
)
```
```dax
Online Revenue = CALCULATE([Total Revenue], FactSales[OnlineOrderFlag] = TRUE())
```
```dax
Store Revenue = CALCULATE([Total Revenue], FactSales[OnlineOrderFlag] = FALSE())
```

فورمات: الفلوس `$#,##0` — النسب `0.0%` (من Measure tools فوق).

## المرحلة 4 — الصفحات (الجزء الأكبر)

### صفحة 1: Executive Overview
- **5 Cards فوق**: Total Revenue, Total Profit, Profit Margin %, Total Orders, AOV
- **Line chart**: Revenue بالشهر (DimDate[MonthName] على X) + خط تاني Revenue LY
- **Map**: Revenue حسب DimTerritory[CountryCode]
- **Donut**: Online Revenue vs Store Revenue
- **Slicer**: DimDate[Year]
- 💡 حط annotation (Text box) عند يوليو 2013: "Online explosion — AOV collapse"

### صفحة 2: Product Profitability
- **Bar chart**: Profit حسب Category → فعّل drill-down لـ Subcategory → Product
  (اسحب التلاتة في نفس الـ Axis بالترتيب)
- **Scatter**: X = Total Revenue, Y = Profit Margin %, تفاصيل = Subcategory
  → الربع اللي تحت يمين (إيراد عالي + هامش سالب) = Touring والـ Jerseys 🚩
- **Table**: أسوأ 15 منتج بالربح (فلتر Top N بالـ Profit تصاعدي)
- **Slicer**: Category

### صفحة 3: Customer Segments
- **Bar**: Revenue حسب DimCustomer[Segment] — هتشوف VIP = 89%
- **Bar تاني**: Customer Count حسب Segment — هتشوف العكس (46% New/Promising)
- **Table**: Segment | Customer Count | Revenue | AOV
- **Slicer**: CustomerKind (Store/Individual)
- 💡 القصة: "قيمة في قلة — 471 عميل At Risk يستاهلوا حملة استرجاع"

### صفحة 4: Territory & Team
- **Map أو Bar**: Revenue حسب Territory
- **Bar**: Revenue YoY % حسب Territory (هتشوف Germany +366%)
- **Table**: SalesPerson | Total Revenue | Profit Margin %
- **Slicer**: DimDate[Year] + DimTerritory[Region]

## المرحلة 5 — اللمسات
- **Format → Report theme**: اختار theme موحد
- امسح الـ gridlines الزايدة، وحّد الفونت
- احفظ الملف هنا: `adventureworks-analysis/powerbi/adventureworks_dashboard.pbix`

## ملاحظات
- استبعد يونيو 2014 من الـ visuals الزمنية (شهر ناقص): فلتر على مستوى الصفحة
  `DimDate[Date] < 2014-06-01` في الصفحات الزمنية
- الـ Segment جاي من جدول `dbo.CustomerSegments` اللي كتبه Python notebook 1 —
  لو أعدت تشغيل الـ notebook، اعمل Refresh في Power BI
