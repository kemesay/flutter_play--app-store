import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Initializes timezone data (should be called once at app startup)
void initializeTimezones() {
  tz.initializeTimeZones();
}

/// Formats a DateTime to Pacific timezone (America/Los_Angeles)
/// Matches website formatDateToPacific: "MMM dd, yyyy, hh:mm a PST/PDT"
/// 
/// Website uses: Intl.DateTimeFormat with timeZone: 'America/Los_Angeles'
/// Format: month: 'short', day: '2-digit', year: 'numeric', 
///         hour: '2-digit', minute: '2-digit', hour12: true, timeZoneName: 'short'
/// 
/// Example: "Dec 25, 2025, 08:00 PM PST"
String formatDateToPacific(DateTime? dateTime) {
  if (dateTime == null) return 'N/A';
  
  try {
    // Ensure timezone data is initialized
    try {
      tz.getLocation('America/Los_Angeles');
    } catch (_) {
      tz.initializeTimeZones();
    }
    
    // Convert to Pacific timezone
    final pacificLocation = tz.getLocation('America/Los_Angeles');
    final utcDateTime = dateTime.toUtc();
    
    // Create TZDateTime in Pacific timezone from UTC timestamp
    final pacificTZ = tz.TZDateTime.fromMicrosecondsSinceEpoch(
      pacificLocation,
      utcDateTime.microsecondsSinceEpoch,
    );
    
    // Convert to regular DateTime for formatting
    final pacificTime = DateTime(
      pacificTZ.year,
      pacificTZ.month,
      pacificTZ.day,
      pacificTZ.hour,
      pacificTZ.minute,
      pacificTZ.second,
    );
    
    // Match website format exactly: "MMM dd, yyyy, hh:mm a PST/PDT"
    // Website: month: 'short', day: '2-digit', year: 'numeric'
    //          hour: '2-digit', minute: '2-digit', hour12: true, timeZoneName: 'short'
    // Note: '2-digit' in JS may show "25" or "05", DateFormat 'dd' shows "25" or "05"
    // Format: "MMM d, yyyy, hh:mm a" to match website (no leading zero for day)
    final formatter = DateFormat('MMM d, yyyy, hh:mm a', 'en_US');
    final formatted = formatter.format(pacificTime);
    
    // Get timezone abbreviation (PST/PDT) - matches website's timeZoneName: 'short'
    final timeZoneAbbr = _getPacificTimeZoneAbbr(pacificTime);
    
    return '$formatted $timeZoneAbbr';
  } catch (e) {
    // Fallback to local time if conversion fails
    return DateFormat('MMM dd, yyyy, hh:mm a', 'en_US').format(dateTime);
  }
}

/// Gets the Pacific timezone abbreviation (PST or PDT)
String _getPacificTimeZoneAbbr(DateTime dateTime) {
  // DST in Pacific timezone: second Sunday in March to first Sunday in November
  final year = dateTime.year;
  
  // Find second Sunday in March
  final marchFirst = DateTime(year, 3, 1);
  final marchFirstWeekday = marchFirst.weekday; // 1=Monday, 7=Sunday
  final daysToSecondSunday = (7 - marchFirstWeekday + 1) % 7 + 7;
  final dstStart = marchFirst.add(Duration(days: daysToSecondSunday));
  
  // Find first Sunday in November
  final novemberFirst = DateTime(year, 11, 1);
  final novemberFirstWeekday = novemberFirst.weekday;
  final daysToFirstSunday = (7 - novemberFirstWeekday + 1) % 7;
  final dstEnd = novemberFirst.add(Duration(days: daysToFirstSunday));
  
  // DST is in effect if date is between start and end
  final isDST = dateTime.isAfter(dstStart.subtract(const Duration(days: 1))) &&
                dateTime.isBefore(dstEnd);
  
  return isDST ? 'PDT' : 'PST';
}

/// Formats a DateTime to Pacific timezone with custom format
/// Similar to website's formatDateToPacific but with customizable format string
String formatDateToPacificCustom(DateTime? dateTime, String format) {
  if (dateTime == null) return 'N/A';
  
  try {
    // Ensure timezone data is initialized
    try {
      tz.getLocation('America/Los_Angeles');
    } catch (_) {
      tz.initializeTimeZones();
    }
    
    final pacificLocation = tz.getLocation('America/Los_Angeles');
    final utcDateTime = dateTime.toUtc();
    
    // Create TZDateTime in Pacific timezone from UTC timestamp
    final pacificTZ = tz.TZDateTime.fromMicrosecondsSinceEpoch(
      pacificLocation,
      utcDateTime.microsecondsSinceEpoch,
    );
    
    // Convert to regular DateTime for formatting
    final pacificTime = DateTime(
      pacificTZ.year,
      pacificTZ.month,
      pacificTZ.day,
      pacificTZ.hour,
      pacificTZ.minute,
      pacificTZ.second,
    );
    
    return DateFormat(format).format(pacificTime);
  } catch (e) {
    return DateFormat(format).format(dateTime);
  }
}

