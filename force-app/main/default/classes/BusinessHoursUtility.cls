/**
 * Utility class for business hours calculations.
 * Reusable across projects for SLA tracking.
 * 
 * Uses the org's default Business Hours settings to calculate
 * elapsed time excluding non-business hours and weekends.
 */
public without sharing class BusinessHoursUtility {
    
    // Cached Business Hours ID for performance
    private static Id defaultBusinessHoursId;
    
    /**
     * Calculate elapsed business minutes between two DateTimes.
     * Uses the org's default Business Hours settings.
     * 
     * @param startDT Start DateTime
     * @param endDT End DateTime
     * @return Elapsed business minutes, or null if either param is null
     */
    public static Long calculateBusinessMinutes(DateTime startDT, DateTime endDT) {
        if (startDT == null || endDT == null) {
            return null;
        }
        
        // Cache the Business Hours Id for performance
        if (defaultBusinessHoursId == null) {
            List<BusinessHours> bhList = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
            if (bhList.isEmpty()) {
                // Fallback: if no default Business Hours, return calendar minutes
                return startDT.getTime() < endDT.getTime() 
                    ? (endDT.getTime() - startDT.getTime()) / 60000 
                    : 0;
            }
            defaultBusinessHoursId = bhList[0].Id;
        }
        
        // BusinessHours.diff() returns milliseconds between two DateTimes within business hours
        Long diffMs = BusinessHours.diff(defaultBusinessHoursId, startDT, endDT);
        
        // Convert milliseconds to minutes
        return diffMs / 60000;
    }
    
    /**
     * Calculate elapsed business hours between two DateTimes.
     * Convenience method that returns hours instead of minutes.
     * 
     * @param startDT Start DateTime
     * @param endDT End DateTime
     * @return Elapsed business hours (decimal), or null if either param is null
     */
    public static Decimal calculateBusinessHours(DateTime startDT, DateTime endDT) {
        Long minutes = calculateBusinessMinutes(startDT, endDT);
        if (minutes == null) {
            return null;
        }
        return Decimal.valueOf(minutes) / 60;
    }
    
    /**
     * Check if a DateTime falls within business hours.
     * 
     * @param dt DateTime to check
     * @return true if within business hours, false otherwise
     */
    public static Boolean isWithinBusinessHours(DateTime dt) {
        if (dt == null) {
            return false;
        }
        
        if (defaultBusinessHoursId == null) {
            List<BusinessHours> bhList = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
            if (bhList.isEmpty()) {
                return true; // No business hours defined, assume always open
            }
            defaultBusinessHoursId = bhList[0].Id;
        }
        
        return BusinessHours.isWithin(defaultBusinessHoursId, dt);
    }
    
    /**
     * Clear the cached Business Hours ID.
     * Useful for testing or when Business Hours settings change.
     */
    @TestVisible
    private static void clearCache() {
        defaultBusinessHoursId = null;
    }
}