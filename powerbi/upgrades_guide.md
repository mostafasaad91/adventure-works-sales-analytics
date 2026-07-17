# ملحق الاحتراف — ترقية الـ Dashboard

> اشتغل على المشروع الجاهز `AdventureWorksDashboard.pbip` — الموديل والـ measures معمولين.
> الملحق ده بيضيف طبقة الاحتراف بالترتيب. كل بند مستقل — اعمل اللي يعجبك.

---

## 1. الـ Theme (دقيقتين — اعمله الأول)
1. **View → Themes → سهم صغير → Browse for themes**
2. اختار `theme.json` من فولدر powerbi
3. كل الـ visuals هتاخد: خلفية رمادي فاتح للصفحة، كروت بيضا بحواف مدورة، أزرق موحد للأرقام

الألوان المقصودة:
- أزرق `#2C6FBB` = الأساسي | برتقالي `#F2A104` = مقارنات (LY)
- أحمر `#D95F5F` = **الخساير بس** — متستخدمهوش لحاجة تانية، عشان لما يظهر يقول "مشكلة"

## 2. Dynamic Titles (5 دقائق)
الـ measures جاهزة في الموديل: `Trend Title`, `Profitability Title`, `Selected Year Label`.

لأي شارت:
1. حدد الشارت → أيقونة الفورمات 🖌 → **Title**
2. جنب خانة Text فيه زرار **fx** (conditional formatting)
3. Format style = **Field value** → اختار `_Measures[Trend Title]`
4. جرب الـ slicer: العنوان هيتغير "Revenue Trend — 2013" / "Revenue Trend — All Years (2011-2014)"

## 3. Conditional Formatting للجداول (5 دقائق)
على جدول "أسوأ 15 منتج":
1. حدد الجدول → 🖌 → **Cell elements**
2. Series = `Profit Margin %` → فعّل **Background color** → fx:
   - Format style = Rules
   - Rule: If value < 0 → لون `#F8D7D7` (أحمر فاتح)
3. Series = `Total Profit` → فعّل **Data bars** → Negative bar = `#D95F5F`

## 4. Custom Tooltip Page (15 دقيقة)
صفحة مصغرة بتظهر لما تحوم على أي منتج:
1. صفحة جديدة → سمّيها `Tooltip: Product`
2. 🖌 (وانت على الصفحة نفسها، مش visual) → **Page information** → فعّل **Allow use as tooltip**
3. **Canvas settings** → Type = **Tooltip** (حجم صغير جاهز)
4. حط فيها: Card بـ `Total Revenue` + Card بـ `Profit Margin %` + Line chart صغير (Revenue بالشهر)
5. روح لأي visual منتجات → 🖌 → **Properties → Tooltips** → Type = **Report page** → Page = `Tooltip: Product`
6. حوم على أي منتج — بدل الـ tooltip العادي هتظهر البطاقة الغنية

## 5. Drill-through Page (15 دقيقة)
صفحة تحقيق لأي منتج:
1. صفحة جديدة `Product Details`
2. من لوحة الحقول: اسحب `DimProduct[Product]` لخانة **Drill through** (في لوحة Visualizations تحت)
3. ابني الصفحة: Cards (Revenue/Profit/Margin/Units) + Line trend + Bar بالـ Territory
4. Power BI هيضيف زرار ⬅ back تلقائي فوق شمال
5. الاستخدام: من أي صفحة تانية، كليك يمين على منتج → **Drill through → Product Details**

## 6. صفحة افتتاحية + تنقل (30 دقيقة)
1. صفحة جديدة أول واحدة اسمها `Home`
2. Text box كبير بالسؤال الرئيسي: *"Where does $123M come from — and where does it leak?"*
3. تحته 3 Cards كبار: Total Revenue | Profit Margin % | Customer Count
4. تحتهم 3 Text boxes بالتوصيات:
   - "Fix or kill the Touring line (1.5% margin, -88% promos, $350K dead stock)"
   - "Re-activate 471 At-Risk customers at month 10-12"
   - "Double down on Europe (+130-366% growth)"
5. **أزرار تنقل**: Insert → **Buttons → Navigator → Page navigator** — شريط أزرار لكل الصفحات، انسخه لكل صفحة (فوق أو شمال)
6. اخفي صفحات الـ Tooltip والـ Drill-through (كليك يمين على التاب → Hide) — بيشتغلوا وهما مخفيين

## 7. لمسات أخيرة
- **فلتر يونيو 2014 الناقص**: على الصفحات الزمنية، لوحة Filters → Filters on this page → اسحب `DimDate[Date]` → Before 2014-06-01
- **Align**: حدد visuals متجاورة → Format → Align → وحّد الحواف
- **Interactions**: لو مش عايز الـ donut يفلتر اللاين شارت: حدده → Format → **Edit interactions** → عطّل اللي مش منطقي
- احفظ: File → Save (هيحفظ في نفس ملفات الـ PBIP)
