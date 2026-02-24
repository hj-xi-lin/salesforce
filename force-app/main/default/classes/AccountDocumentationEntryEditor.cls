/*
*      	@author 		Lisa Müller
*      	@date   		Feb-2026
*      	@description  	Invocable action to handle regex logic for extracting and editing account documentation entries
*
*      	Modification Log:
*      	------------------------------------------------------------------------------------
*      	Developer		Date                Description
*
*      	------------------------------------------------------------------------------------			
*/

public class AccountDocumentationEntryEditor {
    
    @InvocableMethod(label='Manage Account Documentation Entry' 
                     description='Finds and edits timestamped entries in account documentation')
    public static List<Result> manageEntry(List<Request> requests) {
        
        List<Result> results = new List<Result>();
        Request req = requests[0];
        Result res = new Result();
        
        // Extract the full entry
        String fullEntry = extractEntry(req.fullText, req.timestamp);
        res.entryFound = String.isNotBlank(fullEntry);
        
        if (res.entryFound) {
            // Strip the timestamp from the extracted entry - only return the content
            res.currentEntryContent = stripTimestamp(fullEntry);
            res.fullTimestamp = '[' + req.timestamp + ']';
        }
        
        if (req.performUpdate && res.entryFound) {
            // Reconstruct: timestamp + edited content
            String reconstructedEntry = '[' + req.timestamp + '] ' + req.newEntryContent;
            res.updatedText = replaceEntry(req.fullText, req.timestamp, reconstructedEntry);
        }
        
        results.add(res);
        return results;
    }
    

    private static String stripTimestamp(String entryWithTimestamp) {
        /**
    	@Methodname     : stripTimestamp
    	@Param          : entryWithTimestamp (full entry including [YYYY-MM-DD HH:mm] timestamp)
    	@Return         : entry content without the timestamp
    	@Description    : Strips the timestamp portion from a full entry, returning only the content
    	**/
     	
        if (String.isBlank(entryWithTimestamp)) return '';
        
        // Find the closing bracket of timestamp
        Integer closingBracket = entryWithTimestamp.indexOf(']');
        
        if (closingBracket == -1) return entryWithTimestamp; // No bracket found, return as-is
        
        // Extract everything after "] " (bracket + space)
        String content = entryWithTimestamp.substring(closingBracket + 1).trim();
        
        return content;
    }
    
    private static String extractEntry(String fullText, String timestamp) {
        /**
    	@Methodname     : extractEntry
    	@Param          : fullText (complete text field containing multiple entries), timestamp (timestamp to search for (format: YYYY-MM-DD HH:mm))
    	@Return         : full entry including timestamp, or null if not found
    	@Description    : extracts a single timestamped entry from the full text
    	**/
        
        
        if (String.isBlank(fullText) || String.isBlank(timestamp)) return null;
        
        // Build regex pattern to find the timestamp with brackets
        String searchPattern = '\\[' + timestamp + '\\]';
        Pattern p = Pattern.compile(searchPattern);
        Matcher m = p.matcher(fullText);
        
        // Return null if timestamp not found
        if (!m.find()) return null;
        
        Integer entryStart = m.start();
        Integer contentStart = m.end();
        
        // Find the next entry (blank line + timestamp pattern) or end of text
        Pattern nextEntry = Pattern.compile('\\n\\s*\\n\\[\\d{4}-\\d{2}-\\d{2}');
        Matcher nextMatcher = nextEntry.matcher(fullText);
        
        // Determine where this entry ends
        Integer entryEnd = nextMatcher.find(contentStart) 
            ? nextMatcher.start() 
            : fullText.length();
            
        return fullText.substring(entryStart, entryEnd).trim();
    }
    

    private static String replaceEntry(String fullText, String timestamp, String newEntryText) {
        /**
    	@Methodname     : replaceEntry
    	@Param          : fullText (complete text field containing multiple entries), timestamp (timestamp of the entry to replace), newEntryText (new complete entry text (including timestamp))
    	@Return         : updated full text with the entry replaced
    	@Description    : Replaces a specific entry in the full text while preserving all other entries
    	**/
        if (String.isBlank(fullText) || String.isBlank(timestamp)) {
            return fullText;
        }
        
        // Find the entry to replace
        String searchPattern = '\\[' + timestamp + '\\]';
        Pattern p = Pattern.compile(searchPattern);
        Matcher m = p.matcher(fullText);
        
        if (!m.find()) {
            return fullText; // Timestamp not found, return original
        }
        
        Integer entryStart = m.start();
        Integer contentStart = m.end();
        
        // Find where this entry ends
        Pattern nextEntry = Pattern.compile('\\n\\s*\\n\\[\\d{4}-\\d{2}-\\d{2}');
        Matcher nextMatcher = nextEntry.matcher(fullText);
        
        Integer entryEnd = nextMatcher.find(contentStart) 
            ? nextMatcher.start() 
            : fullText.length();
        
        // Build the new text: before + new entry + after
        String before = entryStart > 0 ? fullText.substring(0, entryStart) : '';
        String after = entryEnd < fullText.length() ? fullText.substring(entryEnd) : '';
        
        // Ensure exactly one blank line between entries
        String separator = '';
        if (String.isNotBlank(after)) {
            separator = after.startsWith('\n') ? '' : '\n\n';
        }

		return before + newEntryText.trim() + separator + after;

    }
    
    // Input parameters variables
    public class Request {
        @InvocableVariable(required=true label='Full Text' 
                          description='The complete text field containing all entries')
        public String fullText;
        
        @InvocableVariable(required=true label='Timestamp' 
                          description='The timestamp to search for (format: YYYY-MM-DD HH:mm)')
        public String timestamp;
        
        @InvocableVariable(label='New Entry Content' 
                          description='The edited content (without timestamp) when performing update')
        public String newEntryContent;
        
        @InvocableVariable(label='Perform Update' 
                          description='Set to true to update the entry, false to only extract')
        public Boolean performUpdate;
    }
    
    // Output variables
    public class Result {
        @InvocableVariable(label='Current Entry Content' 
                          description='The extracted content without timestamp')
        public String currentEntryContent;
        
        @InvocableVariable(label='Full Timestamp' 
                          description='The complete timestamp with brackets [YYYY-MM-DD HH:mm]')
        public String fullTimestamp;
        
        @InvocableVariable(label='Entry Found' 
                          description='True if the timestamp was found in the text')
        public Boolean entryFound;
        
        @InvocableVariable(label='Updated Text' 
                          description='The complete text with the entry updated')
        public String updatedText;
    }
}