import SwiftUI
import SwiftData
import MapKit

// MARK: - Time Period

private enum TimePeriod: String, CaseIterable {
    case week, month, year

    var localizedLabel: String {
        switch self {
        case .week:  L10n.t("Week", "周")
        case .month: L10n.t("Month", "月")
        case .year:  L10n.t("Year", "年")
        }
    }
}

// MARK: - Calendar Day Model

private struct CalendarDay: Identifiable {
    let id: Int
    let date: Date?
    let mood: MoodTag?
    let isToday: Bool
    let isInPeriod: Bool
}

// MARK: - Sub-Period Item

private struct SubPeriodItem: Identifiable {
    let id: Int   // offset value
    let label: String
}

// MARK: - Mood Stats View

struct MoodStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var allEntries: [JournalEntry]

    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedMonthOffset: Int = 0
    @State private var selectedWeekOffset: Int = 0
    @State private var selectedYearOffset: Int = 0

    private let cal = Calendar.current

    var body: some View {
        // All derived data in ONE pass — the sections previously each ran
        // their own full scan (5+ per body evaluation, re-run for every
        // frame of the period-switch animation).
        let stats = makeStats()
        ZStack {
            TreeholeTheme.warmBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: TreeholeTheme.spacingLarge) {
                    placesMapSection(located: stats.located)
                    periodPickerSection
                    subPeriodScroller
                    calendarSection(stats: stats)
                    distributionSection(counts: stats.moodCounts)
                    streakSection(streaks: stats.streaks)
                }
                .padding(.horizontal, TreeholeTheme.spacingMedium)
                .padding(.vertical, TreeholeTheme.spacingSmall)
            }
        }
        .navigationTitle(L10n.t("Mood Stats", "情绪统计"))
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Places Map Section

    @ViewBuilder
    private func placesMapSection(located: [JournalEntry]) -> some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(TreeholeTheme.skyBlue)
                Text(L10n.t("Places", "地点"))
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
            }

            if located.isEmpty {
                Text(L10n.t(
                    "Add a location to your next entry to see it here",
                    "在下一条日记中添加位置以在这里查看"
                ))
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textLight)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TreeholeTheme.spacingMedium)
            } else {
                PlacesMapView(entries: located)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
            }
        }
        .glassCard()
    }

    // MARK: - Period Picker

    private var periodPickerSection: some View {
        Picker(L10n.t("Period", "周期"), selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.localizedLabel).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, TreeholeTheme.spacingSmall)
    }

    // MARK: - Sub-Period Scroller

    private var subPeriodScroller: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TreeholeTheme.spacingSmall) {
                    ForEach(subPeriodItems) { item in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                switch selectedPeriod {
                                case .week:  selectedWeekOffset = item.id
                                case .month: selectedMonthOffset = item.id
                                case .year:  selectedYearOffset = item.id
                                }
                            }
                        } label: {
                            Text(item.label)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(isSelected(item.id) ? Color.white : TreeholeTheme.textPrimary)
                                .padding(.horizontal, TreeholeTheme.spacingSmall)
                                .padding(.vertical, 8)
                                .background(
                                    isSelected(item.id) ? TreeholeTheme.softPurple : Color.clear,
                                    in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium)
                                )
                        }
                        .id(item.id)
                        .accessibilityAddTraits(isSelected(item.id) ? [.isSelected] : [])
                    }
                }
                .padding(.horizontal, TreeholeTheme.spacingMedium)
            }
            .onAppear { proxy.scrollTo(0, anchor: .center) }
            .onChange(of: selectedPeriod) { proxy.scrollTo(0, anchor: .center) }
        }
    }

    private var subPeriodItems: [SubPeriodItem] {
        switch selectedPeriod {
        case .month:
            return (-11...0).map { offset in
                let date = cal.date(byAdding: .month, value: offset, to: Date()) ?? Date()
                let label = date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
                return SubPeriodItem(id: offset, label: label)
            }
        case .year:
            return (-4...0).map { offset in
                let date = cal.date(byAdding: .year, value: offset, to: Date()) ?? Date()
                let label = date.formatted(.dateTime.year())
                return SubPeriodItem(id: offset, label: label)
            }
        case .week:
            return (-7...0).map { offset in
                let start = weekStart(offset: offset)
                let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
                let s = start.formatted(.dateTime.month(.abbreviated).day())
                let e = end.formatted(.dateTime.month(.abbreviated).day())
                return SubPeriodItem(id: offset, label: "\(s)–\(e)")
            }
        }
    }

    private func isSelected(_ offset: Int) -> Bool {
        switch selectedPeriod {
        case .week:  selectedWeekOffset == offset
        case .month: selectedMonthOffset == offset
        case .year:  selectedYearOffset == offset
        }
    }

    // MARK: - Calendar Section

    private func calendarSection(stats: StatsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            Text(L10n.t("Average Mood", "情绪概览"))
                .font(.headline)
                .foregroundStyle(TreeholeTheme.textPrimary)
            calendarGrid(stats: stats)
        }
        .glassCard()
    }

    @ViewBuilder
    private func calendarGrid(stats: StatsSnapshot) -> some View {
        if selectedPeriod == .year {
            yearGrid(moodByMonth: stats.dominantMoodByMonth)
        } else {
            dayGrid(moodByDay: stats.dominantMoodByDay)
        }
    }

    private func dayGrid(moodByDay: [Date: MoodTag]) -> some View {
        VStack(spacing: 6) {
            // Weekday headers Mon–Sun
            HStack(spacing: 6) {
                ForEach(weekdayHeaders, id: \.self) { label in
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TreeholeTheme.textLight)
                        .frame(maxWidth: .infinity)
                }
            }

            let days = selectedPeriod == .week
                ? buildWeekDays(moodByDay: moodByDay)
                : buildMonthDays(moodByDay: moodByDay)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days) { day in
                    dayCellView(day)
                }
            }
        }
    }

    /// Year mode: 12 month cells, each showing the month's dominant mood.
    private func yearGrid(moodByMonth: [Date: MoodTag]) -> some View {
        let months = buildYearMonths(moodByMonth: moodByMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
        return LazyVGrid(columns: columns, spacing: TreeholeTheme.spacingSmall) {
            ForEach(months) { month in
                monthCellView(month)
            }
        }
    }

    private var weekdayHeaders: [String] {
        var symbols = cal.shortWeekdaySymbols   // [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
        let sun = symbols.removeFirst()
        symbols.append(sun)                     // [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
        return symbols.map { String($0.prefix(1)) }
    }

    @ViewBuilder
    private func dayCellView(_ day: CalendarDay) -> some View {
        ZStack {
            if day.isInPeriod {
                if let mood = day.mood {
                    if day.isToday {
                        Circle()
                            .strokeBorder(TreeholeTheme.softPurple, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                    Text(mood.emoji)
                        .font(.system(size: 22))
                        .frame(width: 36, height: 36)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 36, height: 36)
                        if day.isToday {
                            Circle()
                                .strokeBorder(TreeholeTheme.softPurple, lineWidth: 2)
                                .frame(width: 36, height: 36)
                        }
                    }
                }
            } else {
                Color.clear
                    .frame(width: 36, height: 36)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cellAccessibilityLabel(day, dateFormat: .dateTime.month(.wide).day()))
    }

    /// One VoiceOver element per calendar cell: "April 5, Happy" / "April 5, no entry".
    /// Out-of-period filler cells produce an empty label (skipped by VoiceOver).
    private func cellAccessibilityLabel(_ day: CalendarDay, dateFormat: Date.FormatStyle) -> String {
        guard day.isInPeriod, let date = day.date else { return "" }
        let dateStr = date.formatted(dateFormat)
        let todayPrefix = day.isToday ? L10n.t("Today, ", "今天，") : ""
        if let mood = day.mood {
            return todayPrefix + dateStr + ", " + L10n.t(mood.labelEN, mood.labelZH)
        }
        return todayPrefix + dateStr + ", " + L10n.t("no entry", "无日记")
    }

    @ViewBuilder
    private func monthCellView(_ month: CalendarDay) -> some View {
        VStack(spacing: 4) {
            Text(month.date?.formatted(.dateTime.month(.abbreviated)) ?? "")
                .font(.caption2.weight(month.isToday ? .semibold : .regular))
                .foregroundStyle(month.isToday ? TreeholeTheme.softPurple : TreeholeTheme.textLight)

            ZStack {
                if month.isToday {
                    Circle()
                        .strokeBorder(TreeholeTheme.softPurple, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }
                if let mood = month.mood {
                    Text(mood.emoji)
                        .font(.system(size: 22))
                } else {
                    // In-period months without entries get the same gray dot
                    // as empty days; future months are barely visible.
                    Circle()
                        .fill(Color.gray.opacity(month.isInPeriod ? 0.2 : 0.08))
                        .frame(width: 36, height: 36)
                }
            }
            .frame(width: 36, height: 36)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(cellAccessibilityLabel(month, dateFormat: .dateTime.month(.wide)))
    }

    // MARK: - Calendar Day Building

    private func buildMonthDays(moodByDay: [Date: MoodTag]) -> [CalendarDay] {
        let target = cal.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
        guard
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: target)),
            let monthRange = cal.range(of: .day, in: .month, for: monthStart)
        else { return [] }

        let today = cal.startOfDay(for: Date())

        let leading = isoWeekday(monthStart) - 1
        var days: [CalendarDay] = []

        for i in 0..<leading {
            days.append(CalendarDay(id: -(leading - i), date: nil, mood: nil, isToday: false, isInPeriod: false))
        }

        for dayNum in monthRange {
            guard let date = cal.date(byAdding: .day, value: dayNum - 1, to: monthStart) else { continue }
            let dayStart = cal.startOfDay(for: date)
            days.append(CalendarDay(
                id: dayNum,
                date: date,
                mood: moodByDay[dayStart],
                isToday: dayStart == today,
                isInPeriod: true
            ))
        }

        let trailing = (7 - (days.count % 7)) % 7
        for i in 0..<trailing {
            days.append(CalendarDay(id: 1000 + i, date: nil, mood: nil, isToday: false, isInPeriod: false))
        }

        return days
    }

    private func buildWeekDays(moodByDay: [Date: MoodTag]) -> [CalendarDay] {
        let start = weekStart(offset: selectedWeekOffset)
        let today = cal.startOfDay(for: Date())

        return (0..<7).map { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: start) else {
                return CalendarDay(id: offset, date: nil, mood: nil, isToday: false, isInPeriod: false)
            }
            let dayStart = cal.startOfDay(for: date)
            return CalendarDay(
                id: offset,
                date: date,
                mood: moodByDay[dayStart],
                isToday: dayStart == today,
                isInPeriod: true
            )
        }
    }

    /// One CalendarDay per month of the selected year, mood = dominant mood
    /// across all of that month's entries. Future months are out-of-period.
    private func buildYearMonths(moodByMonth: [Date: MoodTag]) -> [CalendarDay] {
        let range = currentDateRange
        let currentMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date()))

        return (0..<12).compactMap { m in
            guard let monthStart = cal.date(byAdding: .month, value: m, to: range.start) else { return nil }
            return CalendarDay(
                id: m + 1,
                date: monthStart,
                mood: moodByMonth[monthStart],
                isToday: monthStart == currentMonthStart,
                isInPeriod: monthStart <= Date()
            )
        }
    }

    // MARK: - Distribution Section

    private func distributionSection(counts: [MoodTag: Int]) -> some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            Text(L10n.t("Mood Distribution", "情绪分布"))
                .font(.headline)
                .foregroundStyle(TreeholeTheme.textPrimary)

            let maxCount = counts.values.max() ?? 1
            let sorted = MoodTag.allCases
                .filter { (counts[$0] ?? 0) > 0 }
                .sorted { (counts[$0] ?? 0) > (counts[$1] ?? 0) }

            if sorted.isEmpty {
                Text(L10n.t("No entries in this period.", "此时间段内没有日记。"))
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textLight)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, TreeholeTheme.spacingSmall)
            } else {
                VStack(spacing: TreeholeTheme.spacingSmall) {
                    ForEach(sorted) { mood in
                        MoodBarRow(
                            mood: mood,
                            count: counts[mood] ?? 0,
                            maxCount: maxCount,
                            barColor: moodColor(mood)
                        )
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Streak Section

    private func streakSection(streaks: (current: Int, longest: Int)) -> some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            Text(L10n.t("Writing Streaks", "写作连续天数"))
                .font(.headline)
                .foregroundStyle(TreeholeTheme.textPrimary)

            HStack(spacing: TreeholeTheme.spacingMedium) {
                StreakCard(
                    value: streaks.current,
                    label: L10n.t("Current Streak", "当前连续"),
                    icon: "flame.fill",
                    color: TreeholeTheme.coral
                )
                StreakCard(
                    value: streaks.longest,
                    label: L10n.t("Longest Streak", "最长连续"),
                    icon: "trophy.fill",
                    color: TreeholeTheme.warmGold
                )
            }
        }
        .glassCard()
        .padding(.bottom, TreeholeTheme.spacingLarge)
    }

    // MARK: - Data Helpers

    /// Everything the sections derive from the entry list, built in one pass.
    private struct StatsSnapshot {
        let located: [JournalEntry]
        let dominantMoodByDay: [Date: MoodTag]
        let dominantMoodByMonth: [Date: MoodTag]
        let moodCounts: [MoodTag: Int]
        let streaks: (current: Int, longest: Int)
    }

    private func makeStats() -> StatsSnapshot {
        let range = currentDateRange
        var located: [JournalEntry] = []
        var moodsByDay: [Date: [MoodTag]] = [:]
        var moodsByMonth: [Date: [MoodTag]] = [:]
        var counts: [MoodTag: Int] = [:]
        var entryDays = Set<Date>()

        for entry in allEntries {
            if entry.latitude != nil && entry.longitude != nil {
                located.append(entry)
            }
            let date = entry.displayDate
            entryDays.insert(cal.startOfDay(for: date))    // streaks span ALL entries
            guard date >= range.start && date < range.end else { continue }
            let mood = entry.moodTag
            counts[mood, default: 0] += 1
            moodsByDay[cal.startOfDay(for: date), default: []].append(mood)
            if let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: date)) {
                moodsByMonth[monthStart, default: []].append(mood)
            }
        }

        return StatsSnapshot(
            located: located,
            dominantMoodByDay: moodsByDay.mapValues(Self.dominantMood),
            dominantMoodByMonth: moodsByMonth.mapValues(Self.dominantMood),
            moodCounts: counts,
            streaks: calculateStreaks(entryDays: entryDays)
        )
    }

    nonisolated private static func dominantMood(_ moods: [MoodTag]) -> MoodTag {
        let freq = moods.reduce(into: [MoodTag: Int]()) { $0[$1, default: 0] += 1 }
        return freq.max(by: { $0.value < $1.value })?.key ?? moods[0]
    }

    private var currentDateRange: (start: Date, end: Date) {
        switch selectedPeriod {
        case .week:
            let start = weekStart(offset: selectedWeekOffset)
            let end = cal.date(byAdding: .day, value: 7, to: start) ?? start
            return (start, end)
        case .month:
            let target = cal.date(byAdding: .month, value: selectedMonthOffset, to: Date()) ?? Date()
            let comps = cal.dateComponents([.year, .month], from: target)
            let start = cal.date(from: comps) ?? target
            let end = cal.date(byAdding: .month, value: 1, to: start) ?? start
            return (start, end)
        case .year:
            let target = cal.date(byAdding: .year, value: selectedYearOffset, to: Date()) ?? Date()
            let comps = cal.dateComponents([.year], from: target)
            let start = cal.date(from: comps) ?? target
            let end = cal.date(byAdding: .year, value: 1, to: start) ?? start
            return (start, end)
        }
    }

    private func weekStart(offset: Int) -> Date {
        WeekAnchor.weekStart(offset: offset, calendar: cal)
    }

    /// ISO weekday: Mon=1 ... Sun=7
    private func isoWeekday(_ date: Date) -> Int {
        WeekAnchor.isoWeekday(date, calendar: cal)
    }

    private func calculateStreaks(entryDays: Set<Date>) -> (current: Int, longest: Int) {
        let today = cal.startOfDay(for: Date())
        let days = entryDays.sorted()

        guard !days.isEmpty else { return (0, 0) }

        // Longest streak
        var longest = 0
        var streak = 0
        var prev: Date? = nil
        for day in days {
            if let p = prev, cal.date(byAdding: .day, value: 1, to: p) == day {
                streak += 1
            } else {
                streak = 1
            }
            longest = max(longest, streak)
            prev = day
        }

        // Current streak (counting backwards from today or yesterday)
        var current = 0
        var check = today
        // if today has no entry, start from yesterday
        if !days.contains(today) {
            check = cal.date(byAdding: .day, value: -1, to: today) ?? today
        }
        while days.contains(check) {
            current += 1
            check = cal.date(byAdding: .day, value: -1, to: check) ?? check
        }

        return (current, longest)
    }

    private func moodColor(_ mood: MoodTag) -> Color {
        switch mood {
        case .happy:        TreeholeTheme.warmGold
        case .sad:          TreeholeTheme.skyBlue
        case .angry:        TreeholeTheme.coral
        case .anxious:      TreeholeTheme.softRose
        case .tired:        TreeholeTheme.gentleLavender
        case .confused:     TreeholeTheme.softPurple
        case .hopeful:      TreeholeTheme.mintCream
        case .calm:         TreeholeTheme.warmPeach
        case .grateful:     TreeholeTheme.warmPeach
        case .loved:        TreeholeTheme.softRose
        case .excited:      TreeholeTheme.warmGold
        case .peaceful:     TreeholeTheme.mintCream
        case .lonely:       TreeholeTheme.skyBlue
        case .melancholic:  TreeholeTheme.gentleLavender
        case .stressed:     TreeholeTheme.coral
        case .proud:        TreeholeTheme.softPurple
        }
    }
}

// MARK: - Mood Bar Row

private struct MoodBarRow: View {
    let mood: MoodTag
    let count: Int
    let maxCount: Int
    let barColor: Color

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Text(mood.emoji)
                .font(.title3)
                .frame(width: 28)

            Text(L10n.t(mood.labelEN, mood.labelZH))
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textPrimary)
                .frame(width: 65, alignment: .leading)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 14)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor)
                        .frame(
                            width: maxCount > 0
                                ? geo.size.width * CGFloat(count) / CGFloat(maxCount)
                                : 0,
                            height: 14
                        )
                }
            }
            .frame(height: 14)

            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(TreeholeTheme.textSecondary)
                .frame(width: 24, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.t(mood.labelEN, mood.labelZH))
        .accessibilityValue(L10n.t("\(count) entries", "\(count) 条日记"))
    }
}

// MARK: - Streak Card

private struct StreakCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.title2.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(L10n.t("days", "天"))
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textLight)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(TreeholeTheme.spacingSmall)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Places Map View

private struct PlacesMapView: View {
    let entries: [JournalEntry]

    @State private var selectedEntry: JournalEntry? = nil
    @State private var cameraPosition: MapCameraPosition

    init(entries: [JournalEntry]) {
        self.entries = entries
        let region = Self.fitRegion(for: entries)
        _cameraPosition = State(initialValue: .region(region))
    }

    private func moodColor(_ mood: MoodTag) -> Color {
        switch mood {
        case .happy:        TreeholeTheme.warmGold
        case .sad:          TreeholeTheme.skyBlue
        case .angry:        TreeholeTheme.coral
        case .anxious:      TreeholeTheme.softRose
        case .tired:        TreeholeTheme.gentleLavender
        case .confused:     TreeholeTheme.softPurple
        case .hopeful:      TreeholeTheme.mintCream
        case .calm:         TreeholeTheme.warmPeach
        case .grateful:     TreeholeTheme.warmPeach
        case .loved:        TreeholeTheme.softRose
        case .excited:      TreeholeTheme.warmGold
        case .peaceful:     TreeholeTheme.mintCream
        case .lonely:       TreeholeTheme.skyBlue
        case .melancholic:  TreeholeTheme.gentleLavender
        case .stressed:     TreeholeTheme.coral
        case .proud:        TreeholeTheme.softPurple
        }
    }

    private static func fitRegion(for entries: [JournalEntry]) -> MKCoordinateRegion {
        let coords = entries.compactMap { entry -> CLLocationCoordinate2D? in
            guard let lat = entry.latitude, let lon = entry.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        guard !coords.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4),
                span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            )
        }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.02, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.02, (maxLon - minLon) * 1.5)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedEntry) {
            ForEach(entries, id: \.self) { entry in
                if let lat = entry.latitude, let lon = entry.longitude {
                    Annotation(
                        entry.formattedDate,
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    ) {
                        Circle()
                            .fill(moodColor(entry.moodTag))
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .shadow(radius: 3)
                            .accessibilityLabel(L10n.t(
                                "\(entry.moodTag.labelEN) entry, \(entry.formattedDate)",
                                "\(entry.moodTag.labelZH)日记，\(entry.formattedDate)"
                            ))
                            .accessibilityAddTraits(.isButton)
                    }
                    .tag(entry)
                }
            }
        }
        .mapStyle(.standard)
        .navigationDestination(item: $selectedEntry) { entry in
            JournalDetailView(entry: entry)
        }
    }
}
