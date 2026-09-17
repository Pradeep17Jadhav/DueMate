\# DueMate iOS App

\## Product Requirements \& AI Coding Agent Instructions



> This document is the authoritative product and engineering specification for the DueMate iOS application.

>

> The AI coding agent must read and understand this entire document before making implementation decisions.

>

> Build the application incrementally, keeping the project compiling and runnable after every major phase.



\---



\# 1. PRODUCT OVERVIEW



\## App Name



DueMate



\## One-line description



A personal finance obligations tracker for bills, EMIs, credit cards, utilities, loans, subscriptions, and other recurring payments.



\## Problem



Users currently manage recurring financial obligations using calendar reminders.



For example:



\- "Pay HDFC Credit Card" on the 5th of every month

\- "Home Loan EMI" on the 7th

\- "Car Loan EMI" on the 1st

\- Electricity bill due date

\- Internet bill

\- Insurance premium

\- Annual subscriptions



The problem with conventional calendar reminders is that the reminder only answers:



> "What do I need to do?"



It does not properly answer:



> "Did I pay it?"

>

> "When did I pay it?"

>

> "How did I pay it?"

>

> "Which bank did I use?"

>

> "Which UPI app did I use?"

>

> "What was the amount?"

>

> "What happened in previous months?"

>

> "How many EMIs have I already paid?"

>

> "How much is remaining?"

>

> "Which payments are still pending?"



DueMate should combine:



1\. Calendar

2\. Task/reminder system

3\. Payment history

4\. Recurring schedules

5\. Loan/EMI tracking

6\. Financial obligation metadata

7\. Home Screen widgets

8\. Notifications

9\. Historical records



into one polished iOS application.



\---



\# 2. CORE PRODUCT PRINCIPLE



Every recurring obligation is a persistent entity.



Do NOT model recurring bills as independent calendar events.



Instead:



&#x20;   Obligation

&#x20;       |

&#x20;       +-- Recurrence Rule

&#x20;       |

&#x20;       +-- Occurrence

&#x20;             |

&#x20;             +-- Status

&#x20;             +-- Payment information

&#x20;             +-- Notes

&#x20;             +-- Amount

&#x20;             +-- Metadata



Example:



&#x20;   HDFC Credit Card

&#x20;       recurrence: monthly, day 5



&#x20;       September 2026 occurrence

&#x20;           due date: Sep 5

&#x20;           status: Paid

&#x20;           payment date: Sep 4, 20:31

&#x20;           payment method: UPI

&#x20;           payment app: Google Pay

&#x20;           payment bank: HDFC Bank

&#x20;           amount: ₹18,420



&#x20;       October 2026 occurrence

&#x20;           due date: Oct 5

&#x20;           status: Pending



This architecture is critical because it allows the app to maintain historical payment information without creating duplicate calendar entries.



\---



\# 3. TARGET PLATFORM



Build a native iPhone application.



Target:



\- iOS 18+

\- Swift 6+

\- SwiftUI

\- Xcode latest stable version available during implementation

\- Latest stable Apple SDKs available during implementation



The application must be designed for modern iPhones.



Primary target:



&#x20;   iPhone



Do not build the first version as a cross-platform application.



Use native Apple technologies.



\---



\# 4. TECHNOLOGY STACK



Use modern Apple-native technologies.



\## UI



\- SwiftUI

\- NavigationStack

\- TabView

\- Observation framework

\- @Observable where appropriate

\- Swift concurrency

\- async/await



Avoid unnecessary UIKit.



UIKit may be used only when SwiftUI does not provide an appropriate API.



\---



\# 5. ARCHITECTURE



Use a clean, modular architecture.



Preferred architecture:



&#x20;   Feature-based MVVM



with clear separation between:



&#x20;   Presentation

&#x20;   Domain

&#x20;   Data

&#x20;   Networking

&#x20;   Persistence

&#x20;   Services



Suggested project structure:



&#x20;   DueMate/

&#x20;   │

&#x20;   ├── App/

&#x20;   │   ├── DueMateApp.swift

&#x20;   │   ├── AppEnvironment.swift

&#x20;   │   └── AppRouter.swift

&#x20;   │

&#x20;   ├── Core/

&#x20;   │   ├── Models/

&#x20;   │   ├── Networking/

&#x20;   │   ├── Persistence/

&#x20;   │   ├── Extensions/

&#x20;   │   ├── Utilities/

&#x20;   │   └── DesignSystem/

&#x20;   │

&#x20;   ├── Features/

&#x20;   │   ├── Dashboard/

&#x20;   │   ├── Calendar/

&#x20;   │   ├── Tasks/

&#x20;   │   ├── Obligations/

&#x20;   │   ├── Payment/

&#x20;   │   ├── Loans/

&#x20;   │   ├── Categories/

&#x20;   │   └── Settings/

&#x20;   │

&#x20;   ├── Widgets/

&#x20;   │

&#x20;   └── Resources/



Do not create one enormous ContentView.



Keep features independently maintainable.



\---



\# 6. DATA STORAGE



The application backend is API based.



Base API URL:



&#x20;   https://www.pradeepjadhav.com/api/



The exact API endpoint should be represented through configuration rather than hardcoded throughout the application.



Example:



&#x20;   APIConfiguration.baseURL



API routes should use typed endpoint definitions.



Example conceptual structure:



&#x20;   APIEndpoint

&#x20;       .obligations

&#x20;       .obligation(id:)

&#x20;       .occurrences

&#x20;       .payments

&#x20;       .categories

&#x20;       .settings

&#x20;       .sync



Do not scatter raw URL strings throughout the application.



\---



\# 7. API DESIGN



Assume the backend exposes REST-style JSON APIs.



The frontend should be designed so the backend implementation can evolve without requiring major UI changes.



Create:



&#x20;   APIClient



responsible for:



\- GET

\- POST

\- PUT/PATCH

\- DELETE

\- authentication headers

\- JSON encoding/decoding

\- HTTP error handling

\- retry handling where appropriate

\- request logging in DEBUG builds only



Use:



&#x20;   URLSession

&#x20;   async/await

&#x20;   Codable



Do not introduce Alamofire unless there is a concrete reason.



\---



\# 8. API SECURITY



Never store secrets in source code.



Never hardcode:



\- API keys

\- authentication tokens

\- passwords

\- private secrets



Use:



\- Keychain for authentication credentials/tokens

\- environment/configuration files for non-secret configuration

\- `.xcconfig` where appropriate



The public API base URL is not itself a secret.



\---



\# 9. OFFLINE-FIRST BEHAVIOR



The application should remain useful when the network is unavailable.



Use local persistence/cache for:



\- obligations

\- occurrences

\- payment records

\- categories

\- settings



Preferred persistence:



&#x20;   SwiftData



The application should follow:



&#x20;   Local database

&#x20;         ↕

&#x20;      Sync Layer

&#x20;         ↕

&#x20;       REST API



When offline:



\- users can view existing data

\- users can create/edit records

\- changes are queued

\- sync happens when connectivity returns



Do not make every screen directly dependent on a network request.



\---



\# 10. AUTHENTICATION



Design the app so authentication can be added cleanly.



Create an abstraction:



&#x20;   AuthenticationService



Support:



\- login

\- logout

\- token storage

\- token refresh

\- current user



If backend authentication endpoints are not available yet, implement a mock/local authentication provider behind a protocol.



Do NOT fake authentication throughout the application.



\---



\# 11. PRIMARY NAVIGATION



Use a bottom TabView.



Primary tabs:



1\. Home

2\. Calendar

3\. Tasks

4\. Obligations

5\. Settings



Use SF Symbols.



Suggested icons:



Home:



&#x20;   house.fill



Calendar:



&#x20;   calendar



Tasks:



&#x20;   checklist



Obligations:



&#x20;   wallet.pass.fill



Settings:



&#x20;   gearshape.fill



The exact icons can be adjusted if a better Apple SF Symbol exists.



\---



\# 12. HOME / DASHBOARD



The Home screen is the primary landing screen.



It should provide an immediate overview.



Suggested sections:



\## Header



Show:



&#x20;   Good morning/afternoon/evening

&#x20;   Current date



Avoid excessive personalization.



\## Summary cards



Examples:



&#x20;   Due Today

&#x20;   Due This Week

&#x20;   Pending

&#x20;   Paid This Month



\## Upcoming obligations



Show the next upcoming items.



Example:



&#x20;   Sep 18

&#x20;   HDFC Credit Card

&#x20;   ₹18,420

&#x20;   Due in 1 day



\## Pending payments



Show unpaid items.



\## Recent payments



Show recently completed payments.



\## Financial overview



Optional cards:



&#x20;   Total due this month

&#x20;   Total paid this month

&#x20;   Total pending



These should be calculated from actual occurrence data.



\---



\# 13. CALENDAR VIEW



The Calendar tab must provide a monthly calendar.



Requirements:



\- Month navigation

\- Today button

\- Selected date

\- Days containing obligations visually marked

\- Multiple obligations on the same date

\- Category indicators

\- Paid/pending visual distinction

\- Tap a date to see that day's obligations

\- Tap an obligation to open its details



Example:



&#x20;   September 2026



&#x20;   M  T  W  T  F  S  S

&#x20;      1  2  3  4  5  6

&#x20;      ●     ●     ●

&#x20;   7  8  9 10 11 12 13

&#x20;      ...



Use subtle visual markers rather than overcrowding calendar cells.



Possible indicators:



\- category color dot

\- multiple dots

\- completion checkmark

\- pending indicator



Do not put too much text inside calendar cells.



\---



\# 14. DATE DETAIL



When a user selects a date, show:



&#x20;   September 17



&#x20;   09:00

&#x20;   HDFC Credit Card

&#x20;   ₹18,420

&#x20;   Pending



&#x20;   11:00

&#x20;   Home Loan EMI

&#x20;   ₹33,000

&#x20;   Paid



Users must be able to:



\- open

\- edit

\- delete

\- mark paid

\- mark unpaid

\- add a new obligation/occurrence



Use swipe actions where appropriate.



\---



\# 15. TASK VIEW



The Tasks tab displays all occurrences grouped by date.



Example:



&#x20;   TODAY

&#x20;   September 17



&#x20;   HDFC Credit Card

&#x20;   ₹18,420

&#x20;   Pending



&#x20;   Home Loan EMI

&#x20;   ₹33,000

&#x20;   Paid



&#x20;   TOMORROW

&#x20;   September 18



&#x20;   Electricity

&#x20;   ₹3,200

&#x20;   Pending



Dates should act as section headers.



Support:



\- search

\- filtering

\- sorting

\- category filtering

\- status filtering

\- date filtering



Possible filters:



&#x20;   All

&#x20;   Pending

&#x20;   Paid

&#x20;   Overdue

&#x20;   Due Today

&#x20;   Upcoming



\---



\# 16. OBLIGATION MODEL



Create a primary domain model:



&#x20;   Obligation



Suggested fields:



&#x20;   id

&#x20;   title

&#x20;   description

&#x20;   categoryId

&#x20;   icon

&#x20;   color

&#x20;   amount

&#x20;   currency

&#x20;   recurrenceRule

&#x20;   startDate

&#x20;   endDate

&#x20;   isActive

&#x20;   createdAt

&#x20;   updatedAt



Additional optional metadata:



&#x20;   providerName

&#x20;   accountReference

&#x20;   website

&#x20;   notes



Do not assume every obligation has an amount.



Some bills may have variable amounts.



\---



\# 17. OCCURRENCE MODEL



An obligation generates occurrences.



Example:



&#x20;   Obligation:

&#x20;       HDFC Credit Card

&#x20;       monthly

&#x20;       day 5



Generates:



&#x20;   Sep 5

&#x20;   Oct 5

&#x20;   Nov 5

&#x20;   Dec 5

&#x20;   ...



Occurrence fields:



&#x20;   id

&#x20;   obligationId

&#x20;   scheduledDate

&#x20;   status

&#x20;   expectedAmount

&#x20;   actualAmount

&#x20;   paymentId

&#x20;   notes

&#x20;   createdAt

&#x20;   updatedAt



Status enum:



&#x20;   pending

&#x20;   paid

&#x20;   skipped

&#x20;   overdue

&#x20;   cancelled



The UI should derive overdue state from date + status rather than requiring the server to permanently store "overdue".



\---



\# 18. PAYMENT MODEL



A payment is a separate entity.



Fields:



&#x20;   id

&#x20;   occurrenceId

&#x20;   paidAt

&#x20;   amount

&#x20;   paymentMethod

&#x20;   paymentApp

&#x20;   paymentBank

&#x20;   transactionReference

&#x20;   notes

&#x20;   createdAt

&#x20;   updatedAt



Payment method examples:



&#x20;   UPI

&#x20;   Bank Transfer

&#x20;   Debit Card

&#x20;   Credit Card

&#x20;   Net Banking

&#x20;   Cash

&#x20;   Auto Debit

&#x20;   Cheque

&#x20;   Other



Payment app examples:



&#x20;   Google Pay

&#x20;   PhonePe

&#x20;   Paytm

&#x20;   BHIM

&#x20;   Bank App

&#x20;   Other



Payment bank examples:



&#x20;   HDFC Bank

&#x20;   ICICI Bank

&#x20;   SBI

&#x20;   Axis Bank

&#x20;   Kotak

&#x20;   Other



Do not hardcode only Indian payment methods into the core architecture.



The data model should support future expansion.



\---



\# 19. MARK AS PAID UX



This is one of the most important workflows.



The user should NOT need to create another calendar event after paying.



When an obligation is marked Paid:



Show a payment sheet.



Example:



&#x20;   Mark HDFC Credit Card as Paid



&#x20;   Amount

&#x20;   ₹18,420



&#x20;   Paid on

&#x20;   Sep 17, 2026

&#x20;   8:31 PM



&#x20;   Payment method

&#x20;   UPI



&#x20;   Payment app

&#x20;   Google Pay



&#x20;   Payment bank

&#x20;   HDFC Bank



&#x20;   Transaction reference

&#x20;   Optional



&#x20;   Notes

&#x20;   Optional



&#x20;   \[Save Payment]



Date/time should default to the current date/time.



Allow editing.



After saving:



\- occurrence becomes Paid

\- payment record is created

\- calendar updates

\- task updates

\- dashboard updates

\- widget data updates

\- payment history is available



\---



\# 20. QUICK MARK PAID



For common workflows, support a quick action.



Example:



&#x20;   HDFC Credit Card

&#x20;   ₹18,420

&#x20;   \[Mark Paid]



Tapping it should open a lightweight payment form.



Do not force the user through a long form every time.



Remember recently used values where appropriate.



For example:



If the user repeatedly pays HDFC Credit Card using:



&#x20;   UPI

&#x20;   Google Pay

&#x20;   HDFC Bank



the app can preselect those values.



However, always allow changing them.



\---



\# 21. CATEGORY SYSTEM



Categories should be configurable.



Default categories:



1\. Bill Due Date

2\. Credit Card

3\. EMI

4\. Utility

5\. Loan

6\. Insurance

7\. Subscription

8\. Rent

9\. Tax

10\. Investment

11\. Other



Each category can have:



&#x20;   id

&#x20;   name

&#x20;   icon

&#x20;   color

&#x20;   sortOrder

&#x20;   isSystem

&#x20;   createdAt

&#x20;   updatedAt



Allow users to create custom categories.



\---



\# 22. CATEGORY-SPECIFIC FIELDS



The form should dynamically show relevant fields depending on category.



For example:



\## Credit Card



Fields:



&#x20;   Card name

&#x20;   Issuing bank

&#x20;   Due date

&#x20;   Statement date

&#x20;   Credit limit (optional)

&#x20;   Expected amount

&#x20;   Notes



Payment metadata:



&#x20;   Payment date/time

&#x20;   Payment method

&#x20;   Payment app

&#x20;   Payment bank

&#x20;   Transaction reference



\---



\# 23. EMI / LOAN



EMI obligations require additional information.



Fields:



&#x20;   EMI name

&#x20;   EMI amount

&#x20;   EMI due date

&#x20;   Bank account for auto debit

&#x20;   Deduction bank

&#x20;   Loan provider

&#x20;   Loan type

&#x20;   Loan account/reference

&#x20;   Tenure

&#x20;   Total installments

&#x20;   Paid installments

&#x20;   Remaining installments

&#x20;   Start date

&#x20;   End date

&#x20;   Interest rate (optional)

&#x20;   Principal amount (optional)



Loan type examples:



&#x20;   Home Loan

&#x20;   Car Loan

&#x20;   Personal Loan

&#x20;   Education Loan

&#x20;   Other



\---



\# 24. EMI BALANCE STATUS



Allow the user to mark:



&#x20;   "Enough balance available"



or



&#x20;   "Need to add funds"



This is NOT a bank balance integration.



It is a manual status.



Possible states:



&#x20;   sufficient

&#x20;   insufficient

&#x20;   unknown



The user can update this before the EMI date.



Example:



&#x20;   Home Loan EMI



&#x20;   ₹33,000



&#x20;   Auto debit:

&#x20;   HDFC Bank



&#x20;   Bank balance:

&#x20;   ✓ Enough balance



\---



\# 25. EMI INSTALLMENT TRACKING



For recurring EMI obligations:



Automatically track:



&#x20;   Installment 1 of 120

&#x20;   Installment 2 of 120

&#x20;   Installment 3 of 120



When an EMI occurrence is marked Paid:



&#x20;   paidInstallments += 1



Display:



&#x20;   23 / 120 paid



&#x20;   97 remaining



Do NOT blindly increment if an existing paid occurrence is edited.



The system must be idempotent.



\---



\# 26. RECURRENCE ENGINE



Recurring obligations are a core feature.



Support:



\- Every day

\- Every N days

\- Weekly

\- Every N weeks

\- Monthly

\- Every N months

\- Bi-annually

\- Yearly

\- Custom



Examples:



&#x20;   Every day

&#x20;   Every 2 days

&#x20;   Every week

&#x20;   Every 2 weeks

&#x20;   Every month

&#x20;   Every 2 months

&#x20;   Every 6 months

&#x20;   Every year



Monthly options:



&#x20;   Specific day of month



Example:



&#x20;   5th of every month



Also support:



&#x20;   Last day of month



Yearly:



&#x20;   Specific date



Example:



&#x20;   10 July every year



\---



\# 27. RECURRENCE EDGE CASES



Handle:



&#x20;   February 30

&#x20;   February 29

&#x20;   Months with 28/29/30/31 days

&#x20;   Leap years

&#x20;   DST changes

&#x20;   Time zones

&#x20;   End dates

&#x20;   Infinite recurrence



For monthly recurrence:



If the selected day does not exist in a month, provide a clear configurable behavior.



Example:



&#x20;   Feb 28



or



&#x20;   Last day of month



Do not create invalid dates.



Use Foundation Calendar APIs rather than manually calculating dates.



\---



\# 28. EDITING RECURRING ITEMS



When editing a recurring obligation, ask:



&#x20;   What do you want to change?



&#x20;   ○ This occurrence only

&#x20;   ○ This and future occurrences

&#x20;   ○ Entire series



This is essential.



For example:



&#x20;   HDFC Credit Card

&#x20;   monthly on 5th



Changing the amount should not necessarily rewrite historical payments.



Historical occurrences must remain intact.



\---



\# 29. DELETING RECURRING ITEMS



When deleting a recurring obligation:



&#x20;   Delete this occurrence

&#x20;   Delete this and future occurrences

&#x20;   Delete entire series



Historical paid records should not be silently destroyed.



Prefer soft deletion/archive where appropriate.



\---



\# 30. VARIABLE BILL AMOUNTS



Not all bills have fixed amounts.



Support:



&#x20;   Fixed amount

&#x20;   Variable amount

&#x20;   Amount unknown



Example:



&#x20;   Electricity

&#x20;   Due: 15th

&#x20;   Amount: Variable



When the bill amount becomes known, the user can enter:



&#x20;   ₹2,847



This should be stored against the occurrence, not necessarily the recurring obligation.



\---



\# 31. CURRENCY



Default currency:



&#x20;   INR



Display:



&#x20;   ₹33,000



Internally store currency codes using ISO-style codes:



&#x20;   INR

&#x20;   USD

&#x20;   EUR



Do not store currency symbols as the primary financial value.



\---



\# 32. DATE AND TIME



Use:



&#x20;   Foundation Date

&#x20;   Calendar

&#x20;   DateComponents



Store dates in a consistent format on the backend.



Display using the user's locale and timezone.



Default locale should follow the device.



Do not hardcode:



&#x20;   DD/MM/YYYY



unless appropriate for the user's locale.



\---



\# 33. NOTIFICATIONS



Support local notifications.



Examples:



&#x20;   HDFC Credit Card due tomorrow



&#x20;   Home Loan EMI due today



&#x20;   Electricity bill overdue



Notification timing should be configurable.



Examples:



&#x20;   On due date

&#x20;   1 day before

&#x20;   3 days before

&#x20;   7 days before



Allow multiple reminders.



Example:



&#x20;   7 days before

&#x20;   1 day before

&#x20;   On due date



\---



\# 34. NOTIFICATION CONTENT



Example:



&#x20;   HDFC Credit Card



&#x20;   ₹18,420 due tomorrow.



Possible actions:



&#x20;   Mark Paid

&#x20;   Snooze



Use actionable notifications where appropriate.



Do not put sensitive payment details into notifications if the user has configured privacy-sensitive behavior.



\---



\# 35. HOME SCREEN WIDGETS



The application MUST support iOS Home Screen widgets.



Use:



&#x20;   WidgetKit



Support at least:



&#x20;   Small

&#x20;   Medium

&#x20;   Large



Ideally support:



&#x20;   Lock Screen accessory widgets



if practical.



\---



\# 36. WIDGET 1: UPCOMING



Small widget.



Show:



&#x20;   Next due obligation



Example:



&#x20;   HDFC Credit Card



&#x20;   ₹18,420



&#x20;   Due tomorrow



Tapping opens the relevant occurrence.



\---



\# 37. WIDGET 2: TODAY



Small/Medium widget.



Example:



&#x20;   TODAY



&#x20;   3 payments



&#x20;   ₹41,420 total



&#x20;   • HDFC Credit Card

&#x20;   • Home Loan EMI

&#x20;   • Electricity



\---



\# 38. WIDGET 3: UPCOMING LIST



Medium widget.



Show the next 3-5 obligations.



Example:



&#x20;   UPCOMING



&#x20;   Today

&#x20;   Home Loan EMI       ₹33,000



&#x20;   Tomorrow

&#x20;   HDFC Credit Card    ₹18,420



&#x20;   Sep 20

&#x20;   Electricity          ₹2,847



\---



\# 39. WIDGET 4: MONTHLY SUMMARY



Medium/Large widget.



Show:



&#x20;   September



&#x20;   Paid       ₹82,400

&#x20;   Pending    ₹41,200

&#x20;   Total      ₹123,600



Optional:



&#x20;   8 / 12 paid



\---



\# 40. WIDGET 5: EMI



Large widget.



Show:



&#x20;   LOANS



&#x20;   Home Loan

&#x20;   53 / 120 paid



&#x20;   Car Loan

&#x20;   11 / 84 paid



Provide progress indicators.



\---



\# 41. WIDGET INTERACTIVITY



Where supported by the current iOS SDK, use interactive widgets/App Intents.



Potential action:



&#x20;   Mark Paid



However, do not compromise reliability.



If direct widget interaction is difficult, tapping should deep-link into the appropriate payment screen.



\---



\# 42. DEEP LINKING



Every important entity should have a deep link.



Examples:



&#x20;   duemate://obligation/{id}



&#x20;   duemate://occurrence/{id}



&#x20;   duemate://calendar/{date}



Widgets should open the relevant screen.



Notifications should also deep-link to the relevant occurrence.



\---



\# 43. ADD OBLIGATION FLOW



The user must be able to add an obligation quickly.



Floating action button or prominent:



&#x20;   + Add



Options:



&#x20;   Credit Card

&#x20;   EMI

&#x20;   Bill

&#x20;   Utility

&#x20;   Loan

&#x20;   Subscription

&#x20;   Insurance

&#x20;   Rent

&#x20;   Tax

&#x20;   Other



After selecting a category, show the appropriate form.



\---



\# 44. ADD BILL FORM



Fields:



&#x20;   Name

&#x20;   Category

&#x20;   Amount

&#x20;   Amount type

&#x20;   Due date

&#x20;   Recurrence

&#x20;   Reminder

&#x20;   Icon

&#x20;   Color

&#x20;   Notes



Optional:



&#x20;   Provider

&#x20;   Account/reference number



Buttons:



&#x20;   Cancel

&#x20;   Save



\---



\# 45. ADD CREDIT CARD FORM



Fields:



&#x20;   Card name

&#x20;   Bank

&#x20;   Due date

&#x20;   Statement date

&#x20;   Expected amount

&#x20;   Recurrence

&#x20;   Reminder

&#x20;   Icon

&#x20;   Color

&#x20;   Notes



Optional:



&#x20;   Credit limit

&#x20;   Last four digits



Never require users to enter full card numbers.



Never store CVV.



\---



\# 46. ADD EMI FORM



Fields:



&#x20;   Name

&#x20;   Loan type

&#x20;   EMI amount

&#x20;   Due day

&#x20;   Start date

&#x20;   Tenure

&#x20;   Loan provider

&#x20;   Deduction bank

&#x20;   Loan account/reference

&#x20;   Interest rate

&#x20;   Principal amount

&#x20;   Reminder

&#x20;   Notes



Automatically calculate:



&#x20;   installment count

&#x20;   approximate end date



where sufficient information exists.



\---



\# 47. ADD UTILITY FORM



Fields:



&#x20;   Utility name

&#x20;   Provider

&#x20;   Due date

&#x20;   Amount type

&#x20;   Recurrence

&#x20;   Reminder

&#x20;   Notes



Examples:



&#x20;   Electricity

&#x20;   Water

&#x20;   Gas

&#x20;   Internet

&#x20;   Mobile

&#x20;   Property Tax



\---



\# 48. DETAIL SCREEN



Each obligation should have a polished detail screen.



Header:



&#x20;   icon

&#x20;   title

&#x20;   category

&#x20;   status



Information:



&#x20;   Next due date

&#x20;   Amount

&#x20;   Recurrence

&#x20;   Reminder



For EMI:



&#x20;   Paid installments

&#x20;   Remaining installments

&#x20;   Loan provider

&#x20;   Deduction bank

&#x20;   EMI amount

&#x20;   Tenure



Payment history:



&#x20;   September 2026

&#x20;   ₹33,000

&#x20;   Paid Sep 1, 08:15



&#x20;   August 2026

&#x20;   ₹33,000

&#x20;   Paid Aug 1, 08:12



Actions:



&#x20;   Mark Paid

&#x20;   Edit

&#x20;   Pause

&#x20;   Archive

&#x20;   Delete



\---



\# 49. PAYMENT HISTORY



Every obligation should have historical payment information.



Example:



&#x20;   PAYMENT HISTORY



&#x20;   September 2026

&#x20;   Paid

&#x20;   ₹18,420

&#x20;   Sep 4, 8:31 PM



&#x20;   Method

&#x20;   UPI



&#x20;   App

&#x20;   Google Pay



&#x20;   Bank

&#x20;   HDFC Bank



&#x20;   Transaction reference

&#x20;   XXXXX



Payment history should be searchable and filterable.



\---



\# 50. PAYMENT EDITING



A payment record must be editable.



Allow changing:



&#x20;   payment date/time

&#x20;   amount

&#x20;   method

&#x20;   app

&#x20;   bank

&#x20;   transaction reference

&#x20;   notes



If a payment is deleted:



&#x20;   occurrence should return to Pending



unless explicitly marked otherwise.



\---



\# 51. STATUS COLORS



Use semantic colors consistently.



Suggested semantic system:



&#x20;   Pending

&#x20;   Warning/orange



&#x20;   Paid

&#x20;   Green



&#x20;   Overdue

&#x20;   Red



&#x20;   Scheduled

&#x20;   Neutral



Do not rely only on color.



Always combine:



&#x20;   color + icon + text



for accessibility.



\---



\# 52. CATEGORY COLORS



Each category can have its own accent color.



Example:



&#x20;   Credit Card

&#x20;   Blue



&#x20;   EMI

&#x20;   Purple



&#x20;   Utility

&#x20;   Orange



&#x20;   Insurance

&#x20;   Green



But users should be able to customize category colors.



Use the app's design system rather than hardcoded arbitrary colors throughout views.



\---



\# 53. ICON SYSTEM



Use SF Symbols by default.



Examples:



&#x20;   Credit Card

&#x20;   creditcard.fill



&#x20;   EMI

&#x20;   building.columns.fill



&#x20;   Utility

&#x20;   bolt.fill



&#x20;   Insurance

&#x20;   shield.fill



&#x20;   Subscription

&#x20;   repeat



Users should be able to change an item's icon.



Do not bundle hundreds of custom image assets unless necessary.



\---



\# 54. SEARCH



Global search should search:



&#x20;   obligation name

&#x20;   provider

&#x20;   bank

&#x20;   payment app

&#x20;   notes

&#x20;   transaction reference



Example:



Search:



&#x20;   HDFC



Results:



&#x20;   HDFC Credit Card

&#x20;   Home Loan - HDFC Bank

&#x20;   HDFC Bank payment



\---



\# 55. FILTERS



Tasks screen should support:



Status:



&#x20;   All

&#x20;   Pending

&#x20;   Paid

&#x20;   Overdue



Category:



&#x20;   All

&#x20;   Credit Card

&#x20;   EMI

&#x20;   Utility

&#x20;   etc.



Date:



&#x20;   Today

&#x20;   This week

&#x20;   This month

&#x20;   Custom



\---



\# 56. SORTING



Support:



&#x20;   Due date

&#x20;   Amount

&#x20;   Category

&#x20;   Recently updated



Default:



&#x20;   Due date ascending



\---



\# 57. DASHBOARD TOTALS



Calculate:



&#x20;   Total due today

&#x20;   Total due this week

&#x20;   Total due this month

&#x20;   Total paid this month

&#x20;   Total pending this month



Do not mix historical and future occurrences incorrectly.



For example:



"Paid this month"



must only include payment records whose payment date falls within the selected month.



\---



\# 58. FINANCIAL CALCULATIONS



Money should NOT be represented using floating point Double for financial calculations where precision matters.



Use a safe representation such as:



&#x20;   Decimal



or integer minor units where appropriate.



For INR:



&#x20;   ₹18,420.50



must not become:



&#x20;   ₹18,420.499999



\---



\# 59. EMPTY STATES



Every major screen needs a useful empty state.



Example:



Calendar:



&#x20;   No payments due today



Tasks:



&#x20;   You're all caught up 🎉



Obligations:



&#x20;   No obligations yet



&#x20;   Add your first bill, EMI or subscription.



Do not show blank screens.



\---



\# 60. ERROR HANDLING



Errors must be human readable.



Bad:



&#x20;   Error 500



Good:



&#x20;   Couldn't save this payment.

&#x20;   Please check your connection and try again.



Provide:



&#x20;   Retry



where appropriate.



Handle:



\- network unavailable

\- authentication expired

\- API errors

\- validation errors

\- malformed server response

\- local persistence errors



\---



\# 61. LOADING STATES



Use modern SwiftUI loading states.



Avoid blocking the entire application unnecessarily.



Use:



\- skeletons

\- progress indicators

\- optimistic updates where safe



For marking an item Paid:



Prefer:



&#x20;   UI updates immediately

&#x20;   local persistence

&#x20;   background sync



with rollback if necessary.



\---



\# 62. ACCESSIBILITY



The application must support:



\- Dynamic Type

\- VoiceOver

\- sufficient contrast

\- accessible labels

\- accessible hints

\- reduced motion

\- large text



Never rely solely on:



&#x20;   red = overdue

&#x20;   green = paid



Use labels and icons too.



\---



\# 63. DARK MODE



Full dark mode support is required.



Use semantic system colors.



Prefer:



&#x20;   Color.primary

&#x20;   Color.secondary

&#x20;   Color(.systemBackground)



and custom semantic colors defined in the design system.



Do not hardcode white/black everywhere.



\---



\# 64. DESIGN LANGUAGE



The UI should feel like a modern premium iOS application.



Design goals:



\- clean

\- calm

\- financial

\- information dense without feeling crowded

\- polished

\- native

\- fast



Use:



\- cards sparingly

\- rounded corners

\- subtle hierarchy

\- SF Symbols

\- system typography

\- native sheets

\- bottom sheets where appropriate

\- context menus

\- swipe actions



Avoid:



\- excessive gradients

\- excessive shadows

\- giant decorative graphics

\- web-style dashboards

\- unnecessary animations



\---



\# 65. DESIGN SYSTEM



Create centralized design tokens.



Example:



&#x20;   AppSpacing

&#x20;   AppCornerRadius

&#x20;   AppTypography

&#x20;   AppColors

&#x20;   AppIcons



This prevents random styling across screens.



Example:



&#x20;   AppSpacing.small

&#x20;   AppSpacing.medium

&#x20;   AppSpacing.large



Do not use arbitrary values everywhere.



\---



\# 66. ANIMATION



Use subtle animations.



Examples:



\- marking Paid

\- expanding payment history

\- changing calendar month

\- progress updates

\- adding/removing items



Animations should be:



\- fast

\- subtle

\- interruptible

\- compatible with Reduce Motion



\---



\# 67. PERFORMANCE



The application should remain fast with:



&#x20;   1,000+ obligations

&#x20;   10,000+ occurrences

&#x20;   10,000+ payment records



Avoid loading unnecessary historical records into memory.



Use:



\- SwiftData predicates

\- pagination

\- lazy containers

\- background processing



where appropriate.



\---



\# 68. API SYNCHRONIZATION



Implement a synchronization layer.



Conceptual flow:



&#x20;   Local change

&#x20;       ↓

&#x20;   Local database

&#x20;       ↓

&#x20;   Sync queue

&#x20;       ↓

&#x20;   API

&#x20;       ↓

&#x20;   Server response

&#x20;       ↓

&#x20;   Local database



Handle:



&#x20;   created

&#x20;   updated

&#x20;   deleted



records.



Each entity should have:



&#x20;   id

&#x20;   createdAt

&#x20;   updatedAt



Consider:



&#x20;   serverUpdatedAt



if useful.



\---



\# 69. CONFLICT HANDLING



The server is authoritative for synchronized data.



However, local unsynced changes must not be silently discarded.



Implement a basic conflict strategy.



At minimum:



&#x20;   latest updatedAt wins



For more complex conflicts:



&#x20;   preserve local pending mutation

&#x20;   fetch server version

&#x20;   resolve deterministically



Never silently lose user-entered payment data.



\---



\# 70. API PAGINATION



Assume APIs may eventually return large datasets.



Support pagination conceptually.



Example:



&#x20;   page

&#x20;   limit

&#x20;   nextCursor



Do not assume all records can always be downloaded in one request.



\---



\# 71. API RESPONSE FORMAT



Design Codable DTOs independently from domain models.



Example:



&#x20;   ObligationDTO

&#x20;   OccurrenceDTO

&#x20;   PaymentDTO



Map:



&#x20;   DTO → Domain Model



and:



&#x20;   Domain Model → Request DTO



Do not tightly couple SwiftUI views to raw API response objects.



\---



\# 72. MOCK DATA



Create a mock data provider.



It should generate realistic examples:



&#x20;   HDFC Credit Card

&#x20;   ICICI Credit Card

&#x20;   Home Loan EMI

&#x20;   Car Loan EMI

&#x20;   Electricity

&#x20;   Internet

&#x20;   Insurance

&#x20;   Netflix/Subscription

&#x20;   Property Tax



This allows the UI to be developed before the backend is ready.



Mock data must be isolated behind protocols.



\---



\# 73. PREVIEW DATA



Create SwiftUI Preview fixtures.



Examples:



&#x20;   PreviewData.sampleObligation

&#x20;   PreviewData.samplePayment

&#x20;   PreviewData.sampleEMI



All major views should have previews.



\---



\# 74. TESTING



Implement unit tests for:



\## Recurrence



Test:



\- daily

\- weekly

\- monthly

\- yearly

\- leap years

\- end-of-month

\- custom intervals



\## Payment



Test:



\- mark paid

\- mark unpaid

\- edit payment

\- delete payment



\## EMI



Test:



\- installment count

\- remaining installments

\- payment progression



\## Dashboard



Test:



\- monthly totals

\- pending totals

\- paid totals



\## API



Test:



\- decoding

\- encoding

\- errors

\- authentication



\---



\# 75. UI TESTS



Create UI tests for critical workflows:



1\. Add obligation

2\. Create recurring credit card

3\. Mark payment as Paid

4\. Edit payment

5\. View calendar

6\. View task list

7\. Filter tasks

8\. Add EMI

9\. Mark EMI paid

10\. View payment history



\---



\# 76. LOGGING



Use Apple's unified logging:



&#x20;   os.Logger



Create categories:



&#x20;   API

&#x20;   Persistence

&#x20;   Sync

&#x20;   Notifications

&#x20;   UI



Do not log sensitive financial information in production.



Never log:



\- passwords

\- authentication tokens

\- full account numbers

\- full card numbers

\- CVV

\- sensitive payment data



\---



\# 77. PRIVACY



The application contains potentially sensitive financial information.



Minimize data collection.



Do not request unnecessary permissions.



Permissions should only be requested when needed.



Potential permission:



&#x20;   Notifications



Calendar access should NOT be required for the app's own calendar unless a later feature explicitly requires integrating with Apple Calendar.



The app's internal calendar is independent of Apple Calendar.



\---



\# 78. APPLE CALENDAR INTEGRATION



Do NOT make EventKit a dependency for the core application.



The app should maintain its own calendar.



A future optional feature may allow:



&#x20;   Export to Apple Calendar



but this is not required for the first version.



\---



\# 79. SETTINGS



Settings should include:



\## Appearance



&#x20;   System

&#x20;   Light

&#x20;   Dark



\## Notifications



&#x20;   Enable notifications

&#x20;   Default reminder



\## Currency



&#x20;   INR



\## Week start



&#x20;   Device default

&#x20;   Monday

&#x20;   Sunday



\## Data



&#x20;   Sync

&#x20;   Export

&#x20;   Import



\## Security



&#x20;   Face ID

&#x20;   Passcode lock



\## About



&#x20;   Version

&#x20;   Privacy

&#x20;   Terms



\---



\# 80. APP LOCK



Design the architecture to support optional:



&#x20;   Face ID / Touch ID / Passcode



Use:



&#x20;   LocalAuthentication



The app should optionally require authentication when opening.



Do not implement custom password cryptography.



\---



\# 81. DATA EXPORT



Support future export.



Preferred formats:



&#x20;   JSON

&#x20;   CSV



Export should include:



&#x20;   obligations

&#x20;   occurrences

&#x20;   payments

&#x20;   categories



This ensures users can recover their data.



\---



\# 82. DATA IMPORT



Design for future import.



Potential:



&#x20;   JSON backup



Validate imported data before replacing local records.



Never blindly overwrite existing data.



\---



\# 83. DELETE ACCOUNT / DATA



If authentication/backend supports accounts, provide a path for:



&#x20;   Delete account

&#x20;   Delete cloud data



The UI should clearly warn the user before destructive operations.



\---



\# 84. CONFIRMATION RULES



Do not ask confirmation for trivial actions.



Examples:



Mark Paid:



&#x20;   No destructive confirmation.



Delete obligation:



&#x20;   Confirmation required.



Delete payment:



&#x20;   Confirmation required.



Archive:



&#x20;   No confirmation or lightweight confirmation.



\---



\# 85. SWIPE ACTIONS



Useful swipe actions:



Task:



&#x20;   Mark Paid

&#x20;   Delete



Payment:



&#x20;   Edit

&#x20;   Delete



Obligation:



&#x20;   Pause

&#x20;   Archive



Use destructive swipe actions carefully.



\---



\# 86. CONTEXT MENUS



Long press / context menu can provide:



&#x20;   Mark Paid

&#x20;   Edit

&#x20;   Duplicate

&#x20;   Pause

&#x20;   Archive

&#x20;   Delete



\---



\# 87. DUPLICATE OBLIGATION



Allow:



&#x20;   Duplicate



Useful for users who have:



&#x20;   multiple credit cards

&#x20;   multiple utilities

&#x20;   multiple subscriptions



The duplicate should get a new ID.



Do not duplicate historical payments.



\---



\# 88. PAUSE / RESUME



Recurring obligations should support:



&#x20;   Active

&#x20;   Paused

&#x20;   Archived



Example:



A subscription can be paused without deleting its history.



When resumed:



allow the user to choose the resume date.



\---



\# 89. ARCHIVING



Archived obligations:



\- remain in history

\- do not generate future occurrences

\- do not appear in default upcoming lists



Users can view archived obligations from settings or filters.



\---



\# 90. HOME SCREEN QUICK ACTIONS



Consider supporting iOS app shortcuts:



&#x20;   Add Bill

&#x20;   Add EMI

&#x20;   Mark Due Payment Paid

&#x20;   Open Calendar

&#x20;   Open Today's Tasks



Use App Intents where appropriate.



\---



\# 91. APP INTENTS



Design reusable App Intent actions.



Potential actions:



&#x20;   AddObligationIntent

&#x20;   MarkOccurrencePaidIntent

&#x20;   OpenTodayIntent



These may later power:



\- Shortcuts

\- Siri

\- widgets



\---



\# 92. WIDGET DATA



Widgets must not make direct network requests every time they render.



Use shared local data through:



&#x20;   App Groups



if required.



The main app should update widget timelines after relevant changes.



Use:



&#x20;   WidgetCenter.shared.reloadTimelines(...)



where appropriate.



\---



\# 93. WIDGET PRIVACY



Widget content may be visible without unlocking the phone.



Provide privacy-conscious widget options.



Potential widget setting:



&#x20;   Show amounts

&#x20;   Hide amounts



Potential:



&#x20;   Show sensitive details

&#x20;   Hide sensitive details



Do not expose transaction references or sensitive financial details by default.



\---



\# 94. WIDGET SIZES



At minimum implement:



&#x20;   Small

&#x20;   Medium

&#x20;   Large



Design each layout specifically for its size.



Do not simply scale one layout.



\---



\# 95. CALENDAR PERFORMANCE



Calendar rendering should not load every historical occurrence.



For a displayed month:



Fetch only the relevant date range plus minimal adjacent dates.



Example:



&#x20;   visible month

&#x20;   ± small buffer



\---



\# 96. TIME ZONES



All backend timestamps should be treated as absolute instants where appropriate.



Due dates without times should be represented as date-only semantics where possible.



Do not accidentally shift:



&#x20;   Sep 5



to:



&#x20;   Sep 4



because of UTC conversion.



This is especially important for recurring due dates.



\---



\# 97. DATE-ONLY VS DATETIME



Distinguish between:



\## Due date



Example:



&#x20;   September 5



This is a date-only concept.



\## Payment date/time



Example:



&#x20;   September 4, 8:31 PM



This is a datetime concept.



Do not treat all dates as timestamps.



\---



\# 98. FORM VALIDATION



Validate:



\- title required

\- recurrence valid

\- due date valid

\- amount >= 0

\- tenure > 0

\- installment count > 0



Show inline validation.



Do not wait until submission to explain obvious validation problems.



\---



\# 99. MONEY INPUT



Create a reusable money input component.



Requirements:



\- numeric keyboard

\- currency formatting

\- Decimal-safe parsing

\- no floating-point display errors



Example:



&#x20;   ₹ 33,000



\---



\# 100. REUSABLE COMPONENTS



Create reusable components such as:



&#x20;   ObligationRow

&#x20;   ObligationCard

&#x20;   PaymentRow

&#x20;   CategoryBadge

&#x20;   StatusBadge

&#x20;   MoneyText

&#x20;   DueDateLabel

&#x20;   EmptyStateView

&#x20;   SectionHeader

&#x20;   SummaryCard

&#x20;   RecurrencePicker

&#x20;   PaymentMethodPicker

&#x20;   BankPicker

&#x20;   IconPicker

&#x20;   ColorPicker



Do not duplicate these implementations across features.



\---



\# 101. DESIGN COMPONENT EXAMPLE



An obligation row should communicate:



&#x20;   \[ICON] HDFC Credit Card

&#x20;          Credit Card



&#x20;          Due Sep 17

&#x20;          ₹18,420



&#x20;                        Pending



It should remain readable at large Dynamic Type sizes.



\---



\# 102. TASK LIST VISUAL HIERARCHY



Recommended hierarchy:



&#x20;   DATE

&#x20;      ↓

&#x20;   Obligation name

&#x20;      ↓

&#x20;   Category + due time

&#x20;      ↓

&#x20;   Amount

&#x20;      ↓

&#x20;   Status



Paid items can have a subtle visual reduction but must remain readable.



Do not completely fade paid items.



\---



\# 103. CALENDAR VISUAL HIERARCHY



Each day should show:



&#x20;   day number



and small markers:



&#x20;   category dots



If selected:



&#x20;   highlighted date



If today:



&#x20;   distinct system treatment



Avoid excessive colors.



\---



\# 104. DASHBOARD DESIGN



The dashboard should prioritize:



&#x20;   What do I need to pay?



above:



&#x20;   Historical information



Order:



1\. Today

2\. Upcoming

3\. Pending/overdue

4\. Monthly summary

5\. Recent payments



\---



\# 105. OVERDUE LOGIC



An occurrence is overdue when:



&#x20;   scheduledDate < current date

&#x20;   AND

&#x20;   status != paid

&#x20;   AND

&#x20;   status != skipped

&#x20;   AND

&#x20;   status != cancelled



Do not permanently mutate the occurrence just because time passed.



This allows the UI to calculate overdue dynamically.



\---



\# 106. PAYMENT STATUS LOGIC



Possible state:



&#x20;   Pending



After payment:



&#x20;   Paid



If due date passes:



&#x20;   Overdue



If user intentionally skips:



&#x20;   Skipped



If recurrence is cancelled:



&#x20;   Cancelled



Paid status must be backed by a Payment entity.



\---



\# 107. PARTIAL PAYMENTS



Design the model to eventually support partial payments.



Example:



&#x20;   Due: ₹20,000



&#x20;   Payment 1: ₹10,000

&#x20;   Payment 2: ₹10,000



For MVP, the UI may initially support one payment per occurrence.



However, structure the backend/domain model so multiple payments can be supported later.



\---



\# 108. PAYMENT AMOUNT DIFFERENCE



If:



&#x20;   Expected = ₹18,000

&#x20;   Paid = ₹18,420



show:



&#x20;   Expected ₹18,000

&#x20;   Paid ₹18,420



Do not silently overwrite the expected amount.



\---



\# 109. PAYMENT METHODS



Use enums internally but make the backend extensible.



Example:



&#x20;   PaymentMethod.upi

&#x20;   PaymentMethod.bankTransfer

&#x20;   PaymentMethod.debitCard

&#x20;   PaymentMethod.creditCard

&#x20;   PaymentMethod.netBanking

&#x20;   PaymentMethod.cash

&#x20;   PaymentMethod.autoDebit

&#x20;   PaymentMethod.cheque

&#x20;   PaymentMethod.other



\---



\# 110. RECENT PAYMENT MEMORY



For convenience, the app can remember the last used:



&#x20;   payment method

&#x20;   payment app

&#x20;   payment bank



per obligation.



Example:



&#x20;   HDFC Credit Card



last used:



&#x20;   UPI

&#x20;   Google Pay

&#x20;   HDFC Bank



When marking it paid again, pre-fill these values.



The user can change them.



\---



\# 111. BANK DIRECTORY



Do not create a gigantic hardcoded bank database.



Initially provide common banks and:



&#x20;   Other



Allow users to create custom payment banks.



\---



\# 112. PAYMENT APP DIRECTORY



Initially:



&#x20;   Google Pay

&#x20;   PhonePe

&#x20;   Paytm

&#x20;   BHIM

&#x20;   Bank App

&#x20;   Other



Allow custom values.



\---



\# 113. CATEGORY MANAGEMENT



Settings → Categories



Show:



&#x20;   icon

&#x20;   color

&#x20;   name



Actions:



&#x20;   Add

&#x20;   Edit

&#x20;   Reorder

&#x20;   Archive



System categories may not be deletable if they are required by the app.



\---



\# 114. SAMPLE USER FLOW



Example:



User adds:



&#x20;   HDFC Credit Card



Category:



&#x20;   Credit Card



Due:



&#x20;   5th every month



Expected amount:



&#x20;   Variable



Reminder:



&#x20;   1 day before



Save.



The app generates:



&#x20;   September 5

&#x20;   October 5

&#x20;   November 5

&#x20;   ...



On September 4 user pays ₹18,420.



They open DueMate.



Tap:



&#x20;   Mark Paid



Payment form:



&#x20;   Amount: ₹18,420

&#x20;   Date: Sep 4

&#x20;   Time: 8:31 PM

&#x20;   Method: UPI

&#x20;   App: Google Pay

&#x20;   Bank: HDFC Bank



Save.



The September occurrence becomes:



&#x20;   Paid



October remains:



&#x20;   Pending



The September payment is available in:



&#x20;   Payment History



No additional calendar event is created.



\---



\# 115. SAMPLE EMI FLOW



User adds:



&#x20;   Home Loan EMI



Amount:



&#x20;   ₹33,000



Due:



&#x20;   7th monthly



Tenure:



&#x20;   120 months



Loan provider:



&#x20;   HDFC Bank



Deduction bank:



&#x20;   HDFC Bank



Start:



&#x20;   April 2022



The app shows:



&#x20;   Home Loan EMI



&#x20;   53 / 120 paid

&#x20;   67 remaining



Next:



&#x20;   Sep 7



When paid:



&#x20;   occurrence becomes Paid

&#x20;   installment count updates



Historical payment remains linked to:



&#x20;   Sep 2026 occurrence



\---



\# 116. MVP SCOPE



The first implementation MUST include:



\### Core



\- SwiftUI app

\- tab navigation

\- dashboard

\- calendar

\- task list

\- obligations list

\- add obligation

\- edit obligation

\- delete/archive obligation

\- recurring schedules

\- categories

\- payment recording

\- payment history

\- EMI tracking

\- local persistence

\- API abstraction

\- mock API/data provider

\- notifications

\- widgets

\- dark mode

\- accessibility



\---



\# 117. PHASE 2



After MVP is stable:



\- App Intents

\- Siri Shortcuts

\- Face ID app lock

\- advanced analytics

\- CSV export

\- JSON backup

\- import

\- richer widget interactivity

\- Apple Calendar export

\- multiple accounts/users

\- cloud conflict resolution improvements



\---



\# 118. DO NOT IMPLEMENT YET



Do not add:



\- bank account aggregation

\- automatic bank transaction scraping

\- automatic UPI transaction scraping

\- credit bureau integrations

\- investment portfolio tracking

\- stock tracking

\- cryptocurrency tracking

\- budgeting

\- net worth tracking



unless explicitly requested later.



The application is primarily an:



&#x20;   obligation + payment tracking system



not a full personal finance platform.



\---



\# 119. BACKEND ASSUMPTION



The frontend must not assume the backend already exists.



Implement:



&#x20;   APIClientProtocol



Example:



&#x20;   protocol APIClientProtocol {

&#x20;       func fetchObligations() async throws -> \[ObligationDTO]

&#x20;       func createObligation(...) async throws -> ObligationDTO

&#x20;       ...

&#x20;   }



Implement:



&#x20;   MockAPIClient



and:



&#x20;   LiveAPIClient



The app can initially run entirely against mock data.



\---



\# 120. API ENDPOINT CONVENTION



Use the following conceptual API structure:



&#x20;   GET    /api/obligations

&#x20;   POST   /api/obligations

&#x20;   GET    /api/obligations/{id}

&#x20;   PATCH  /api/obligations/{id}

&#x20;   DELETE /api/obligations/{id}



&#x20;   GET    /api/occurrences

&#x20;   GET    /api/occurrences/{id}

&#x20;   PATCH  /api/occurrences/{id}



&#x20;   POST   /api/payments

&#x20;   GET    /api/payments

&#x20;   GET    /api/payments/{id}

&#x20;   PATCH  /api/payments/{id}

&#x20;   DELETE /api/payments/{id}



&#x20;   GET    /api/categories

&#x20;   POST   /api/categories

&#x20;   PATCH  /api/categories/{id}

&#x20;   DELETE /api/categories/{id}



&#x20;   POST   /api/sync



These are proposed endpoints.



Do not assume these endpoints exist.



Keep endpoint definitions centralized so they can easily be changed.



\---



\# 121. API SIGNATURE



The user initially described the API as:



&#x20;   www.pradeepjadhav.com/api/"requiredSignature"



The actual implementation should use:



&#x20;   https://www.pradeepjadhav.com/api/



as the base URL.



Do not literally create an endpoint called:



&#x20;   "requiredSignature"



unless the backend specification explicitly requires it.



\---



\# 122. NETWORK ERROR UX



If offline:



&#x20;   "You're offline. Changes will sync when you're back online."



Do not prevent the user from recording a payment solely because the API is unavailable.



\---



\# 123. SYNC STATUS



Consider showing subtle sync state:



&#x20;   Synced

&#x20;   Syncing...

&#x20;   Offline

&#x20;   Sync failed



Do not make this visually dominant.



A small status indicator in Settings is sufficient for MVP.



\---



\# 124. FIRST LAUNCH



First launch should show a lightweight onboarding flow.



Screens:



1\. Welcome

2\. What DueMate does

3\. Notifications permission

4\. Add first obligation



Do not force users through a long onboarding questionnaire.



Provide:



&#x20;   Skip



where appropriate.



\---



\# 125. SAMPLE DATA MODE



For development builds:



&#x20;   Load sample data



This should be easy to disable/remove for production.



Sample data should demonstrate:



\- paid

\- pending

\- overdue

\- EMI

\- recurring bill

\- utility

\- credit card

\- subscription



\---



\# 126. APP ICON



Create a simple modern app icon concept.



Theme:



&#x20;   due date

&#x20;   checkmark

&#x20;   financial organization



Avoid overly detailed artwork.



The icon should remain recognizable at small sizes.



\---



\# 127. LOCALIZATION



Prepare the app for localization.



Do not hardcode user-visible strings throughout SwiftUI views.



Use:



&#x20;   Localizable.strings



or modern String Catalogs.



Initial language:



&#x20;   English



Future:



&#x20;   Hindi

&#x20;   Marathi



\---



\# 128. CODE QUALITY



The code must be:



\- strongly typed

\- documented where complexity warrants

\- modular

\- testable

\- readable

\- maintainable



Avoid:



\- massive View structs

\- global mutable state

\- singleton abuse

\- force unwraps

\- magic numbers

\- duplicated networking code

\- duplicated formatting logic



\---



\# 129. SWIFT CONCURRENCY



Use modern Swift concurrency.



Prefer:



&#x20;   async/await



Avoid callback pyramids.



Use actors where shared mutable state requires synchronization.



Ensure UI updates occur on the MainActor.



\---



\# 130. OBSERVATION



Prefer Apple's modern Observation framework where appropriate.



Use:



&#x20;   @Observable



instead of creating unnecessary ObservableObject boilerplate for new code.



Do not force Observation everywhere if another architecture is cleaner.



\---



\# 131. DEPENDENCY INJECTION



Services should be injected.



Examples:



&#x20;   APIClient

&#x20;   PersistenceController

&#x20;   NotificationService

&#x20;   AuthenticationService

&#x20;   SyncService



Avoid direct construction inside every View.



\---



\# 132. ENVIRONMENT



Use an application environment/container.



Conceptually:



&#x20;   AppEnvironment



containing:



&#x20;   apiClient

&#x20;   persistence

&#x20;   notificationService

&#x20;   syncService

&#x20;   authService



This makes previews and tests easy.



\---



\# 133. DATA FLOW



Preferred:



&#x20;   View

&#x20;     ↓

&#x20;   ViewModel / Feature Model

&#x20;     ↓

&#x20;   Domain Service

&#x20;     ↓

&#x20;   Repository

&#x20;     ↓

&#x20;   Local Persistence / API



The View must not directly perform network requests.



\---



\# 134. REPOSITORY PATTERN



Use repositories where useful.



Example:



&#x20;   ObligationRepository



responsibilities:



\- fetch

\- create

\- update

\- delete

\- observe

\- synchronize



Do not create abstractions purely for ceremony.



Use them where they improve testability and separation.



\---



\# 135. DOMAIN SERVICES



Create services for complex business logic.



Examples:



&#x20;   RecurrenceService

&#x20;   PaymentService

&#x20;   EMIService

&#x20;   DashboardService

&#x20;   NotificationScheduler

&#x20;   SyncService



Keep business rules out of SwiftUI Views.



\---



\# 136. NOTIFICATION SCHEDULER



Notification scheduling should be based on occurrences.



If an occurrence is:



&#x20;   Paid



cancel reminders for that occurrence.



If payment is removed:



restore appropriate reminder scheduling if needed.



Do not schedule notifications indefinitely for every possible future recurrence.



Schedule a reasonable future window and refresh as necessary.



\---



\# 137. CALENDAR GENERATION



Do not pre-generate millions of future occurrences.



Use a bounded generation strategy.



For example:



&#x20;   current date

&#x20;   + 12 months



or generate occurrences lazily.



Historical occurrences should remain persistent.



\---



\# 138. HISTORICAL DATA



Historical paid occurrences are valuable.



Do not delete them simply because the obligation is archived.



Example:



&#x20;   Car Loan



After loan completion:



&#x20;   84 / 84 paid



The user should still be able to see all historical payments.



\---



\# 139. COMPLETED LOANS



When all installments are paid:



Show:



&#x20;   Loan Completed 🎉



The recurring schedule should stop generating future EMI occurrences.



\---



\# 140. LOAN EARLY CLOSURE



Design for:



&#x20;   Closed early



Example:



&#x20;   45 / 84 paid



User closes loan.



The obligation becomes:



&#x20;   Completed early



Future occurrences stop.



History remains.



\---



\# 141. EMI PREPAYMENT



Do not implement complex amortization calculations in MVP.



However, the model should not prevent future support for:



&#x20;   principal prepayment

&#x20;   EMI reduction

&#x20;   tenure reduction



Keep the architecture extensible.



\---



\# 142. USER EXPERIENCE PRIORITY



Optimize for the most common action:



&#x20;   "I just paid something."



This should take only a few seconds.



Ideal flow:



&#x20;   Open app

&#x20;     ↓

&#x20;   Today's task

&#x20;     ↓

&#x20;   Mark Paid

&#x20;     ↓

&#x20;   Confirm/pre-filled payment info

&#x20;     ↓

&#x20;   Save



Do not make users manually create a second event.



\---



\# 143. QUICK ADD



Support quick add from the Home screen.



Example:



&#x20;   + Add



Then:



&#x20;   Bill

&#x20;   Credit Card

&#x20;   EMI

&#x20;   Utility

&#x20;   Subscription

&#x20;   Other



Keep this interaction fast.



\---



\# 144. INFORMATION DENSITY



Financial apps require information density.



Use hierarchy rather than excessive whitespace.



A user should quickly see:



&#x20;   WHAT

&#x20;   WHEN

&#x20;   HOW MUCH

&#x20;   STATUS



Then secondary information:



&#x20;   category

&#x20;   provider

&#x20;   bank

&#x20;   recurrence



\---



\# 145. NO UNNECESSARY CONFIRMATION



For:



&#x20;   Mark Paid



do not show:



&#x20;   "Are you sure?"



Instead show a payment form.



For:



&#x20;   Delete payment



show confirmation.



\---



\# 146. SEARCHABLE PAYMENT HISTORY



Eventually support:



&#x20;   Search all payments



Example:



&#x20;   Search: Google Pay



Results:



&#x20;   Sep 4 - HDFC Credit Card

&#x20;   Aug 5 - ICICI Credit Card

&#x20;   Jul 7 - Electricity



\---



\# 147. ANALYTICS



For MVP, basic analytics can show:



&#x20;   Total paid

&#x20;   Total pending

&#x20;   Payments by category



Do not turn this into a budgeting application.



\---



\# 148. MONTHLY SUMMARY



Allow selecting:



&#x20;   September 2026



Show:



&#x20;   Total scheduled

&#x20;   Total paid

&#x20;   Total pending

&#x20;   Total overdue



Example:



&#x20;   Scheduled     ₹1,45,000

&#x20;   Paid          ₹98,000

&#x20;   Pending       ₹47,000



\---



\# 149. CATEGORY SUMMARY



Example:



&#x20;   Credit Cards

&#x20;   ₹48,200



&#x20;   EMIs

&#x20;   ₹54,500



&#x20;   Utilities

&#x20;   ₹7,840



This is useful on the dashboard.



\---



\# 150. FUTURE EXTENSIBILITY



The architecture should make it possible to add:



\- multiple currencies

\- multiple users

\- family sharing

\- bank integrations

\- automatic transaction matching

\- OCR bill scanning

\- email bill detection

\- WhatsApp bill reminders

\- AI payment categorization



But none of these should complicate the MVP.



\---



\# 151. DEVELOPMENT PROCESS



The AI coding agent must work in phases.



Do NOT attempt to generate the entire application in one giant implementation.



Use the following phases.



\---



\# PHASE 1: PROJECT FOUNDATION



Implement:



\- Xcode project

\- SwiftUI

\- app entry point

\- architecture

\- design system

\- navigation

\- dependency injection

\- mock environment



Requirement:



The project must compile.



\---



\# PHASE 2: DOMAIN MODELS



Implement:



\- Obligation

\- Occurrence

\- Payment

\- Category

\- RecurrenceRule

\- EMI metadata



Implement:



\- enums

\- Codable support

\- persistence models

\- DTO models



Add unit tests.



\---



\# PHASE 3: LOCAL PERSISTENCE



Implement:



\- SwiftData

\- repositories

\- local CRUD

\- sample data



Requirement:



App works without API.



\---



\# PHASE 4: HOME



Implement:



\- dashboard

\- summary cards

\- upcoming

\- pending

\- recent payments



Polish UI.



\---



\# PHASE 5: OBLIGATIONS



Implement:



\- obligation list

\- add

\- edit

\- delete

\- archive

\- pause

\- category selection

\- recurrence



\---



\# PHASE 6: CALENDAR



Implement:



\- monthly calendar

\- date selection

\- occurrence indicators

\- day detail

\- editing



\---



\# PHASE 7: TASKS



Implement:



\- date grouped list

\- search

\- filtering

\- sorting

\- swipe actions



\---



\# PHASE 8: PAYMENT WORKFLOW



Implement:



\- mark paid

\- payment form

\- payment history

\- edit payment

\- delete payment

\- quick mark paid



This phase is especially important.



\---



\# PHASE 9: EMI



Implement:



\- EMI form

\- installment tracking

\- bank balance status

\- loan metadata

\- completion state



\---



\# PHASE 10: NOTIFICATIONS



Implement:



\- notification permission

\- reminder scheduling

\- paid occurrence cancellation

\- configurable reminders



\---



\# PHASE 11: WIDGETS



Implement:



\- WidgetKit target

\- Small

\- Medium

\- Large

\- upcoming

\- today's payments

\- monthly summary

\- EMI summary



Add deep links.



\---



\# PHASE 12: API



Implement:



\- APIClient

\- LiveAPIClient

\- DTOs

\- repository synchronization

\- authentication abstraction

\- sync queue



Use the configured API base URL.



\---



\# PHASE 13: POLISH



Implement:



\- dark mode

\- accessibility

\- animations

\- empty states

\- error states

\- loading states

\- performance improvements



\---



\# PHASE 14: TESTING



Add:



\- unit tests

\- recurrence tests

\- payment tests

\- EMI tests

\- repository tests

\- API decoding tests

\- UI tests



\---



\# 152. CODING AGENT RULES



The coding agent must follow these rules.



\## Rule 1



Never leave the project in a non-compiling state at the end of a phase.



\## Rule 2



Do not invent backend API behavior without clearly isolating it behind protocols.



\## Rule 3



Do not hardcode data that should be user configurable.



\## Rule 4



Do not put business logic in SwiftUI Views.



\## Rule 5



Do not use deprecated APIs when a modern replacement exists.



\## Rule 6



Prefer Apple's native frameworks before third-party dependencies.



\## Rule 7



Use the latest stable APIs available for the target iOS version.



\## Rule 8



Do not add dependencies unless they provide meaningful value.



\## Rule 9



Do not over-engineer simple features.



\## Rule 10



Do not sacrifice maintainability for speed of implementation.



\---



\# 153. THIRD-PARTY LIBRARIES



Prefer:



&#x20;   SwiftUI

&#x20;   Foundation

&#x20;   SwiftData

&#x20;   WidgetKit

&#x20;   UserNotifications

&#x20;   LocalAuthentication

&#x20;   AppIntents

&#x20;   OSLog



before adding external libraries.



If a third-party library is proposed:



1\. Explain why it is needed.

2\. Confirm there is no suitable Apple-native alternative.

3\. Use the latest stable version compatible with the target SDK.

4\. Keep it isolated.



\---



\# 154. DOCUMENTATION



Document complex business rules.



Especially:



\- recurrence

\- EMI installment logic

\- synchronization

\- payment state transitions

\- date handling

\- conflict resolution



Do not write comments explaining obvious code.



\---



\# 155. GIT PRACTICES



Use small logical commits.



Suggested commits:



&#x20;   feat: initialize iOS project

&#x20;   feat: add domain models

&#x20;   feat: add local persistence

&#x20;   feat: add dashboard

&#x20;   feat: add calendar

&#x20;   feat: add task list

&#x20;   feat: add payment workflow

&#x20;   feat: add EMI tracking

&#x20;   feat: add notifications

&#x20;   feat: add widgets

&#x20;   feat: add API layer

&#x20;   test: add domain tests

&#x20;   polish: improve accessibility and UI



Never commit:



\- API secrets

\- tokens

\- credentials

\- generated sensitive data



\---



\# 156. README



Create a README containing:



\- app overview

\- architecture

\- setup instructions

\- API configuration

\- build instructions

\- test instructions

\- widget setup

\- environment configuration

\- project structure



\---



\# 157. CONFIGURATION



Use separate configurations:



&#x20;   Debug

&#x20;   Release



Development API configuration should be easy to change.



Do not require source-code modifications just to switch API environments.



Prefer:



&#x20;   Development

&#x20;   Staging

&#x20;   Production



if the backend eventually provides them.



\---



\# 158. CRASH SAFETY



Avoid:



&#x20;   force unwraps



unless absolutely guaranteed.



Avoid:



&#x20;   fatalError()



in production paths.



Gracefully handle missing data.



\---



\# 159. BACKWARD COMPATIBILITY



Target:



&#x20;   iOS 18+



Do not write compatibility code for very old iOS versions unless necessary.



Use modern APIs directly where the deployment target supports them.



\---



\# 160. FINAL UX CHECKLIST



Before considering MVP complete, verify:



\[ ] I can add a credit card



\[ ] I can make it recurring monthly



\[ ] I can see it on the calendar



\[ ] I can see it in the task list



\[ ] I can mark it paid



\[ ] I can record payment date/time



\[ ] I can record payment method



\[ ] I can record payment app



\[ ] I can record payment bank



\[ ] I can view payment history



\[ ] I can edit a payment



\[ ] I can delete a payment



\[ ] I can add an EMI



\[ ] EMI installments are tracked



\[ ] I can record deduction bank



\[ ] I can mark bank balance sufficient



\[ ] I can create utility bills



\[ ] I can create yearly obligations



\[ ] I can create weekly obligations



\[ ] I can create daily obligations



\[ ] I can create custom recurrence



\[ ] I can pause recurring items



\[ ] I can archive recurring items



\[ ] I can edit one occurrence



\[ ] I can edit future occurrences



\[ ] I can delete one occurrence



\[ ] I can see overdue items



\[ ] I can filter tasks



\[ ] I can search obligations



\[ ] Notifications work



\[ ] Small widget works



\[ ] Medium widget works



\[ ] Large widget works



\[ ] Widget deep links work



\[ ] Dark mode works



\[ ] Dynamic Type works



\[ ] VoiceOver labels exist



\[ ] App works offline



\[ ] Data sync architecture exists



\[ ] API implementation is isolated



\[ ] Unit tests pass



\[ ] UI tests for critical flows pass



\[ ] No secrets are committed



\---



\# 161. DEFINITION OF DONE



The application is considered MVP-complete when a user can perform this complete journey:



1\. Launch DueMate.

2\. Add an HDFC Credit Card.

3\. Set it to recur on the 5th of every month.

4\. See it on the Calendar.

5\. See it in Tasks.

6\. Receive a reminder.

7\. Pay the card.

8\. Tap Mark Paid.

9\. Record:

&#x20;  - amount

&#x20;  - payment date/time

&#x20;  - UPI

&#x20;  - Google Pay

&#x20;  - HDFC Bank

10\. Save the payment.

11\. See the item become Paid.

12\. View the payment in history.

13\. Navigate to the next month's occurrence.

14\. Add a Home Loan EMI.

15\. Track its installment count.

16\. Record the deduction bank.

17\. Mark bank balance as sufficient.

18\. See the EMI on the calendar.

19\. See upcoming obligations on the Home Screen widget.

20\. Open the app from the widget.

21\. Continue using the app without manually creating secondary calendar events.



\---



\# 162. IMPORTANT PRODUCT PHILOSOPHY



The application exists to eliminate repetitive manual bookkeeping.



Whenever a workflow requires the user to enter the same information twice, reconsider the design.



Bad:



&#x20;   Calendar reminder

&#x20;       ↓

&#x20;   Mark done

&#x20;       ↓

&#x20;   Create another calendar event

&#x20;       ↓

&#x20;   Enter payment details



Good:



&#x20;   Obligation

&#x20;       ↓

&#x20;   Mark Paid

&#x20;       ↓

&#x20;   Payment form

&#x20;       ↓

&#x20;   Payment history



The application should make the user's financial obligations feel like a structured system rather than a pile of calendar reminders.



\---



\# 163. AGENT EXECUTION INSTRUCTION



Start by inspecting the existing repository.



Before writing code:



1\. Determine whether an iOS project already exists.

2\. Inspect existing files.

3\. Determine the current Xcode/Swift configuration.

4\. Identify existing dependencies.

5\. Do not overwrite useful existing work.

6\. Create a concise implementation plan.



Then implement Phase 1.



After each phase:



1\. Build the project.

2\. Fix compilation errors.

3\. Run relevant tests.

4\. Verify the feature manually where possible.

5\. Keep the codebase clean.

6\. Update README/documentation where needed.

7\. Move to the next phase only after the current phase is stable.



Do not generate placeholder implementations for core functionality and declare the feature complete.



If backend APIs are unavailable, use proper mock implementations behind protocols.



Do not stop after creating UI mockups.



The final result must be a functioning native iOS application with real local state, domain logic, recurrence handling, payment tracking, widgets, notifications, and an API integration layer.



\---



\# END OF SPECIFICATION

