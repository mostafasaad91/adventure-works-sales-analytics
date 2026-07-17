# دليل بناء الـ Dashboard — نسخة مفصلة خطوة بخطوة

> **الأساس:** مشروع `AdventureWorksDashboard.pbip` — الموديل والعلاقات والـ 17 measure جاهزين.
> شغلك هنا **رسم بس**. كل visual هقولك: بتضيفه إزاي، تحط إيه فين، تظبط شكله إزاي،
> والرقم اللي المفروض يظهر عشان تتأكد إنك ماشي صح ✅.

---

# التجهيز (مرة واحدة)

## أ. افتح المشروع
1. Double-click على `AdventureWorksDashboard.pbip`
2. أول مرة هيطلب تحديث الداتا: **Refresh** → لو سأل credentials اختار **Windows** → Connect
3. لو ظهر تحذير encryption → **OK**
4. لو الملف رفض يفتح: File → Options and settings → Options → **Preview features** → ✅ "Power BI Project (.pbip) save option" → أعد التشغيل

## ب. فعّل الـ Theme
1. **View** (من الريبون فوق) → في قسم Themes دوس السهم الصغير ˅
2. **Browse for themes** → اختار `theme.json` من فولدر powerbi
3. الصفحات هتاخد خلفية رمادي فاتح والكروت هتبقى بيضا بحواف مدورة

## ج. اعرف أدواتك (اقرأها مرة واحدة)
- **لوحة Data** (أقصى يمين): الجداول والحقول — منها بتسحب
- **لوحة Visualizations** (جنبها): أيقونات أنواع الشارتات + خانات الحقول (X-axis, Y-axis...)
- **لوحة Filters**: فلاتر على مستوى الـ visual / الصفحة / التقرير كله
- **أيقونة 🖌 (Format)**: جوه لوحة Visualizations — كل تظبيط الشكل هنا
- الصفحات = تابات تحت زي Excel

## د. تحقق سريع من الموديل (30 ثانية)
حط visual **Card** مؤقت → اسحب فيه `Total Revenue` من جدول `_Measures`:
- ✅ المفروض: **$110M** تقريباً
- ❌ لو طلع رقم خام من غير $: الـ measure مش من `_Measures` — اتأكد إنك ساحب الـ measure مش عمود Revenue
امسح الكارت بعد التأكد.

---

# صفحة 1: Executive Overview

**هدف الصفحة:** المدير يفهم الوضع في 10 ثواني — كام بنكسب، رايحين فين، الفلوس منين.

## التخطيط النهائي (ابنيه بالترتيب ده)
```
┌──────┬──────┬──────┬──────┬──────┐
│ Rev  │Profit│Margin│Orders│ AOV  │   ← صف كروت (ارتفاع ~100px)
├──────┴──────┴──────┴──┬───┴──────┤
│  Line: Revenue Trend  │  Slicer  │
│  (العرض الأكبر)        │  Year    │
├──────────────┬────────┴──────────┤
│ Map: Revenue │  Donut:           │
│ by Country   │  Online vs Store  │
└──────────────┴───────────────────┘
```

## 1.1 الكروت الخمسة (KPI Cards)
لكل واحد:
1. دوس مكان فاضي في الصفحة → من Visualizations اختار **Card** (أيقونة 123)
2. اسحب الـ measure في خانة **Fields**
3. كرر 5 مرات:

| كارت | Measure | المفروض يظهر |
|---|---|---|
| 1 | `Total Revenue` | ~$110M |
| 2 | `Total Profit` | ~$12.5M |
| 3 | `Profit Margin %` | ~11.4% |
| 4 | `Total Orders` | ~31K |
| 5 | `AOV` | ~$3.5K |

**تظبيط الشكل** (اعمله على الأول وانسخ الفورمات):
- 🖌 → **Callout value**: Font size = 26
- 🖌 → **Category label**: Font size = 10
- رصّهم صف واحد فوق: حددهم كلهم (Ctrl+Click) → **Format** (ريبون) → **Align → Distribute horizontally**

## 1.2 الـ Line Chart (قلب الصفحة)
1. **Line chart** من Visualizations
2. الحقول:
   - **X-axis**: `DimDate[MonthName]` ← هتترتب زمنياً تلقائي (الموديل مظبوط)
   - **Y-axis**: `Total Revenue`
   - **Secondary y-axis أو Y-axis تاني**: `Revenue LY`
3. ✅ تحقق: خط متذبذب صاعد + قفزة واضحة عند **Jul 2013** — لو الخط مستوي، فيه مشكلة، بلّغني
4. **العنوان الديناميكي**:
   - 🖌 → **Title** → جنب Text دوس **fx**
   - Format style = **Field value** → Field = `_Measures[Trend Title]` → OK
5. 🖌 → **Lines**: خلي خط `Revenue LY` متقطع (Line style = Dashed) ولونه رمادي — عشان الحالي يبان أوضح
6. **Text box** (Insert → Text box): اكتب `Jul 2013: online explosion — AOV collapsed`
   حجم 10، رمادي، وحطه فوق منطقة القفزة

## 1.3 الـ Map
1. **Map** (الكرة الأرضية)
2. الحقول:
   - **Location**: `DimTerritory[CountryCode]`
   - **Bubble size**: `Total Revenue`
3. ✅ تحقق: أكبر فقاعة على أمريكا، وبعدها كندا وأستراليا
4. لو الخريطة مطلعتش: File → Options → **Security** → ✅ Use Map and Filled Map visuals → أعد الفتح
5. 🖌 → Title: اكتب `Revenue by Country`

## 1.4 الـ Donut
1. **Donut chart**
2. **Values**: اسحب `Online Revenue` وبعدين `Store Revenue` (الاتنين في Values)
3. ✅ تحقق: Store ≈ **73%** رغم إن أوردراته 12% بس — دي النقطة
4. 🖌 → **Detail labels** → Label contents = **Percent of total**
5. Title: `Revenue by Channel: the 12% of orders that bring 73% of money`

## 1.5 الـ Slicer
1. **Slicer** → اسحب `DimDate[Year]`
2. من سهم ˅ فوق يمين الـ slicer نفسه → **Tile**
3. 🖌 → **Slicer settings** → Selection: فعّل ✅ **Show "Select all"**
4. جرب: دوس 2013 → كل الصفحة تتفلتر

## 1.6 فلتر الشهر الناقص (مهم)
يونيو 2014 نصف شهر وبيبوظ الترند:
1. دوس مكان فاضي في الصفحة (عشان يكون الفلتر على مستوى الصفحة)
2. لوحة **Filters** → **Filters on this page** → اسحب `DimDate[Date]`
3. Filter type = Advanced → **is before** → `6/1/2014` → Apply

---

# صفحة 2: Product Profitability

**هدف الصفحة:** "الإيراد العالي مش معناه ربح" — إظهار Touring والـ Jerseys كنقاط نزيف.

## التخطيط
```
┌────────────────────────────────────┐
│ Slicer: Category (شريط أفقي فوق)   │
├─────────────────┬──────────────────┤
│ Bar drill-down: │ Scatter:         │
│ Profit by       │ Revenue vs       │
│ Category        │ Margin %         │
├─────────────────┴──────────────────┤
│ Table: Bottom 15 products (عريض)   │
└────────────────────────────────────┘
```

## 2.1 Bar Chart بالـ Drill-down
1. **Clustered bar chart**
2. **Y-axis** — اسحب التلاتة بالترتيب فوق بعض:
   - `DimProduct[Category]`
   - `DimProduct[Subcategory]`
   - `DimProduct[Product]`
3. **X-axis**: `Total Profit`
4. ✅ تحقق: Bikes أطول عمود (~$10.5M)
5. **جرب الغطس**: فعّل السهم ⬇ (فوق يمين الشارت) → دوس عمود Bikes → هتشوف Mountain/Road/Touring → دوس Touring Bikes → الموديلات بالخساير
6. **تلوين الخساير أحمر**:
   - 🖌 → **Bars** (أو Columns) → Colors → **fx**
   - Format style = **Rules** → What field = `Total Profit`
   - Rule: If value **< 0** → `#D95F5F` → أضف Rule تانية: If value **>= 0** → `#2C6FBB`
7. العنوان الديناميكي: 🖌 → Title → fx → `_Measures[Profitability Title]`

## 2.2 الـ Scatter (نجم المشروع)
1. **Scatter chart**
2. الحقول:
   - **Values**: `DimProduct[Subcategory]`
   - **X-axis**: `Total Revenue`
   - **Y-axis**: `Profit Margin %`
   - **Size**: `Total Profit`
3. ✅ تحقق: نقطة Road Bikes أقصى يمين، Tires and Tubes فوق خالص (62%)، و Jerseys **تحت الصفر**
4. **خط الصفر**:
   - أيقونة العدسة المكبرة 🔍 (Analytics) جنب أيقونة الفورمات
   - **Y-Axis Constant Line** → Add line → Value = **0** → لون أحمر، Style = Dashed
5. **Labels**: 🖌 → **Category labels** → On (أسماء الفئات على النقط)
6. Title: `Revenue vs Margin — bottom-right quadrant is the leak`

## 2.3 جدول أسوأ 15 منتج
1. **Table**
2. **Columns** بالترتيب: `DimProduct[Product]`, `Total Revenue`, `Total Profit`, `Profit Margin %`
3. **فلتر Bottom 15**:
   - لوحة Filters → Filters on this visual → دوس `Product`
   - Filter type = **Top N** → Show items = **Bottom** + اكتب **15**
   - By value = اسحب `Total Profit` → **Apply filter**
4. رتب: دوس على هيدر عمود Total Profit لغاية السهم ⬆ (تصاعدي)
5. ✅ تحقق: أول صف `Touring-1000 Yellow, 60` بخسارة **−$133K**
6. **تلوين**:
   - 🖌 → **Cell elements** → Series = `Profit Margin %` → ✅ Background color → fx → Rules → If < 0 → `#F8D7D7`
   - Series = `Total Profit` → ✅ **Data bars** → Negative bar color = `#D95F5F`

## 2.4 الـ Slicer
`DimProduct[Category]` → نوع Tile → مدده شريط أفقي فوق الصفحة.

---

# صفحة 3: Customer Segments

**هدف الصفحة:** عرض شغل الـ Python — القيمة في قلة، والفرصة في الـ At Risk.

## التخطيط
```
┌──────────┬──────────┬─────────────┐
│Card: VIP │Card: At  │Slicer:      │
│Rev Share │Risk count│CustomerKind │
├──────────┴──────────┴─────────────┤
│ Bar: Revenue by Segment │ Bar: Customers by Segment │
├────────────────────────────────────┤
│ Table: Segment summary  (عريض)     │
└────────────────────────────────────┘
```

## 3.1 الشارتين المتقابلين (جوهر الصفحة)
**الأول — الفلوس:**
1. **Clustered bar chart**
2. Y-axis: `DimCustomer[Segment]` | X-axis: `Total Revenue`
3. ✅ VIP ≈ $98M — بياكل الشاشة

**التاني — العدد:**
1. Bar chart تاني جنبه
2. Y-axis: `DimCustomer[Segment]` | X-axis: `Customer Count`
3. ✅ New/Promising الأكبر (~8.9K عميل)

**النقطة البصرية:** الشارتين جنب بعض بيحكوا التناقض — الإيراد في segment والعدد في segment تاني. Title للأول: `Where the money is` وللتاني: `Where the people are`

## 3.2 جدول الملخص
1. **Table** → Columns: `DimCustomer[Segment]`, `Customer Count`, `Total Revenue`, `AOV`, `Profit Margin %`
2. رتب بالإيراد تنازلي
3. ✅ تحقق من صف At Risk: 471 عميل

## 3.3 Slicer
`DimCustomer[CustomerKind]` (Store/Individual) — Tile.
جربه: دوس Individual → شوف الـ VIP بيتقلص (أغلب الـ VIP محلات).

## 3.4 Text box بالقصة
> `471 "At Risk" customers used to spend $12.6K each and went quiet.
> Re-activation window: month 10-12 (median repurchase = 345 days).`

---

# صفحة 4: Territory & Team

**هدف الصفحة:** فين ننمو (أوروبا) ومين بيبيع فعلاً.

## التخطيط
```
┌─────────────────┬──────────────────┐
│ Map: Revenue    │ Bar: YoY % by    │
│ by Territory    │ Territory        │
├─────────────────┴──────────────────┤
│ Table: SalesPerson performance     │
├────────────────────────────────────┤
│ Slicers: Year | Region             │
└────────────────────────────────────┘
```

## 4.1 الـ Map
زي صفحة 1: Location = `DimTerritory[Territory]`... ⚠️ الأسماء زي "Southwest" مش هتتظبط على الخريطة لوحدها — استخدم `CountryCode` في **Location** و `Territory` في **Legend**.

## 4.2 Bar النمو (اكتشاف أوروبا)
1. **Clustered bar chart**
2. Y-axis: `DimTerritory[Territory]` | X-axis: `Revenue YoY %`
3. **فلتر مهم**: Filters on this visual → `DimDate[Year]` → Basic → اختار **2013** بس
   (عشان YoY تبقى مقارنة سنة كاملة بسنة كاملة)
4. رتب تنازلي → ✅ Germany فوق بـ **+366%**
5. Title: `2013 growth: Europe on fire, US East shrinking`
6. لوّن بالـ Rules زي ما عملنا: سالب أحمر / موجب أزرق

## 4.3 جدول الفريق
1. **Table** → `DimSalesPerson[SalesPerson]`, `Total Revenue`, `Total Profit`, `Profit Margin %`, `DimSalesPerson[CommissionPct]`
2. فلتر على مستوى الـ visual: `SalesPerson` → is not blank (عشان تشيل الأوردرات الـ online اللي ملهاش بياع)
3. رتب بالـ Revenue تنازلي → ✅ Linda Mitchell فوق (~$10.4M)
4. Data bars على عمود Total Revenue

## 4.4 Slicers
`DimDate[Year]` + `DimTerritory[Region]` جنب بعض تحت.

---

# التشطيب النهائي (15 دقيقة)

1. **مسميات الصفحات**: تأكد إن التابات: Executive Overview / Product Profitability / Customer Segments / Territory & Team
2. **Edit interactions** (لو visual بيفلتر واحد تاني بشكل مش منطقي):
   حدد الـ visual → ريبون **Format** → **Edit interactions** → أيقونة ⊘ على اللي عايز تعطله
3. **المحاذاة**: كل صفحة — حدد الـ visuals المتجاورة → Format → **Align**
4. **احفظ**: Ctrl+S — بيحفظ في ملفات الـ PBIP نفسها
5. **Screenshot لكل صفحة** — هنحتاجهم للـ README بتاع GitHub

# اختبار القبول النهائي ✅
امشي على القايمة دي — لو كلها شغالة، الـ dashboard خلص:
- [ ] slicer السنة في صفحة 1 بيغير كل الأرقام
- [ ] الغطس Bikes → Touring Bikes → موديلات شغال في صفحة 2
- [ ] الـ scatter فيه نقط تحت خط الصفر ملونة/واضحة
- [ ] جدول Bottom 15 أوله Touring-1000 Yellow, 60
- [ ] شارتي segment بيوروا التناقض (فلوس vs عدد)
- [ ] Germany فوق في شارت النمو
- [ ] العناوين الديناميكية بتتغير مع الـ slicer

**بعد كده:** ملحق الاحتراف `upgrades_guide.md` — Tooltips, Drill-through, صفحة Home.
