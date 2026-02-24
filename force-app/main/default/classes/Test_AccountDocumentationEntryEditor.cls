@isTest
private class Test_AccountDocumentationEntryEditor {
    
    @isTest
    static void testExtractEntry_FoundAndNotFound() {
        String fullText = '[2024-01-15 10:30] First entry\n\n[2024-01-16 14:45] Second entry';
        
        // Test found
        AccountDocumentationEntryEditor.Request req1 = new AccountDocumentationEntryEditor.Request();
        req1.fullText = fullText;
        req1.timestamp = '2024-01-15 10:30';
        req1.performUpdate = false;
        
        List<AccountDocumentationEntryEditor.Result> results1 = AccountDocumentationEntryEditor.manageEntry(new List<AccountDocumentationEntryEditor.Request>{req1});
        
        System.assertEquals(true, results1[0].entryFound, 'Entry should be found');
        System.assertEquals('First entry', results1[0].currentEntryContent, 'Should extract content without timestamp');
        System.assertEquals('[2024-01-15 10:30]', results1[0].fullTimestamp, 'Should return full timestamp');
        
        // Test not found
        AccountDocumentationEntryEditor.Request req2 = new AccountDocumentationEntryEditor.Request();
        req2.fullText = fullText;
        req2.timestamp = '2024-01-17 10:30';
        req2.performUpdate = false;
        
        List<AccountDocumentationEntryEditor.Result> results2 = AccountDocumentationEntryEditor.manageEntry(new List<AccountDocumentationEntryEditor.Request>{req2});
        
        System.assertEquals(false, results2[0].entryFound, 'Entry should not be found');
    }
    
    @isTest
    static void testUpdateEntry() {
        String fullText = '[2024-01-15 10:30] First entry\n\n[2024-01-16 14:45] Second entry';
        
        AccountDocumentationEntryEditor.Request req = new AccountDocumentationEntryEditor.Request();
        req.fullText = fullText;
        req.timestamp = '2024-01-15 10:30';
        req.newEntryContent = 'Updated content';
        req.performUpdate = true;
        
        List<AccountDocumentationEntryEditor.Result> results = AccountDocumentationEntryEditor.manageEntry(new List<AccountDocumentationEntryEditor.Request>{req});
        
        System.assertEquals(true, results[0].entryFound, 'Entry should be found');
        System.assert(results[0].updatedText.contains('[2024-01-15 10:30] Updated content'), 'Should contain updated entry');
        System.assert(results[0].updatedText.contains('[2024-01-16 14:45] Second entry'), 'Should preserve other entries');
    }
    
    @isTest
    static void testEdgeCases() {
        // Null/empty inputs
        AccountDocumentationEntryEditor.Request req1 = new AccountDocumentationEntryEditor.Request();
        req1.fullText = '';
        req1.timestamp = '2024-01-15 10:30';
        req1.performUpdate = false;
        
        List<AccountDocumentationEntryEditor.Result> results1 = AccountDocumentationEntryEditor.manageEntry(new List<AccountDocumentationEntryEditor.Request>{req1});
        System.assertEquals(false, results1[0].entryFound, 'Should handle empty text');
        
        // Single entry
        AccountDocumentationEntryEditor.Request req2 = new AccountDocumentationEntryEditor.Request();
        req2.fullText = '[2024-01-15 10:30] Only entry';
        req2.timestamp = '2024-01-15 10:30';
        req2.performUpdate = false;
        
        List<AccountDocumentationEntryEditor.Result> results2 = AccountDocumentationEntryEditor.manageEntry(new List<AccountDocumentationEntryEditor.Request>{req2});
        System.assertEquals(true, results2[0].entryFound, 'Should find single entry');
        System.assertEquals('Only entry', results2[0].currentEntryContent, 'Should extract single entry content');
    }
}