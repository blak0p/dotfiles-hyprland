const weekDays = [
    { day: 'Mo', full: 'Monday' },
    { day: 'Tu', full: 'Tuesday' },
    { day: 'We', full: 'Wednesday' },
    { day: 'Th', full: 'Thursday' },
    { day: 'Fr', full: 'Friday' },
    { day: 'Sa', full: 'Saturday' },
    { day: 'Su', full: 'Sunday' },
];

function isLeapYear(year) {
    return (year % 400 === 0 || (year % 4 === 0 && year % 100 !== 0));
}

function getMonthDays(month, year) {
    const leap = isLeapYear(year);
    if ((month <= 7 && month % 2 === 1) || (month >= 8 && month % 2 === 0)) return 31;
    if (month === 2) return leap ? 29 : 28;
    return 30;
}

function getDateInXMonthsTime(x) {
    const d = new Date();
    if (x === 0) return d;
    const targetMonth = d.getMonth() + x;
    const targetYear = d.getFullYear() + Math.floor(targetMonth / 12);
    const normalizedMonth = (targetMonth % 12 + 12) % 12;
    return new Date(targetYear, normalizedMonth, 1);
}

function getCalendarGrid(dateObject, isCurrentMonth) {
    if (!dateObject) dateObject = new Date();
    const today = new Date();
    const todayDay = today.getDate();
    const todayMonth = today.getMonth() + 1;
    const todayYear = today.getFullYear();

    const month = dateObject.getMonth() + 1;
    const year = dateObject.getFullYear();
    
    // First day of month (0 = Sunday, 1 = Monday...) -> Monday as index 0
    const firstDayIndex = (new Date(year, month - 1, 1).getDay() + 6) % 7;
    const daysInMonth = getMonthDays(month, year);
    
    const prevMonth = month === 1 ? 12 : month - 1;
    const prevYear = month === 1 ? year - 1 : year;
    const daysInPrevMonth = getMonthDays(prevMonth, prevYear);

    const cells = [];
    
    // Prev month days
    for (let i = firstDayIndex - 1; i >= 0; i--) {
        cells.push({
            day: daysInPrevMonth - i,
            isCurrentMonth: false,
            isToday: false,
        });
    }

    // Current month days
    for (let i = 1; i <= daysInMonth; i++) {
        const isToday = isCurrentMonth && (i === todayDay) && (month === todayMonth) && (year === todayYear);
        cells.push({
            day: i,
            isCurrentMonth: true,
            isToday: isToday,
        });
    }

    // Next month days to fill 42 cells (6 rows x 7 cols)
    const remaining = 42 - cells.length;
    for (let i = 1; i <= remaining; i++) {
        cells.push({
            day: i,
            isCurrentMonth: false,
            isToday: false,
        });
    }

    return cells;
}
