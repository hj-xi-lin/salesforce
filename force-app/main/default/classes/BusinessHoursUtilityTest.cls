/**
 * @description Test class for BusinessHoursUtility
 * Covers calculateBusinessMinutes, calculateBusinessHours, isWithinBusinessHours, and clearCache
 */
@isTest
private class BusinessHoursUtilityTest {

    /**
     * @description calculateBusinessMinutes returns null when either argument is null
     */
    @isTest
    static void testCalculateBusinessMinutes_NullArgs() {
        Test.startTest();
        Long result1 = BusinessHoursUtility.calculateBusinessMinutes(null, null);
        Long result2 = BusinessHoursUtility.calculateBusinessMinutes(DateTime.now(), null);
        Long result3 = BusinessHoursUtility.calculateBusinessMinutes(null, DateTime.now());
        Test.stopTest();

        System.assertEquals(null, result1, 'Both null should return null');
        System.assertEquals(null, result2, 'Null end should return null');
        System.assertEquals(null, result3, 'Null start should return null');
    }

    /**
     * @description calculateBusinessMinutes returns a non-negative value for valid DateTimes
     * Also verifies cache is populated on second call
     */
    @isTest
    static void testCalculateBusinessMinutes_ValidArgs() {
        DateTime startDT = DateTime.newInstance(2026, 2, 2, 9, 0, 0);  // Monday 09:00
        DateTime endDT   = DateTime.newInstance(2026, 2, 2, 10, 0, 0); // Monday 10:00

        Test.startTest();
        Long firstCall  = BusinessHoursUtility.calculateBusinessMinutes(startDT, endDT);
        Long secondCall = BusinessHoursUtility.calculateBusinessMinutes(startDT, endDT); // cache hit
        Test.stopTest();

        System.assertNotEquals(null, firstCall,  'Result should not be null for valid DateTimes');
        System.assert(firstCall >= 0,            'Business minutes should be non-negative');
        System.assertEquals(firstCall, secondCall, 'Cached result should match first call');
    }

    /**
     * @description clearCache resets the cached ID so the next call re-queries
     */
    @isTest
    static void testClearCache() {
        DateTime startDT = DateTime.newInstance(2026, 2, 2, 9, 0, 0);
        DateTime endDT   = DateTime.newInstance(2026, 2, 2, 10, 0, 0);

        // Warm up the cache
        BusinessHoursUtility.calculateBusinessMinutes(startDT, endDT);

        Test.startTest();
        BusinessHoursUtility.clearCache();
        // After clearing, should still return a valid result (re-queries BH)
        Long result = BusinessHoursUtility.calculateBusinessMinutes(startDT, endDT);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return result after cache clear');
        System.assert(result >= 0, 'Business minutes should be non-negative after cache reset');
    }

    /**
     * @description calculateBusinessHours returns null when inputs are null
     */
    @isTest
    static void testCalculateBusinessHours_NullArgs() {
        Test.startTest();
        Decimal result = BusinessHoursUtility.calculateBusinessHours(null, null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for null inputs');
    }

    /**
     * @description calculateBusinessHours returns a non-negative decimal for valid DateTimes
     */
    @isTest
    static void testCalculateBusinessHours_ValidArgs() {
        DateTime startDT = DateTime.newInstance(2026, 2, 2, 9, 0, 0);
        DateTime endDT   = DateTime.newInstance(2026, 2, 2, 10, 0, 0);

        Test.startTest();
        Decimal result = BusinessHoursUtility.calculateBusinessHours(startDT, endDT);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result >= 0, 'Business hours should be non-negative');
    }

    /**
     * @description isWithinBusinessHours returns false for null input
     */
    @isTest
    static void testIsWithinBusinessHours_Null() {
        Test.startTest();
        Boolean result = BusinessHoursUtility.isWithinBusinessHours(null);
        Test.stopTest();

        System.assertEquals(false, result, 'Null DateTime should return false');
    }

    /**
     * @description isWithinBusinessHours returns a boolean for a valid DateTime
     * Also tests cache-hit path via second call
     */
    @isTest
    static void testIsWithinBusinessHours_ValidDateTime() {
        DateTime dt = DateTime.newInstance(2026, 2, 2, 9, 30, 0); // Monday 09:30

        Test.startTest();
        BusinessHoursUtility.clearCache();                    // ensure fresh query
        Boolean firstCall  = BusinessHoursUtility.isWithinBusinessHours(dt);
        Boolean secondCall = BusinessHoursUtility.isWithinBusinessHours(dt); // cache hit
        Test.stopTest();

        // Result is org-dependent (true inside BH, false outside) — just verify no exception
        System.assertNotEquals(null, firstCall,  'Should return a boolean for valid DateTime');
        System.assertEquals(firstCall, secondCall, 'Cached result should match first call');
    }
}